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

    Box(
        modifier = GlanceModifier
            .fillMaxSize()
            .background(backgroundColor)
            .cornerRadius(CornerRadius.dpFor(prefs[GlanceWidgetManager.borderRadiusKey]).dp)
            .clickable {
                if (deepLinkUri != null) {
                    actionStartActivity(Intent(Intent.ACTION_VIEW, Uri.parse(deepLinkUri)))
                } else {
                    GlanceWidgetManager.sendActionEvent(widgetId, "tap")
                }
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
                            ColorProvider(Color(c.toInt()))
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
