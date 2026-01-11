package com.example.glance_widget_android.templates

import android.content.Context
import android.util.Log
import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.datastore.preferences.core.Preferences
import androidx.glance.*
import androidx.glance.action.clickable
import androidx.glance.appwidget.CheckBox
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetReceiver
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
import com.example.glance_widget_android.GlanceWidgetManager
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken

/**
 * List Widget - displays a list of items with optional checkboxes.
 * Perfect for to-do lists, news headlines, etc.
 */
class ListGlanceWidget : GlanceAppWidget() {

    override val stateDefinition: GlanceStateDefinition<*> = PreferencesGlanceStateDefinition

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent {
            val prefs = currentState<Preferences>()
            ListWidgetContent(prefs)
        }
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
private fun ListWidgetContent(prefs: Preferences) {
    val widgetId = prefs[GlanceWidgetManager.widgetIdKey] ?: "list"
    val title = prefs[GlanceWidgetManager.titleKey] ?: "List"
    val itemsString = prefs[GlanceWidgetManager.itemsKey] ?: ""
    val showCheckboxes = prefs[GlanceWidgetManager.showCheckboxesKey] ?: false
    val isDark = prefs[GlanceWidgetManager.isDarkKey] ?: true

    // Parse items
    val items = parseItems(itemsString)

    // Theme colors
    val backgroundColor = prefs[GlanceWidgetManager.backgroundColorKey]
        ?.let { ColorProvider(android.graphics.Color.valueOf(it)) }
        ?: ColorProvider(if (isDark) android.graphics.Color.parseColor("#1A1A2E") else android.graphics.Color.WHITE)

    val textColor = prefs[GlanceWidgetManager.textColorKey]
        ?.let { ColorProvider(android.graphics.Color.valueOf(it)) }
        ?: ColorProvider(if (isDark) android.graphics.Color.WHITE else android.graphics.Color.parseColor("#212121"))

    val secondaryTextColor = prefs[GlanceWidgetManager.secondaryTextColorKey]
        ?.let { ColorProvider(android.graphics.Color.valueOf(it)) }
        ?: ColorProvider(if (isDark) android.graphics.Color.parseColor("#B0B0B0") else android.graphics.Color.parseColor("#757575"))

    val accentColor = prefs[GlanceWidgetManager.accentColorKey]
        ?.let { ColorProvider(android.graphics.Color.valueOf(it)) }
        ?: ColorProvider(android.graphics.Color.parseColor("#2196F3"))

    val borderRadius = prefs[GlanceWidgetManager.borderRadiusKey]?.toInt() ?: 16

    Column(
        modifier = GlanceModifier
            .fillMaxSize()
            .background(backgroundColor)
            .cornerRadius(borderRadius.dp)
            .padding(16.dp)
    ) {
        // Header
        Row(
            modifier = GlanceModifier
                .fillMaxWidth()
                .padding(bottom = 12.dp),
            horizontalAlignment = Alignment.Start,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = title,
                style = TextStyle(
                    color = textColor,
                    fontSize = 18.sp,
                    fontWeight = FontWeight.Bold
                )
            )

            Spacer(modifier = GlanceModifier.defaultWeight())

            // Item count badge
            Text(
                text = "${items.size}",
                style = TextStyle(
                    color = secondaryTextColor,
                    fontSize = 14.sp
                )
            )
        }

        // Divider
        Box(
            modifier = GlanceModifier
                .fillMaxWidth()
                .height(1.dp)
                .background(ColorProvider(
                    if (isDark) android.graphics.Color.parseColor("#3A3A4E")
                    else android.graphics.Color.parseColor("#E0E0E0")
                ))
        ) {}

        Spacer(modifier = GlanceModifier.height(8.dp))

        // Items list
        if (items.isEmpty()) {
            Box(
                modifier = GlanceModifier.fillMaxSize(),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = "No items",
                    style = TextStyle(
                        color = secondaryTextColor,
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
                        showCheckbox = showCheckboxes,
                        textColor = textColor,
                        secondaryTextColor = secondaryTextColor,
                        accentColor = accentColor,
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
    showCheckbox: Boolean,
    textColor: ColorProvider,
    secondaryTextColor: ColorProvider,
    accentColor: ColorProvider,
    isDark: Boolean
) {
    Row(
        modifier = GlanceModifier
            .fillMaxWidth()
            .padding(vertical = 8.dp)
            .clickable {
                GlanceWidgetManager.sendActionEvent(
                    widgetId,
                    "itemTap",
                    mapOf("index" to index)
                )
            },
        verticalAlignment = Alignment.CenterVertically
    ) {
        if (showCheckbox) {
            CheckBox(
                checked = item.checked,
                onCheckedChange = null, // Handled by clickable
                modifier = GlanceModifier.padding(end = 12.dp),
                colors = androidx.glance.appwidget.CheckboxDefaults.colors(
                    checkedColor = accentColor,
                    uncheckedColor = secondaryTextColor
                )
            )
        }

        Column(
            modifier = GlanceModifier.defaultWeight()
        ) {
            Text(
                text = item.text,
                style = TextStyle(
                    color = if (item.checked && showCheckbox) secondaryTextColor else textColor,
                    fontSize = 14.sp,
                    fontWeight = FontWeight.Normal
                ),
                maxLines = 1
            )

            item.secondaryText?.let { secondary ->
                if (secondary.isNotEmpty()) {
                    Text(
                        text = secondary,
                        style = TextStyle(
                            color = secondaryTextColor,
                            fontSize = 12.sp
                        ),
                        maxLines = 1
                    )
                }
            }
        }
    }
}

/**
 * Parses the serialized items string back to ListItem objects.
 * Uses JSON parsing for robust handling of special characters.
 * Falls back to legacy delimiter parsing for backward compatibility.
 */
private fun parseItems(itemsString: String): List<ListItem> {
    if (itemsString.isEmpty()) return emptyList()

    // Try JSON parsing first (new format)
    if (itemsString.startsWith("[")) {
        return try {
            val gson = Gson()
            val type = object : TypeToken<List<Map<String, Any?>>>() {}.type
            val items: List<Map<String, Any?>> = gson.fromJson(itemsString, type)

            items.map { itemMap ->
                ListItem(
                    text = itemMap["text"] as? String ?: "",
                    checked = itemMap["checked"] as? Boolean ?: false,
                    secondaryText = (itemMap["secondaryText"] as? String)?.takeIf { it.isNotEmpty() }
                )
            }
        } catch (e: Exception) {
            Log.e("ListGlanceWidget", "Failed to parse items as JSON, falling back to legacy format", e)
            parseLegacyItems(itemsString)
        }
    }

    // Legacy delimiter-based parsing for backward compatibility
    return parseLegacyItems(itemsString)
}

/**
 * Legacy parsing using delimiter-based format.
 * Kept for backward compatibility with older widget data.
 * @deprecated Use JSON format for new implementations.
 */
private fun parseLegacyItems(itemsString: String): List<ListItem> {
    return itemsString.split("|||").mapNotNull { itemStr ->
        val parts = itemStr.split("::")
        if (parts.isNotEmpty()) {
            ListItem(
                text = parts.getOrNull(0) ?: "",
                checked = parts.getOrNull(1)?.toBoolean() ?: false,
                secondaryText = parts.getOrNull(2)?.takeIf { it.isNotEmpty() }
            )
        } else null
    }
}

/**
 * Receiver for List Widget.
 */
class ListWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = ListGlanceWidget()
}
