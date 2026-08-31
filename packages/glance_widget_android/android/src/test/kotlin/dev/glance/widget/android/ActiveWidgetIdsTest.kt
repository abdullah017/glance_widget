package dev.glance.widget.android

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import org.junit.Assert.assertEquals
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

/**
 * What `getActiveWidgetIds()` answers, and in what order.
 *
 * The set behind it is a `mutableSetOf`, and it used to be returned with
 * `toList()`. A `LinkedHashSet` iterates in insertion order, so the order was
 * whatever sequence of updates the app happened to make -- reproducible in a
 * test, arbitrary to a caller, and different again after a reload from
 * SharedPreferences. See #13.
 */
@RunWith(RobolectricTestRunner::class)
class ActiveWidgetIdsTest {

    private val context: Context get() = ApplicationProvider.getApplicationContext()

    @Before
    fun seedStore() {
        // Written in an order no sort would produce by accident.
        context.getSharedPreferences("glance_widget_prefs", Context.MODE_PRIVATE)
            .edit()
            .putString("active_widget_ids", """["steps","btc","aapl","eth"]""")
            .commit()
        GlanceWidgetManager.initialize(context, null)
    }

    @Test
    fun `ids come back in ascending order`() {
        assertEquals(
            listOf("aapl", "btc", "eth", "steps"),
            GlanceWidgetManager.getActiveWidgetIds(context)
        )
    }

    @Test
    fun `the order does not depend on the order they were stored in`() {
        context.getSharedPreferences("glance_widget_prefs", Context.MODE_PRIVATE)
            .edit()
            .putString("active_widget_ids", """["eth","aapl","steps","btc"]""")
            .commit()
        GlanceWidgetManager.initialize(context, null)

        assertEquals(
            listOf("aapl", "btc", "eth", "steps"),
            GlanceWidgetManager.getActiveWidgetIds(context)
        )
    }

    @Test
    fun `removing an id drops it from the list`() {
        // The method existed with no callers until #13 wired it to onDelete.
        GlanceWidgetManager.removeWidgetId(context, "btc")

        assertEquals(
            listOf("aapl", "eth", "steps"),
            GlanceWidgetManager.getActiveWidgetIds(context)
        )
    }

    @Test
    fun `removing an id that is not tracked changes nothing`() {
        GlanceWidgetManager.removeWidgetId(context, "never-seen")

        assertEquals(
            listOf("aapl", "btc", "eth", "steps"),
            GlanceWidgetManager.getActiveWidgetIds(context)
        )
    }

    @Test
    fun `an empty store answers with an empty list`() {
        context.getSharedPreferences("glance_widget_prefs", Context.MODE_PRIVATE)
            .edit()
            .putString("active_widget_ids", "[]")
            .commit()
        GlanceWidgetManager.initialize(context, null)

        assertEquals(emptyList<String>(), GlanceWidgetManager.getActiveWidgetIds(context))
    }
}
