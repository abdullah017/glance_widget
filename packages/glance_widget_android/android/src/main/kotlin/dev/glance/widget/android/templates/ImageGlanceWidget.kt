package dev.glance.widget.android.templates

import android.content.Context
import android.content.Intent
import android.net.Uri
import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.datastore.preferences.core.Preferences
import androidx.glance.*
import androidx.glance.appwidget.action.actionStartActivity
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
import dev.glance.widget.android.GlanceWidgetManager
import dev.glance.widget.android.ImageCache

/**
 * Image Widget - displays a title, an image (from base64), and optional subtitle.
 * Perfect for photo displays, album art, thumbnail previews, etc.
 */
class ImageGlanceWidget : GlanceAppWidget() {

    override val stateDefinition: GlanceStateDefinition<*> = PreferencesGlanceStateDefinition

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent {
            val prefs = currentState<Preferences>()
            ImageWidgetContent(prefs)
        }
    }
}

@Composable
private fun ImageWidgetContent(prefs: Preferences) {
    val widgetId = prefs[GlanceWidgetManager.widgetIdKey] ?: "image"
    val title = prefs[GlanceWidgetManager.titleKey] ?: ""
    val subtitle = prefs[GlanceWidgetManager.subtitleKey]
    val imagePath = prefs[GlanceWidgetManager.imagePathKey]
    val stamp = prefs[GlanceWidgetManager.timestampKey] ?: 0L
    val imageFit = prefs[GlanceWidgetManager.imageFitKey] ?: "cover"
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

    // Determine content scale from imageFit
    val contentScale = when (imageFit) {
        "contain" -> ContentScale.Fit
        "fill" -> ContentScale.FillBounds
        "fitWidth" -> ContentScale.FillBounds
        else -> ContentScale.Crop // "cover" default
    }

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
        // Title (if not empty)
        if (title.isNotEmpty()) {
            Text(
                text = title,
                style = TextStyle(
                    color = textColor,
                    fontSize = 16.sp,
                    fontWeight = FontWeight.Bold
                )
            )
            Spacer(modifier = GlanceModifier.height(8.dp))
        }

        // Image
        if (imagePath != null) {
            // Decoded once and held, rather than re-decoded on every
            // recomposition. The picture was already downsampled at update time.
            val bitmap = ImageCache.get(imagePath, stamp)
            if (bitmap != null) {
                Image(
                    provider = ImageProvider(bitmap),
                    contentDescription = title.ifEmpty { "Widget image" },
                    modifier = GlanceModifier
                        .fillMaxWidth()
                        .fillMaxHeight(),
                    contentScale = contentScale
                )
            } else {
                // Fallback when image decode fails
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
                        text = "Image unavailable",
                        style = TextStyle(
                            color = secondaryTextColor,
                            fontSize = 12.sp
                        )
                    )
                }
            }
        } else {
            // No image provided placeholder
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
                    text = "No image",
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
                    maxLines = 2
                )
            }
        }
    }
}

/**
 * Receiver for Image Widget.
 */
class ImageWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = ImageGlanceWidget()
}
