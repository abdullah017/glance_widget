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
import dev.glance.widget.android.CornerRadius
import dev.glance.widget.android.GlanceWidgetManager
import dev.glance.widget.android.widgetColors
import dev.glance.widget.android.ImageCache
import dev.glance.widget.android.ReportActionCallback
import dev.glance.widget.android.WidgetSizeClass
import dev.glance.widget.android.WidgetSlots
import dev.glance.widget.android.WidgetTypeScale

/**
 * Image Widget - displays a title, an image (from base64), and optional subtitle.
 * Perfect for photo displays, album art, thumbnail previews, etc.
 */
class ImageGlanceWidget : GlanceAppWidget() {

    override val stateDefinition: GlanceStateDefinition<*> = PreferencesGlanceStateDefinition

    override val sizeMode = WidgetSlots.resizable

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent {
            val prefs = currentState<Preferences>()
            ImageWidgetContent(prefs)
        }
    }
}

@Composable
internal fun ImageWidgetContent(prefs: Preferences) {
    val widgetId = prefs[GlanceWidgetManager.widgetIdKey] ?: "image"
    val title = prefs[GlanceWidgetManager.titleKey] ?: ""
    val subtitle = prefs[GlanceWidgetManager.subtitleKey]
    val imagePath = prefs[GlanceWidgetManager.imagePathKey]
    val stamp = prefs[GlanceWidgetManager.timestampKey] ?: 0L
    val imageFit = prefs[GlanceWidgetManager.imageFitKey] ?: "cover"
    val deepLinkUri = prefs[GlanceWidgetManager.deepLinkUriKey]
    val isDark = prefs[GlanceWidgetManager.isDarkKey] ?: true

    val colors = widgetColors(prefs)

    val sizeClass = WidgetSizeClass.of(LocalSize.current)

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
        // The picture is the widget. It takes what is left after the text, so
        // every line of text here is subtracted from it -- at the 110dp slot
        // image_widget_info.xml allows, a title, a two-line caption and 32dp of
        // padding left the picture 5dp. The text gives way instead.
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
                            color = colors.secondaryText,
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
                        color = colors.secondaryText,
                        fontSize = 12.sp
                    )
                )
            }
        }

        // Subtitle (optional). Two lines is most of a short slot, so it is one
        // line until there is room for the second.
        if (sizeClass != WidgetSizeClass.COMPACT) {
            subtitle?.let {
                if (it.isNotEmpty()) {
                    Spacer(modifier = GlanceModifier.height(WidgetTypeScale.gap(sizeClass)))
                    Text(
                        text = it,
                        style = TextStyle(
                            color = colors.secondaryText,
                            fontSize = WidgetTypeScale.caption(sizeClass),
                            fontWeight = FontWeight.Normal
                        ),
                        maxLines = if (sizeClass == WidgetSizeClass.EXPANDED) 2 else 1
                    )
                }
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
