package dev.glance.widget.android.templates

import android.content.Context
import android.content.Intent
import android.net.Uri
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.datastore.preferences.core.Preferences
import androidx.glance.*
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
import dev.glance.widget.android.ReportActionCallback

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
    val deepLinkUri = prefs[GlanceWidgetManager.deepLinkUriKey]
    val isDark = prefs[GlanceWidgetManager.isDarkKey] ?: true

    // Theme colors
    val backgroundColor = prefs[GlanceWidgetManager.backgroundColorKey]
        ?.let { ColorProvider(Color(it.toInt())) }
        ?: ColorProvider(Color(if (isDark) 0xFF1A1A2E.toInt() else 0xFFFFFFFF.toInt()))

    val textColor = prefs[GlanceWidgetManager.textColorKey]
        ?.let { ColorProvider(Color(it.toInt())) }
        ?: ColorProvider(Color(if (isDark) 0xFFFFFFFF.toInt() else 0xFF212121.toInt()))

    val secondaryTextColor = prefs[GlanceWidgetManager.secondaryTextColorKey]
        ?.let { ColorProvider(Color(it.toInt())) }
        ?: ColorProvider(Color(if (isDark) 0xFFB0B0B0.toInt() else 0xFF757575.toInt()))

    val accentColor = prefs[GlanceWidgetManager.accentColorKey]
        ?.let { ColorProvider(Color(it.toInt())) }
        ?: ColorProvider(Color(0xFF2196F3.toInt()))

    val progressColor = progressColorInt?.let { ColorProvider(Color(it.toInt())) } ?: accentColor
    val trackColor = trackColorInt?.let { ColorProvider(Color(it.toInt())) }
        ?: ColorProvider(Color(if (isDark) 0xFF3A3A4E.toInt() else 0xFFE0E0E0.toInt()))

    Box(
        modifier = GlanceModifier
            .fillMaxSize()
            .background(backgroundColor)
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
                // Note: Glance CircularProgressIndicator only supports indeterminate mode
                // So we show a styled percentage display instead
                Box(
                    modifier = GlanceModifier
                        .size(80.dp)
                        .background(trackColor),
                    contentAlignment = Alignment.Center
                ) {
                    // Percentage text
                    val percentage = (progress * 100).toInt()
                    Text(
                        text = "$percentage%",
                        style = TextStyle(
                            color = textColor,
                            fontSize = 24.sp,
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
