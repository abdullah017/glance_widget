package dev.glance.widget.android.templates

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.util.Log
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.datastore.preferences.core.Preferences
import androidx.glance.*
import androidx.glance.LocalSize
import androidx.glance.action.clickable
import androidx.glance.appwidget.CheckBox
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetReceiver
import androidx.glance.appwidget.action.actionRunCallback
import androidx.glance.appwidget.action.actionStartActivity
import androidx.glance.appwidget.cornerRadius
import androidx.glance.appwidget.lazy.LazyColumn
import androidx.glance.appwidget.lazy.itemsIndexed
import androidx.glance.appwidget.provideContent
import androidx.glance.layout.*
import androidx.glance.state.GlanceStateDefinition
import androidx.glance.state.PreferencesGlanceStateDefinition
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import dev.glance.widget.android.CornerRadius
import dev.glance.widget.android.GlanceWidgetManager
import dev.glance.widget.android.WidgetRemoval
import dev.glance.widget.android.widgetColors
import dev.glance.widget.android.ListItems
import dev.glance.widget.android.ReportActionCallback
import dev.glance.widget.android.ToggleListItemAction
import dev.glance.widget.android.WidgetSizeClass
import dev.glance.widget.android.WidgetSlots
import dev.glance.widget.android.WidgetTypeScale

/**
 * List Widget - displays a list of items with optional checkboxes.
 * Perfect for to-do lists, news headlines, etc.
 */
class ListGlanceWidget : GlanceAppWidget() {

    override val stateDefinition: GlanceStateDefinition<*> = PreferencesGlanceStateDefinition

    // Tall rather than fully resizable: list_widget_info.xml declares a 180dp
    // minResizeHeight, so this template is never handed a compact slot through
    // its own manifest.
    override val sizeMode = WidgetSlots.tall

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent {
            val prefs = currentState<Preferences>()
            ListWidgetContent(prefs)
        }
    }

    /**
     * Drops the data this widget was the last one using.
     *
     * Glance deletes the instance's own state after this returns; everything
     * keyed by the app's `widgetId` -- the cached image, the tracked id -- is
     * not its business, and used to survive the widget forever. See #13.
     */
    override suspend fun onDelete(context: Context, glanceId: GlanceId) {
        WidgetRemoval.onInstanceDeleted(context, glanceId)
    }
}

/**
 * Data class for list items.
 */
data class ListItem(
    val text: String,
    val checked: Boolean,
    val secondaryText: String?
)

@Composable
internal fun ListWidgetContent(prefs: Preferences) {
    val widgetId = prefs[GlanceWidgetManager.widgetIdKey] ?: "list"
    val title = prefs[GlanceWidgetManager.titleKey] ?: "List"
    val itemsString = prefs[GlanceWidgetManager.itemsKey] ?: ""
    val showCheckboxes = prefs[GlanceWidgetManager.showCheckboxesKey] ?: false
    val deepLinkUri = prefs[GlanceWidgetManager.deepLinkUriKey]
    val isDark = prefs[GlanceWidgetManager.isDarkKey] ?: true

    // Parse items
    val items = ListItems.parse(itemsString) {
        Log.e("ListGlanceWidget", "Failed to read the list's items", it)
    }

    val colors = widgetColors(prefs)

    val sizeClass = WidgetSizeClass.of(LocalSize.current)

    Column(
        modifier = GlanceModifier
            .fillMaxSize()
            .background(colors.background)
            .cornerRadius(CornerRadius.dpFor(prefs[GlanceWidgetManager.borderRadiusKey]).dp)
            .padding(WidgetTypeScale.padding(sizeClass))
    ) {
        // This template already scrolled its items, so unlike the other six it
        // never cut content off the bottom. What it did do was spend the same
        // 35dp of header and divider whatever room it had, and draw an 18sp
        // title into a slot that could only show two items.
        if (sizeClass != WidgetSizeClass.COMPACT) {
            // Header
            Row(
                modifier = GlanceModifier
                    .fillMaxWidth()
                    .padding(bottom = WidgetTypeScale.gap(sizeClass)),
                horizontalAlignment = Alignment.Start,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = title,
                    style = TextStyle(
                        color = colors.text,
                        fontSize = if (sizeClass == WidgetSizeClass.EXPANDED) 18.sp else 16.sp,
                        fontWeight = FontWeight.Bold
                    ),
                    maxLines = 1
                )

                Spacer(modifier = GlanceModifier.fillMaxWidth())

                // Item count badge
                Text(
                    text = "${items.size}",
                    style = TextStyle(
                        color = colors.secondaryText,
                        fontSize = WidgetTypeScale.caption(sizeClass)
                    ),
                    maxLines = 1
                )
            }

            // Divider
            Box(
                modifier = GlanceModifier
                    .fillMaxWidth()
                    .height(1.dp)
                    .background(ColorProvider(
                        Color(if (isDark) 0xFF3A3A4E.toInt() else 0xFFE0E0E0.toInt())
                    ))
            ) {}

            Spacer(modifier = GlanceModifier.height(WidgetTypeScale.gap(sizeClass)))
        }

        // Items list
        if (items.isEmpty()) {
            Box(
                modifier = GlanceModifier.fillMaxSize(),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = "No items",
                    style = TextStyle(
                        color = colors.secondaryText,
                        fontSize = 14.sp
                    )
                )
            }
        } else {
            LazyColumn {
                itemsIndexed(items) { index, item ->
                    ListItemRow(
                        item = item,
                        index = index,
                        widgetId = widgetId,
                        sizeClass = sizeClass,
                        showCheckbox = showCheckboxes,
                        deepLinkUri = deepLinkUri,
                        textColor = colors.text,
                        secondaryTextColor = colors.secondaryText,
                        accentColor = colors.accent,
                        isDark = isDark
                    )
                }
            }
        }
    }
}

@Composable
private fun ListItemRow(
    item: ListItem,
    index: Int,
    widgetId: String,
    sizeClass: WidgetSizeClass,
    showCheckbox: Boolean,
    deepLinkUri: String?,
    textColor: ColorProvider,
    secondaryTextColor: ColorProvider,
    accentColor: ColorProvider,
    isDark: Boolean
) {
    Row(
        modifier = GlanceModifier
            .fillMaxWidth()
            .padding(vertical = if (sizeClass == WidgetSizeClass.EXPANDED) 8.dp else 6.dp)
            // Not a lambda action: that runs in a process the system may
            // have started purely to deliver this tap, with no Flutter engine
            // in it, so the event went to a null sink and vanished. A deep link
            // still starts the activity -- the launch is the notification.
            .clickable(
                if (deepLinkUri != null) {
                    actionStartActivity(Intent(Intent.ACTION_VIEW, Uri.parse(deepLinkUri)))
                } else {
                    ReportActionCallback.tapAt(widgetId, "itemTap", index)
                }
            ),
        verticalAlignment = Alignment.CenterVertically
    ) {
        if (showCheckbox) {
            CheckBox(
                checked = item.checked,
                // An ActionCallback rather than a lambda action: this runs in
                // a process the system may have started purely to deliver the
                // tap, with no Flutter engine in it. `ToggleListItemAction`
                // writes the new state and queues the event for Dart, so the
                // box stays ticked and the app hears about it later.
                onCheckedChange = actionRunCallback<ToggleListItemAction>(
                    ToggleListItemAction.parametersFor(widgetId, index)
                ),
                modifier = GlanceModifier.padding(end = 12.dp),
                colors = androidx.glance.appwidget.CheckboxDefaults.colors(
                    checkedColor = accentColor,
                    uncheckedColor = secondaryTextColor
                )
            )
        }

        Column(
            modifier = GlanceModifier.fillMaxWidth()
        ) {
            Text(
                text = item.text,
                style = TextStyle(
                    color = if (item.checked && showCheckbox) secondaryTextColor else textColor,
                    fontSize = WidgetTypeScale.body(sizeClass),
                    fontWeight = FontWeight.Normal
                ),
                maxLines = 1
            )

            // A second line per item halves how many items fit. Worth it when
            // the slot is tall; not when it costs the reader half the list.
            if (sizeClass == WidgetSizeClass.EXPANDED) {
                item.secondaryText?.let { secondary ->
                    if (secondary.isNotEmpty()) {
                        Text(
                            text = secondary,
                            style = TextStyle(
                                color = secondaryTextColor,
                                fontSize = WidgetTypeScale.caption(sizeClass)
                            ),
                            maxLines = 1
                        )
                    }
                }
            }
        }
    }
}

/**
 * Receiver for List Widget.
 */
class ListWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = ListGlanceWidget()
}
