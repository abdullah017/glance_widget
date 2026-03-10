package com.example.glance_widget_android.templates

import android.content.Context
import android.content.Intent
import android.graphics.BitmapFactory
import android.net.Uri
import android.util.Base64
import android.util.Log
import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.datastore.preferences.core.Preferences
import androidx.glance.*
import androidx.glance.action.actionStartActivity
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
import androidx.compose.ui.graphics.Color
import com.example.glance_widget_android.GlanceWidgetManager

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

    Column(
        modifier = GlanceModifier
            .fillMaxSize()
            .background(backgroundColor)
            .clickable {
                if (deepLinkUri != null) {
                    actionStartActivity(Intent(Intent.ACTION_VIEW, Uri.parse(deepLinkUri)))
                } else {
                    GlanceWidgetManager.sendActionEvent(widgetId, "tap")
                }
            }
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
                        color = textColor,
                        fontSize = 16.sp,
                        fontWeight = FontWeight.Bold
                    )
                )

                Spacer(modifier = GlanceModifier.defaultWeight())

                // Chart type label
                Text(
                    text = chartType.replaceFirstChar { it.uppercase() },
                    style = TextStyle(
                        color = secondaryTextColor,
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
                        .defaultWeight(),
                    contentScale = ContentScale.FillBounds
                )
            } else {
                // Fallback when bitmap decode fails
                Box(
                    modifier = GlanceModifier
                        .fillMaxWidth()
                        .defaultWeight()
                        .background(ColorProvider(
                            Color(if (isDark) 0xFF3A3A4E.toInt() else 0xFFE0E0E0.toInt())
                        )),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        text = "Chart unavailable",
                        style = TextStyle(
                            color = secondaryTextColor,
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
                    .defaultWeight()
                    .background(ColorProvider(
                        Color(if (isDark) 0xFF3A3A4E.toInt() else 0xFFE0E0E0.toInt())
                    )),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = "No chart data",
                    style = TextStyle(
                        color = secondaryTextColor,
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
                        color = secondaryTextColor,
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
