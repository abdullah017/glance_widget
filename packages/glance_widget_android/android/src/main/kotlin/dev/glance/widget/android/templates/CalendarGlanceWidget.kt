package dev.glance.widget.android.templates

import android.content.Context
import android.content.Intent
import android.net.Uri
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
import androidx.glance.appwidget.lazy.LazyColumn
import androidx.glance.appwidget.lazy.itemsIndexed
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
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Calendar Widget - displays a date header and list of events.
 * Perfect for schedule display, appointment tracking, etc.
 */
class CalendarGlanceWidget : GlanceAppWidget() {

    override val stateDefinition: GlanceStateDefinition<*> = PreferencesGlanceStateDefinition

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent {
            val prefs = currentState<Preferences>()
            CalendarWidgetContent(prefs)
        }
    }
}

/**
 * Data class for calendar events.
 */
data class CalendarEvent(
    val title: String,
    val time: String,
    val color: Int?
)

@Composable
private fun CalendarWidgetContent(prefs: Preferences) {
    val widgetId = prefs[GlanceWidgetManager.widgetIdKey] ?: "calendar"
    val title = prefs[GlanceWidgetManager.titleKey] ?: "Calendar"
    val dateString = prefs[GlanceWidgetManager.dateKey] ?: ""
    val eventsJson = prefs[GlanceWidgetManager.eventsKey] ?: "[]"
    val maxEvents = prefs[GlanceWidgetManager.maxEventsKey] ?: 5
    val deepLinkUri = prefs[GlanceWidgetManager.deepLinkUriKey]
    val isDark = prefs[GlanceWidgetManager.isDarkKey] ?: true

    // Parse date
    val dateInfo = parseDateInfo(dateString)
    val dayName = dateInfo.first
    val dateNumber = dateInfo.second
    val monthName = dateInfo.third

    // Parse events
    val allEvents = parseEvents(eventsJson)
    val events = if (allEvents.size > maxEvents) allEvents.take(maxEvents) else allEvents

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
        // Date header section
        Row(
            modifier = GlanceModifier
                .fillMaxWidth()
                .padding(bottom = 12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Date number block
            Box(
                modifier = GlanceModifier
                    .size(56.dp)
                    .background(colors.accent),
                contentAlignment = Alignment.Center
            ) {
                Column(
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    Text(
                        text = dateNumber,
                        style = TextStyle(
                            color = ColorProvider(Color(0xFFFFFFFF.toInt())),
                            fontSize = 24.sp,
                            fontWeight = FontWeight.Bold
                        )
                    )
                    Text(
                        text = dayName.uppercase(),
                        style = TextStyle(
                            color = ColorProvider(Color(0xFFFFFFFF.toInt())),
                            fontSize = 10.sp,
                            fontWeight = FontWeight.Medium
                        )
                    )
                }
            }

            Spacer(modifier = GlanceModifier.width(12.dp))

            // Title and month
            Column {
                Text(
                    text = title,
                    style = TextStyle(
                        color = colors.text,
                        fontSize = 18.sp,
                        fontWeight = FontWeight.Bold
                    )
                )
                Text(
                    text = monthName,
                    style = TextStyle(
                        color = colors.secondaryText,
                        fontSize = 14.sp
                    )
                )
            }
        }

        // Divider
        Box(
            modifier = GlanceModifier
                .fillMaxWidth()
                .height(1.dp)
                .background(ColorProvider(
                    Color(if (isDark) 0xFF3A3A4E.toInt() else 0xFFE0E0E0.toInt())
                ))
        ) {}

        Spacer(modifier = GlanceModifier.height(8.dp))

        // Events list
        if (events.isEmpty()) {
            Box(
                modifier = GlanceModifier.fillMaxSize(),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = "No events",
                    style = TextStyle(
                        color = colors.secondaryText,
                        fontSize = 14.sp
                    )
                )
            }
        } else {
            LazyColumn {
                itemsIndexed(events) { index, event ->
                    CalendarEventRow(
                        event = event,
                        index = index,
                        widgetId = widgetId,
                        textColor = colors.text,
                        secondaryTextColor = colors.secondaryText,
                        isDark = isDark
                    )
                }
            }

            // Show remaining count if events were truncated
            if (allEvents.size > maxEvents) {
                Spacer(modifier = GlanceModifier.height(4.dp))
                Text(
                    text = "+${allEvents.size - maxEvents} more events",
                    style = TextStyle(
                        color = colors.secondaryText,
                        fontSize = 12.sp
                    )
                )
            }
        }
    }
}

@Composable
private fun CalendarEventRow(
    event: CalendarEvent,
    index: Int,
    widgetId: String,
    textColor: ColorProvider,
    secondaryTextColor: ColorProvider,
    isDark: Boolean
) {
    Row(
        modifier = GlanceModifier
            .fillMaxWidth()
            .padding(vertical = 6.dp)
            .clickable(
                ReportActionCallback.tapAt(
                    widgetId,
                    "eventTap",
                    index,
                    indexName = "index"
                )
            ),
        verticalAlignment = Alignment.CenterVertically
    ) {
        // Colored dot indicator
        val dotColor = event.color?.let { ColorProvider(Color(it)) }
            ?: ColorProvider(Color(0xFF2196F3.toInt()))

        Box(
            modifier = GlanceModifier
                .size(10.dp)
                .background(dotColor)
        ) {}

        Spacer(modifier = GlanceModifier.width(10.dp))

        // Time
        Text(
            text = event.time,
            style = TextStyle(
                color = secondaryTextColor,
                fontSize = 12.sp,
                fontWeight = FontWeight.Medium
            )
        )

        Spacer(modifier = GlanceModifier.width(10.dp))

        // Title
        Text(
            text = event.title,
            style = TextStyle(
                color = textColor,
                fontSize = 14.sp,
                fontWeight = FontWeight.Normal
            ),
            maxLines = 1
        )
    }
}

/**
 * Parses an ISO date string into day name, date number, and month name.
 * Falls back to current date if parsing fails.
 */
private fun parseDateInfo(dateString: String): Triple<String, String, String> {
    return try {
        if (dateString.isEmpty()) {
            getCurrentDateInfo()
        } else {
            val isoFormat = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault())
            val date = isoFormat.parse(dateString) ?: Date()
            val dayName = SimpleDateFormat("EEE", Locale.getDefault()).format(date)
            val dateNumber = SimpleDateFormat("d", Locale.getDefault()).format(date)
            val monthName = SimpleDateFormat("MMMM yyyy", Locale.getDefault()).format(date)
            Triple(dayName, dateNumber, monthName)
        }
    } catch (e: Exception) {
        Log.e("CalendarGlanceWidget", "Failed to parse date: $dateString", e)
        getCurrentDateInfo()
    }
}

private fun getCurrentDateInfo(): Triple<String, String, String> {
    val now = Date()
    val dayName = SimpleDateFormat("EEE", Locale.getDefault()).format(now)
    val dateNumber = SimpleDateFormat("d", Locale.getDefault()).format(now)
    val monthName = SimpleDateFormat("MMMM yyyy", Locale.getDefault()).format(now)
    return Triple(dayName, dateNumber, monthName)
}

/**
 * Parses the serialized events JSON string back to CalendarEvent objects.
 */
private fun parseEvents(eventsJson: String): List<CalendarEvent> {
    if (eventsJson.isEmpty() || eventsJson == "[]") return emptyList()

    return try {
        val gson = Gson()
        val type = object : TypeToken<List<Map<String, Any?>>>() {}.type
        val items: List<Map<String, Any?>> = gson.fromJson(eventsJson, type)

        items.map { eventMap ->
            CalendarEvent(
                title = eventMap["title"] as? String ?: "",
                time = eventMap["time"] as? String ?: "",
                color = (eventMap["color"] as? Number)?.toInt()
            )
        }
    } catch (e: Exception) {
        Log.e("CalendarGlanceWidget", "Failed to parse events JSON", e)
        emptyList()
    }
}

/**
 * Receiver for Calendar Widget.
 */
class CalendarWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = CalendarGlanceWidget()
}
