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
import androidx.glance.LocalSize
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
import dev.glance.widget.android.WidgetSizeClass
import dev.glance.widget.android.WidgetSlots

/**
 * Simple Widget - displays title, value, and optional subtitle.
 * Perfect for crypto prices, weather, or any single-value display.
 */
class SimpleGlanceWidget : GlanceAppWidget() {

    override val stateDefinition: GlanceStateDefinition<*> = PreferencesGlanceStateDefinition

    override val sizeMode = WidgetSlots.resizable

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent {
            val prefs = currentState<Preferences>()
            SimpleWidgetContent(prefs)
        }
    }
}

@Composable
internal fun SimpleWidgetContent(prefs: Preferences) {
    val widgetId = prefs[GlanceWidgetManager.widgetIdKey] ?: "simple"
    val title = prefs[GlanceWidgetManager.titleKey] ?: "Title"
    val value = prefs[GlanceWidgetManager.valueKey] ?: "--"
    val subtitle = prefs[GlanceWidgetManager.subtitleKey]
    val subtitleColor = prefs[GlanceWidgetManager.subtitleColorKey]
    val deepLinkUri = prefs[GlanceWidgetManager.deepLinkUriKey]
    val isDark = prefs[GlanceWidgetManager.isDarkKey] ?: true

    val colors = widgetColors(prefs)

    val sizeClass = WidgetSizeClass.of(LocalSize.current)

    Box(
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
            .padding(if (sizeClass == WidgetSizeClass.COMPACT) 8.dp else 16.dp),
        contentAlignment = Alignment.Center
    ) {
        Column(
            modifier = GlanceModifier.fillMaxWidth(),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalAlignment = Alignment.CenterVertically
        ) {
            // The compact slot can be 40dp tall. A title, a spacer, a 28sp
            // value and 32dp of padding is roughly 90dp, so something has to
            // go -- and it is not the number the widget exists to show.
            if (sizeClass != WidgetSizeClass.COMPACT) {
                Text(
                    text = title,
                    style = TextStyle(
                        color = colors.secondaryText,
                        fontSize = if (sizeClass == WidgetSizeClass.EXPANDED) 16.sp else 14.sp,
                        fontWeight = FontWeight.Medium
                    )
                )

                Spacer(modifier = GlanceModifier.height(8.dp))
            }

            Text(
                text = value,
                style = TextStyle(
                    color = colors.text,
                    fontSize = when (sizeClass) {
                        WidgetSizeClass.COMPACT -> 20.sp
                        WidgetSizeClass.MEDIUM -> 28.sp
                        WidgetSizeClass.EXPANDED -> 36.sp
                    },
                    fontWeight = FontWeight.Bold
                ),
                maxLines = 1
            )

            if (sizeClass == WidgetSizeClass.EXPANDED) {
                subtitle?.let {
                    Spacer(modifier = GlanceModifier.height(4.dp))
                    Text(
                        text = it,
                        style = TextStyle(
                            color = subtitleColor?.let { c ->
                                ColorProvider(Color(c.toInt()))
                            } ?: colors.secondaryText,
                            fontSize = 14.sp,
                            fontWeight = FontWeight.Medium
                        )
                    )
                }
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
