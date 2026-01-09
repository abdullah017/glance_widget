package com.example.glance_widget_android.templates

import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.datastore.preferences.core.Preferences
import androidx.glance.*
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetReceiver
import androidx.glance.appwidget.provideContent
import androidx.glance.layout.*
import androidx.glance.state.GlanceStateDefinition
import androidx.glance.state.PreferencesGlanceStateDefinition
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import com.example.glance_widget_android.GlanceWidgetManager

/**
 * Simple Widget - displays title, value, and optional subtitle.
 * Perfect for crypto prices, weather, or any single-value display.
 */
class SimpleGlanceWidget : GlanceAppWidget() {

    override val stateDefinition: GlanceStateDefinition<*> = PreferencesGlanceStateDefinition

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent {
            val prefs = currentState<Preferences>()
            SimpleWidgetContent(prefs)
        }
    }
}

@Composable
private fun SimpleWidgetContent(prefs: Preferences) {
    val widgetId = prefs[GlanceWidgetManager.widgetIdKey] ?: "simple"
    val title = prefs[GlanceWidgetManager.titleKey] ?: "Title"
    val value = prefs[GlanceWidgetManager.valueKey] ?: "--"
    val subtitle = prefs[GlanceWidgetManager.subtitleKey]
    val subtitleColor = prefs[GlanceWidgetManager.subtitleColorKey]
    val isDark = prefs[GlanceWidgetManager.isDarkKey] ?: true

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

    val borderRadius = prefs[GlanceWidgetManager.borderRadiusKey]?.toInt() ?: 16

    Box(
        modifier = GlanceModifier
            .fillMaxSize()
            .background(backgroundColor)
            .cornerRadius(borderRadius.dp)
            .clickable {
                GlanceWidgetManager.sendActionEvent(widgetId, "tap")
            }
            .padding(16.dp),
        contentAlignment = Alignment.Center
    ) {
        Column(
            modifier = GlanceModifier.fillMaxWidth(),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Title
            Text(
                text = title,
                style = TextStyle(
                    color = secondaryTextColor,
                    fontSize = 14.sp,
                    fontWeight = FontWeight.Medium
                )
            )

            Spacer(modifier = GlanceModifier.height(8.dp))

            // Value (large)
            Text(
                text = value,
                style = TextStyle(
                    color = textColor,
                    fontSize = 28.sp,
                    fontWeight = FontWeight.Bold
                )
            )

            // Subtitle (optional)
            subtitle?.let {
                Spacer(modifier = GlanceModifier.height(4.dp))
                Text(
                    text = it,
                    style = TextStyle(
                        color = subtitleColor?.let { c ->
                            ColorProvider(android.graphics.Color.valueOf(c))
                        } ?: secondaryTextColor,
                        fontSize = 14.sp,
                        fontWeight = FontWeight.Medium
                    )
                )
            }
        }
    }
}

/**
 * Receiver for Simple Widget.
 */
class SimpleWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = SimpleGlanceWidget()
}
