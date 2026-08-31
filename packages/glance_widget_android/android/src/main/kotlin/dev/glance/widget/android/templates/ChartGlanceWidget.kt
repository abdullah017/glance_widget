package dev.glance.widget.android.templates

import android.content.Context
import android.content.Intent
import android.graphics.BitmapFactory
import android.net.Uri
import android.util.Base64
import android.util.Log
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
import dev.glance.widget.android.widgetColors
import dev.glance.widget.android.ReportActionCallback

/**
 * Chart Widget - displays a chart rendered as a bitmap.
 * Supports line, bar, and sparkline chart types.
 * The chart is pre-rendered to a bitmap by GlanceWidgetManager using Android Canvas API
 * because Glance does not support direct Canvas drawing.
 */
class ChartGlanceWidget : GlanceAppWidget() {

    override val stateDefinition: GlanceStateDefinition<*> = PreferencesGlanceStateDefinition

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent {
            val prefs = currentState<Preferences>()
            ChartWidgetContent(prefs)
        }
    }
}

@Composable
private fun ChartWidgetContent(prefs: Preferences) {
    val widgetId = prefs[GlanceWidgetManager.widgetIdKey] ?: "chart"
    val title = prefs[GlanceWidgetManager.titleKey] ?: ""
    val subtitle = prefs[GlanceWidgetManager.subtitleKey]
    val chartBitmapBase64 = prefs[GlanceWidgetManager.chartBitmapKey] ?: ""
    val chartType = prefs[GlanceWidgetManager.chartTypeKey] ?: "line"
    val deepLinkUri = prefs[GlanceWidgetManager.deepLinkUriKey]
    val isDark = prefs[GlanceWidgetManager.isDarkKey] ?: true

    val colors = widgetColors(prefs)

    Column(
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
            .padding(16.dp)
    ) {
        // Title header
        if (title.isNotEmpty()) {
            Row(
                modifier = GlanceModifier
                    .fillMaxWidth()
                    .padding(bottom = 8.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = title,
                    style = TextStyle(
                        color = colors.text,
                        fontSize = 16.sp,
                        fontWeight = FontWeight.Bold
                    )
                )

                Spacer(modifier = GlanceModifier.fillMaxWidth())

                // Chart type label
                Text(
                    text = chartType.replaceFirstChar { it.uppercase() },
                    style = TextStyle(
                        color = colors.secondaryText,
                        fontSize = 12.sp
                    )
                )
            }
        }

        // Chart bitmap
        if (chartBitmapBase64.isNotEmpty()) {
            val bitmap = decodeChartBitmap(chartBitmapBase64)
            if (bitmap != null) {
                Image(
                    provider = ImageProvider(bitmap),
                    contentDescription = "$title chart",
                    modifier = GlanceModifier
                        .fillMaxWidth()
                        .fillMaxHeight(),
                    contentScale = ContentScale.FillBounds
                )
            } else {
                // Fallback when bitmap decode fails
                Box(
                    modifier = GlanceModifier
                        .fillMaxWidth()
                        .fillMaxHeight()
                        .background(ColorProvider(
                            Color(if (isDark) 0xFF3A3A4E.toInt() else 0xFFE0E0E0.toInt())
                        )),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        text = "Chart unavailable",
                        style = TextStyle(
                            color = colors.secondaryText,
                            fontSize = 12.sp
                        )
                    )
                }
            }
        } else {
            // No chart data placeholder
            Box(
                modifier = GlanceModifier
                    .fillMaxWidth()
                    .fillMaxHeight()
                    .background(ColorProvider(
                        Color(if (isDark) 0xFF3A3A4E.toInt() else 0xFFE0E0E0.toInt())
                    )),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = "No chart data",
                    style = TextStyle(
                        color = colors.secondaryText,
                        fontSize = 12.sp
                    )
                )
            }
        }

        // Subtitle (optional)
        subtitle?.let {
            if (it.isNotEmpty()) {
                Spacer(modifier = GlanceModifier.height(8.dp))
                Text(
                    text = it,
                    style = TextStyle(
                        color = colors.secondaryText,
                        fontSize = 14.sp,
                        fontWeight = FontWeight.Normal
                    ),
                    maxLines = 1
                )
            }
        }
    }
}

/**
 * Decodes a base64-encoded chart bitmap.
 */
private fun decodeChartBitmap(base64String: String): android.graphics.Bitmap? {
    return try {
        val decodedBytes = Base64.decode(base64String, Base64.DEFAULT)
        BitmapFactory.decodeByteArray(decodedBytes, 0, decodedBytes.size)
    } catch (e: Exception) {
        Log.e("ChartGlanceWidget", "Failed to decode chart bitmap", e)
        null
    }
}

/**
 * Receiver for Chart Widget.
 */
class ChartWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = ChartGlanceWidget()
}
