package dev.glance.widget.android.templates

import androidx.compose.ui.unit.DpSize
import androidx.compose.ui.unit.dp
import androidx.datastore.preferences.core.mutablePreferencesOf
import androidx.glance.appwidget.testing.unit.runGlanceAppWidgetUnitTest
import androidx.glance.testing.unit.hasText
import dev.glance.widget.android.GlanceWidgetManager
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

/**
 * These two are the templates whose content already scrolled, so neither cut
 * anything off the bottom. What they did was spend a fixed header whatever room
 * they had.
 *
 * Calendar was the worse of the two: 32dp of padding, a 56dp date block, 12dp
 * under it, a divider and its spacer is 109dp -- of the 110dp slot
 * `calendar_widget_info.xml` allows. One device pixel was left for the events,
 * which are the reason the widget is on the screen.
 *
 * Both declare a 180dp minResize in one axis, so neither can be handed a
 * compact slot through its own manifest; both use `WidgetSlots.tall`. The
 * compact branch is still written and still tested, because these are library
 * templates and a consumer writes their own `widget_info`.
 */
@RunWith(RobolectricTestRunner::class)
class CalendarAndListLayoutTest {

    private val calendarPrefs = mutablePreferencesOf(
        GlanceWidgetManager.titleKey to "Today",
        // The template derives the day, the date number and the month from one
        // ISO string, so that is what a test supplies. Fixed rather than
        // "today" so the assertions below do not change with the calendar.
        GlanceWidgetManager.dateKey to "2026-08-14",
        GlanceWidgetManager.eventsKey to
            // No time here may contain the date number below: hasText matches
            // as a substring, so a 14:00 event and a date block reading 14 are
            // two hits for one assertion.
            """[{"title":"Standup","time":"09:30"},{"title":"Retro","time":"11:00"}]"""
    )

    private val listPrefs = mutablePreferencesOf(
        GlanceWidgetManager.titleKey to "Groceries",
        GlanceWidgetManager.itemsKey to
            """[{"text":"Milk","secondaryText":"2 litres","checked":false},""" +
            """{"text":"Bread","secondaryText":"sourdough","checked":true}]"""
    )

    // Calendar

    @Test
    fun `calendar keeps its events at the smallest slot`() = runGlanceAppWidgetUnitTest {
        setAppWidgetSize(DpSize(180.dp, 40.dp))
        provideComposable { CalendarWidgetContent(calendarPrefs) }

        onNode(hasText("Standup")).assertExists()
        // A calendar showing no events is not a calendar; one showing events
        // without today's date still is.
        onNode(hasText("14")).assertDoesNotExist()
        onNode(hasText("Today")).assertDoesNotExist()
    }

    @Test
    fun `calendar shows its header once there is room`() = runGlanceAppWidgetUnitTest {
        setAppWidgetSize(DpSize(250.dp, 110.dp))
        provideComposable { CalendarWidgetContent(calendarPrefs) }

        onNode(hasText("14")).assertExists()
        onNode(hasText("Today")).assertExists()
        onNode(hasText("Standup")).assertExists()
        // The month is already implied by the date block beside it.
        onNode(hasText("August 2026")).assertDoesNotExist()
    }

    @Test
    fun `calendar shows everything in a tall slot`() = runGlanceAppWidgetUnitTest {
        setAppWidgetSize(DpSize(250.dp, 250.dp))
        provideComposable { CalendarWidgetContent(calendarPrefs) }

        onNode(hasText("14")).assertExists()
        onNode(hasText("August 2026")).assertExists()
        onNode(hasText("Standup")).assertExists()
    }

    @Test
    fun `calendar renders at a zero-height slot`() = runGlanceAppWidgetUnitTest {
        setAppWidgetSize(DpSize(0.dp, 0.dp))
        provideComposable { CalendarWidgetContent(calendarPrefs) }
        onNode(hasText("Standup")).assertExists()
    }

    // List

    @Test
    fun `list keeps its items at the smallest slot`() = runGlanceAppWidgetUnitTest {
        setAppWidgetSize(DpSize(180.dp, 40.dp))
        provideComposable { ListWidgetContent(listPrefs) }

        onNode(hasText("Milk")).assertExists()
        onNode(hasText("Groceries")).assertDoesNotExist()
    }

    @Test
    fun `list drops per-item detail before it drops an item`() =
        runGlanceAppWidgetUnitTest {
            // A second line per item halves how many items fit, which costs the
            // reader half the list to gain a detail about the half that is left.
            setAppWidgetSize(DpSize(250.dp, 110.dp))
            provideComposable { ListWidgetContent(listPrefs) }

            onNode(hasText("Milk")).assertExists()
            onNode(hasText("Bread")).assertExists()
            onNode(hasText("2 litres")).assertDoesNotExist()
        }

    @Test
    fun `list shows everything in a tall slot`() = runGlanceAppWidgetUnitTest {
        setAppWidgetSize(DpSize(250.dp, 250.dp))
        provideComposable { ListWidgetContent(listPrefs) }

        onNode(hasText("Groceries")).assertExists()
        onNode(hasText("Milk")).assertExists()
        onNode(hasText("2 litres")).assertExists()
    }

    @Test
    fun `an empty list still says so at every size`() = runGlanceAppWidgetUnitTest {
        setAppWidgetSize(DpSize(180.dp, 40.dp))
        provideComposable {
            ListWidgetContent(
                mutablePreferencesOf(GlanceWidgetManager.titleKey to "Groceries")
            )
        }
        onNode(hasText("No items")).assertExists()
    }
}
