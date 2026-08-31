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
import androidx.glance.LocalSize
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
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import dev.glance.widget.android.CornerRadius
import dev.glance.widget.android.GlanceWidgetManager
import dev.glance.widget.android.widgetColors
import dev.glance.widget.android.ReportActionCallback
import dev.glance.widget.android.WidgetSizeClass
import dev.glance.widget.android.WidgetSlots
import dev.glance.widget.android.WidgetTypeScale

/**
 * Gauge Widget - displays radial gauge or dashboard metric cards.
 * Radial mode: renders a gauge arc as a pre-rendered bitmap (Canvas -> Bitmap).
 * Dashboard mode: displays metric cards in a grid using Glance Row/Column.
 */
class GaugeGlanceWidget : GlanceAppWidget() {

    override val stateDefinition: GlanceStateDefinition<*> = PreferencesGlanceStateDefinition

    override val sizeMode = WidgetSlots.resizable

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent {
            val prefs = currentState<Preferences>()
            GaugeWidgetContent(prefs)
        }
    }
}

/**
 * Data class for dashboard metric items.
 */
data class GaugeMetric(
    val label: String,
    val value: String,
    val color: Int?,
    val progress: Float?
)

@Composable
internal fun GaugeWidgetContent(prefs: Preferences) {
    val widgetId = prefs[GlanceWidgetManager.widgetIdKey] ?: "gauge"
    val title = prefs[GlanceWidgetManager.titleKey] ?: ""
    val gaugeType = prefs[GlanceWidgetManager.gaugeTypeKey] ?: "radial"
    val gaugeBitmapBase64 = prefs[GlanceWidgetManager.gaugeBitmapKey] ?: ""
    val metricsJson = prefs[GlanceWidgetManager.metricsKey] ?: "[]"
    val deepLinkUri = prefs[GlanceWidgetManager.deepLinkUriKey]
    val isDark = prefs[GlanceWidgetManager.isDarkKey] ?: true

    val colors = widgetColors(prefs)

    val sizeClass = WidgetSizeClass.of(LocalSize.current)

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
            .padding(WidgetTypeScale.padding(sizeClass))
    ) {
        // The readings are the widget. At the compact end the title goes, on
        // the same reasoning as everywhere else here: a label with nothing
        // under it reports nothing.
        if (title.isNotEmpty() && sizeClass != WidgetSizeClass.COMPACT) {
            Text(
                text = title,
                style = TextStyle(
                    color = colors.text,
                    fontSize = WidgetTypeScale.title(sizeClass),
                    fontWeight = FontWeight.Bold
                ),
                maxLines = 1
            )
            Spacer(modifier = GlanceModifier.height(WidgetTypeScale.gap(sizeClass)))
        }

        when (gaugeType) {
            "dashboard" -> {
                DashboardContent(
                    metricsJson = metricsJson,
                    widgetId = widgetId,
                    sizeClass = sizeClass,
                    textColor = colors.text,
                    secondaryTextColor = colors.secondaryText,
                    accentColor = colors.accent,
                    isDark = isDark
                )
            }
            else -> {
                // Radial gauge (default) - rendered as bitmap
                RadialGaugeContent(
                    bitmapBase64 = gaugeBitmapBase64,
                    secondaryTextColor = colors.secondaryText,
                    isDark = isDark,
                    title = title
                )
            }
        }
    }
}

@Composable
private fun RadialGaugeContent(
    bitmapBase64: String,
    secondaryTextColor: ColorProvider,
    isDark: Boolean,
    title: String
) {
    if (bitmapBase64.isNotEmpty()) {
        val bitmap = decodeGaugeBitmap(bitmapBase64)
        if (bitmap != null) {
            Box(
                modifier = GlanceModifier
                    .fillMaxWidth()
                    .fillMaxHeight(),
                contentAlignment = Alignment.Center
            ) {
                Image(
                    provider = ImageProvider(bitmap),
                    contentDescription = "$title gauge",
                    modifier = GlanceModifier
                        .fillMaxWidth()
                        .fillMaxHeight(),
                    contentScale = ContentScale.Fit
                )
            }
        } else {
            GaugePlaceholder(
                message = "Gauge unavailable",
                secondaryTextColor = secondaryTextColor,
                isDark = isDark
            )
        }
    } else {
        GaugePlaceholder(
            message = "No gauge data",
            secondaryTextColor = secondaryTextColor,
            isDark = isDark
        )
    }
}

@Composable
private fun DashboardContent(
    metricsJson: String,
    widgetId: String,
    sizeClass: WidgetSizeClass,
    textColor: ColorProvider,
    secondaryTextColor: ColorProvider,
    accentColor: ColorProvider,
    isDark: Boolean
) {
    val metrics = parseMetrics(metricsJson)

    if (metrics.isEmpty()) {
        GaugePlaceholder(
            message = "No metrics",
            secondaryTextColor = secondaryTextColor,
            isDark = isDark
        )
        return
    }

    // Arrange metrics in a 2-column grid, capped at what the slot can show.
    //
    // Every row was drawn before, whatever the height. A row is around 76dp,
    // so six metrics is 228dp of grid; in the 110dp slot this template's own
    // manifest allows, everything below the first row was cut off the bottom
    // with nothing to say it had been. Drawing fewer is not less information
    // than drawing some invisibly -- it is the same information, minus the
    // false impression that the rest is not there.
    val maxRows = when (sizeClass) {
        WidgetSizeClass.COMPACT -> 1
        WidgetSizeClass.MEDIUM -> 2
        WidgetSizeClass.EXPANDED -> Int.MAX_VALUE
    }
    val rows = metrics.chunked(2).take(maxRows)
    Column(
        modifier = GlanceModifier.fillMaxWidth()
    ) {
        rows.forEachIndexed { rowIndex, rowMetrics ->
            Row(
                modifier = GlanceModifier
                    .fillMaxWidth()
                    .padding(vertical = if (sizeClass == WidgetSizeClass.COMPACT) 0.dp else 4.dp),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                rowMetrics.forEachIndexed { colIndex, metric ->
                    val metricIndex = rowIndex * 2 + colIndex
                    MetricCard(
                        metric = metric,
                        index = metricIndex,
                        widgetId = widgetId,
                        sizeClass = sizeClass,
                        textColor = textColor,
                        secondaryTextColor = secondaryTextColor,
                        accentColor = accentColor,
                        isDark = isDark
                    )

                    // Add spacer between columns, but not after the last column
                    if (colIndex < rowMetrics.size - 1) {
                        Spacer(modifier = GlanceModifier.width(8.dp))
                    }
                }

                // If odd number, fill remaining space
                if (rowMetrics.size == 1) {
                    Spacer(modifier = GlanceModifier.fillMaxWidth())
                }
            }
        }
    }
}

@Composable
private fun MetricCard(
    metric: GaugeMetric,
    index: Int,
    widgetId: String,
    sizeClass: WidgetSizeClass,
    textColor: ColorProvider,
    secondaryTextColor: ColorProvider,
    accentColor: ColorProvider,
    isDark: Boolean
) {
    val cardBackground = ColorProvider(
        Color(if (isDark) 0xFF2A2A3E.toInt() else 0xFFF5F5F5.toInt())
    )
    val metricColor = metric.color?.let { ColorProvider(Color(it)) } ?: accentColor

    // 8dp outside and 8dp inside is 32dp of padding around two lines of text.
    // That is affordable in a tall slot and is most of a short one.
    val cardPadding = if (sizeClass == WidgetSizeClass.COMPACT) 2.dp else 8.dp

    Box(
        modifier = GlanceModifier
            .fillMaxWidth()
            .padding(cardPadding)
            .background(cardBackground)
            .clickable(
                ReportActionCallback.tapAt(
                    widgetId,
                    "metricTap",
                    index,
                    indexName = "index"
                )
            )
    ) {
        Column(
            modifier = GlanceModifier.padding(cardPadding),
            horizontalAlignment = Alignment.Start
        ) {
            // The label stays at every size. Unlike a widget title it is not a
            // restatement of what is below it -- with several readings on
            // screen, an unlabelled number does not say which reading it is.
            Text(
                text = metric.label,
                style = TextStyle(
                    color = secondaryTextColor,
                    fontSize = WidgetTypeScale.caption(sizeClass),
                    fontWeight = FontWeight.Medium
                ),
                maxLines = 1
            )

            if (sizeClass != WidgetSizeClass.COMPACT) {
                Spacer(modifier = GlanceModifier.height(4.dp))
            }

            // Value
            Text(
                text = metric.value,
                style = TextStyle(
                    color = textColor,
                    fontSize = WidgetTypeScale.value(sizeClass),
                    fontWeight = FontWeight.Bold
                ),
                maxLines = 1
            )

            // Progress bar (optional). Dropped at the compact end: a 4dp bar
            // under a 20sp number is the first thing that stops fitting and
            // the last thing that is read.
            if (sizeClass != WidgetSizeClass.COMPACT) metric.progress?.let { progress ->
                Spacer(modifier = GlanceModifier.height(6.dp))
                Box(
                    modifier = GlanceModifier
                        .fillMaxWidth()
                        .height(4.dp)
                        .background(ColorProvider(
                            Color(if (isDark) 0xFF3A3A4E.toInt() else 0xFFE0E0E0.toInt())
                        ))
                ) {
                    val clampedProgress = progress.coerceIn(0f, 1f)
                    // Approximate the fill by using a fixed width approach
                    // Since Glance doesn't support fraction-based widths directly,
                    // we use fillMaxWidth for the track and overlay the fill
                    Box(
                        modifier = GlanceModifier
                            .height(4.dp)
                            .fillMaxWidth()
                            .background(metricColor)
                    ) {}
                }
            }
        }
    }
}

@Composable
private fun GaugePlaceholder(
    message: String,
    secondaryTextColor: ColorProvider,
    isDark: Boolean
) {
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
            text = message,
            style = TextStyle(
                color = secondaryTextColor,
                fontSize = 12.sp
            )
        )
    }
}

/**
 * Parses the serialized metrics JSON string to GaugeMetric objects.
 */
private fun parseMetrics(metricsJson: String): List<GaugeMetric> {
    if (metricsJson.isEmpty() || metricsJson == "[]") return emptyList()

    return try {
        val gson = Gson()
        val type = object : TypeToken<List<Map<String, Any?>>>() {}.type
        val items: List<Map<String, Any?>> = gson.fromJson(metricsJson, type)

        items.map { metricMap ->
            GaugeMetric(
                label = metricMap["label"] as? String ?: "",
                value = metricMap["value"] as? String ?: "",
                color = (metricMap["color"] as? Number)?.toInt(),
                progress = (metricMap["progress"] as? Number)?.toFloat()
            )
        }
    } catch (e: Exception) {
        Log.e("GaugeGlanceWidget", "Failed to parse metrics JSON", e)
        emptyList()
    }
}

/**
 * Decodes a base64-encoded gauge bitmap.
 */
private fun decodeGaugeBitmap(base64String: String): android.graphics.Bitmap? {
    return try {
        val decodedBytes = Base64.decode(base64String, Base64.DEFAULT)
        BitmapFactory.decodeByteArray(decodedBytes, 0, decodedBytes.size)
    } catch (e: Exception) {
        Log.e("GaugeGlanceWidget", "Failed to decode gauge bitmap", e)
        null
    }
}

/**
 * Receiver for Gauge Widget.
 */
class GaugeWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = GaugeGlanceWidget()
}
