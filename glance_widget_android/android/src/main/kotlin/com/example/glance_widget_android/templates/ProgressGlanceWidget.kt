package com.example.glance_widget_android.templates

import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.datastore.preferences.core.Preferences
import androidx.glance.*
import androidx.glance.action.clickable
import androidx.glance.appwidget.CircularProgressIndicator
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetReceiver
import androidx.glance.appwidget.LinearProgressIndicator
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
 * Progress Widget - displays a progress indicator with title and subtitle.
 * Perfect for download progress, goal tracking, etc.
 */
class ProgressGlanceWidget : GlanceAppWidget() {

    override val stateDefinition: GlanceStateDefinition<*> = PreferencesGlanceStateDefinition

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent {
            val prefs = currentState<Preferences>()
            ProgressWidgetContent(prefs)
        }
    }
}

@Composable
private fun ProgressWidgetContent(prefs: Preferences) {
    val widgetId = prefs[GlanceWidgetManager.widgetIdKey] ?: "progress"
    val title = prefs[GlanceWidgetManager.titleKey] ?: "Progress"
    val progress = prefs[GlanceWidgetManager.progressKey] ?: 0f
    val subtitle = prefs[GlanceWidgetManager.subtitleKey]
    val progressType = prefs[GlanceWidgetManager.progressTypeKey] ?: "circular"
    val progressColorInt = prefs[GlanceWidgetManager.progressColorKey]
    val trackColorInt = prefs[GlanceWidgetManager.trackColorKey]
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

    val accentColor = prefs[GlanceWidgetManager.accentColorKey]
        ?.let { ColorProvider(android.graphics.Color.valueOf(it)) }
        ?: ColorProvider(android.graphics.Color.parseColor("#2196F3"))

    val progressColor = progressColorInt?.let { ColorProvider(android.graphics.Color.valueOf(it)) } ?: accentColor
    val trackColor = trackColorInt?.let { ColorProvider(android.graphics.Color.valueOf(it)) }
        ?: ColorProvider(if (isDark) android.graphics.Color.parseColor("#3A3A4E") else android.graphics.Color.parseColor("#E0E0E0"))

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
        if (progressType == "linear") {
            // Linear progress layout
            Column(
                modifier = GlanceModifier.fillMaxWidth(),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalAlignment = Alignment.CenterVertically
            ) {
                // Title
                Text(
                    text = title,
                    style = TextStyle(
                        color = textColor,
                        fontSize = 16.sp,
                        fontWeight = FontWeight.Medium
                    )
                )

                Spacer(modifier = GlanceModifier.height(12.dp))

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
                subtitle?.let {
                    Spacer(modifier = GlanceModifier.height(8.dp))
                    Text(
                        text = it,
                        style = TextStyle(
                            color = secondaryTextColor,
                            fontSize = 14.sp
                        )
                    )
                }
            }
        } else {
            // Circular progress layout
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

                Spacer(modifier = GlanceModifier.height(12.dp))

                // Circular Progress with percentage in center
                Box(
                    contentAlignment = Alignment.Center
                ) {
                    CircularProgressIndicator(
                        progress = progress,
                        modifier = GlanceModifier.size(80.dp),
                        color = progressColor
                    )

                    // Percentage text
                    val percentage = (progress * 100).toInt()
                    Text(
                        text = "$percentage%",
                        style = TextStyle(
                            color = textColor,
                            fontSize = 18.sp,
                            fontWeight = FontWeight.Bold
                        )
                    )
                }

                // Subtitle
                subtitle?.let {
                    Spacer(modifier = GlanceModifier.height(8.dp))
                    Text(
                        text = it,
                        style = TextStyle(
                            color = secondaryTextColor,
                            fontSize = 12.sp
                        )
                    )
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
