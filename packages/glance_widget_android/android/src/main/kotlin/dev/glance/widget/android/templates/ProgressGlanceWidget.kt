package dev.glance.widget.android.templates

import android.content.Context
import android.content.Intent
import android.net.Uri
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.datastore.preferences.core.Preferences
import androidx.glance.*
import androidx.glance.LocalSize
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetReceiver
import androidx.glance.appwidget.LinearProgressIndicator
import androidx.glance.appwidget.action.actionStartActivity
import androidx.glance.appwidget.cornerRadius
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
import dev.glance.widget.android.ReportActionCallback
import dev.glance.widget.android.WidgetSizeClass
import dev.glance.widget.android.WidgetSlots
import dev.glance.widget.android.WidgetTypeScale

/**
 * Progress Widget - displays a progress indicator with title and subtitle.
 * Perfect for download progress, goal tracking, etc.
 */
class ProgressGlanceWidget : GlanceAppWidget() {

    override val stateDefinition: GlanceStateDefinition<*> = PreferencesGlanceStateDefinition

    override val sizeMode = WidgetSlots.resizable

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent {
            val prefs = currentState<Preferences>()
            ProgressWidgetContent(prefs)
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

@Composable
internal fun ProgressWidgetContent(prefs: Preferences) {
    val widgetId = prefs[GlanceWidgetManager.widgetIdKey] ?: "progress"
    val title = prefs[GlanceWidgetManager.titleKey] ?: "Progress"
    val progress = prefs[GlanceWidgetManager.progressKey] ?: 0f
    val subtitle = prefs[GlanceWidgetManager.subtitleKey]
    val progressType = prefs[GlanceWidgetManager.progressTypeKey] ?: "circular"
    val progressColorInt = prefs[GlanceWidgetManager.progressColorKey]
    val trackColorInt = prefs[GlanceWidgetManager.trackColorKey]
    val deepLinkUri = prefs[GlanceWidgetManager.deepLinkUriKey]
    val isDark = prefs[GlanceWidgetManager.isDarkKey] ?: true

    val colors = widgetColors(prefs)

    val sizeClass = WidgetSizeClass.of(LocalSize.current)

    val progressColor = progressColorInt?.let { ColorProvider(Color(it.toInt())) } ?: colors.accent
    val trackColor = trackColorInt?.let { ColorProvider(Color(it.toInt())) }
        ?: ColorProvider(Color(if (isDark) 0xFF3A3A4E.toInt() else 0xFFE0E0E0.toInt()))

    Box(
        modifier = GlanceModifier
            .fillMaxSize()
            .background(colors.background)
            .cornerRadius(CornerRadius.dpFor(prefs[GlanceWidgetManager.borderRadiusKey]).dp)
            // Not a lambda action: that runs in a process the system may
            // have started purely to deliver this tap, with no Flutter engine
            // in it, so the event went to a null sink and vanished. A deep link
            // still starts the activity -- the launch is the notification.
            .clickable(
                if (deepLinkUri != null) {
                    actionStartActivity(Intent(Intent.ACTION_VIEW, Uri.parse(deepLinkUri)))
                } else {
                    ReportActionCallback.tap(widgetId, "tap")
                }
            )
            .padding(WidgetTypeScale.padding(sizeClass)),
        contentAlignment = Alignment.Center
    ) {
        if (progressType == "linear") {
            // Linear progress layout
            Column(
                modifier = GlanceModifier.fillMaxWidth(),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalAlignment = Alignment.CenterVertically
            ) {
                // The bar is the widget. At the compact end the title is the
                // first thing to go, because a title with no bar under it
                // reports nothing at all.
                if (sizeClass != WidgetSizeClass.COMPACT) {
                    Text(
                        text = title,
                        style = TextStyle(
                            color = colors.text,
                            fontSize = WidgetTypeScale.title(sizeClass),
                            fontWeight = FontWeight.Medium
                        ),
                        maxLines = 1
                    )

                    Spacer(modifier = GlanceModifier.height(WidgetTypeScale.gap(sizeClass)))
                }

                // Linear Progress
                LinearProgressIndicator(
                    progress = progress,
                    modifier = GlanceModifier
                        .fillMaxWidth()
                        .height(8.dp),
                    color = progressColor,
                    backgroundColor = trackColor
                )

                // Subtitle
                if (sizeClass != WidgetSizeClass.COMPACT) {
                    subtitle?.let {
                        Spacer(modifier = GlanceModifier.height(WidgetTypeScale.gap(sizeClass)))
                        Text(
                            text = it,
                            style = TextStyle(
                                color = colors.secondaryText,
                                fontSize = WidgetTypeScale.caption(sizeClass)
                            ),
                            maxLines = 1
                        )
                    }
                }
            }
        } else {
            // Circular progress layout
            Column(
                modifier = GlanceModifier.fillMaxWidth(),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalAlignment = Alignment.CenterVertically
            ) {
                if (sizeClass != WidgetSizeClass.COMPACT) {
                    Text(
                        text = title,
                        style = TextStyle(
                            color = colors.secondaryText,
                            fontSize = WidgetTypeScale.title(sizeClass),
                            fontWeight = FontWeight.Medium
                        ),
                        maxLines = 1
                    )

                    Spacer(modifier = GlanceModifier.height(WidgetTypeScale.gap(sizeClass)))
                }

                // Glance's CircularProgressIndicator is indeterminate only, so
                // the reading is the number and this box is the dial around it.
                //
                // The box is what used to make this template the worst of the
                // seven: 80dp of it plus 32dp of padding is 112dp before a
                // single character, against a declared minResizeHeight of
                // 110dp. It now gives way with the slot, and at the compact end
                // it goes entirely -- a dial with no room for its own number
                // reports nothing.
                val percentage = (progress * 100).toInt()
                val percentageText = @Composable {
                    Text(
                        text = "$percentage%",
                        style = TextStyle(
                            color = colors.text,
                            fontSize = WidgetTypeScale.value(sizeClass),
                            fontWeight = FontWeight.Bold
                        ),
                        maxLines = 1
                    )
                }

                if (sizeClass == WidgetSizeClass.COMPACT) {
                    percentageText()
                } else {
                    Box(
                        modifier = GlanceModifier
                            .size(if (sizeClass == WidgetSizeClass.EXPANDED) 80.dp else 56.dp)
                            .background(trackColor),
                        contentAlignment = Alignment.Center
                    ) {
                        percentageText()
                    }
                }

                // Subtitle
                if (sizeClass == WidgetSizeClass.EXPANDED) {
                    subtitle?.let {
                        Spacer(modifier = GlanceModifier.height(WidgetTypeScale.gap(sizeClass)))
                        Text(
                            text = it,
                            style = TextStyle(
                                color = colors.secondaryText,
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
 * Receiver for Progress Widget.
 */
class ProgressWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = ProgressGlanceWidget()
}
