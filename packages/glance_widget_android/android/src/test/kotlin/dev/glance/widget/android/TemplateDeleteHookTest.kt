package dev.glance.widget.android

import android.content.Context
import androidx.glance.GlanceId
import androidx.glance.appwidget.GlanceAppWidget
import dev.glance.widget.android.templates.CalendarGlanceWidget
import dev.glance.widget.android.templates.ChartGlanceWidget
import dev.glance.widget.android.templates.GaugeGlanceWidget
import dev.glance.widget.android.templates.ImageGlanceWidget
import dev.glance.widget.android.templates.ListGlanceWidget
import dev.glance.widget.android.templates.ProgressGlanceWidget
import dev.glance.widget.android.templates.SimpleGlanceWidget
import kotlin.coroutines.Continuation
import org.junit.Assert.assertNotNull
import org.junit.Test

/**
 * That every template is actually wired to the cleanup.
 *
 * `GlanceAppWidget.onDelete` has a no-op default, so a template that does not
 * override it compiles, installs, runs, and quietly leaves its image and its id
 * behind forever -- which is exactly what all seven did before #13. Nothing
 * fails; there is only a file on disk that nothing will look for again.
 *
 * The behaviour itself needs a host to observe, so what is checked here is the
 * wiring: each template declares its own `onDelete`. An eighth template added
 * without one fails this test rather than shipping the leak.
 */
class TemplateDeleteHookTest {

    private val templates: List<GlanceAppWidget> = listOf(
        SimpleGlanceWidget(),
        ProgressGlanceWidget(),
        ListGlanceWidget(),
        CalendarGlanceWidget(),
        ImageGlanceWidget(),
        ChartGlanceWidget(),
        GaugeGlanceWidget()
    )

    @Test
    fun `every template overrides onDelete`() {
        templates.forEach { template ->
            // getDeclaredMethod, not getMethod: the inherited default would
            // satisfy the latter and prove nothing.
            val declared = template::class.java.getDeclaredMethod(
                "onDelete",
                Context::class.java,
                GlanceId::class.java,
                Continuation::class.java
            )
            assertNotNull(template::class.java.simpleName, declared)
        }
    }

    @Test
    fun `every template is one WidgetRemoval knows about`() {
        // WidgetRemoval asks each template class which instances are still
        // placed. A template missing from that list is one whose widgets do
        // not count as survivors, so removing a copy of an id it renders would
        // delete data still on the screen.
        val known = WidgetRemoval.templateClassesForTest.toSet()

        templates.forEach { template ->
            assert(known.contains(template::class.java)) {
                "${template::class.java.simpleName} is not in WidgetRemoval.templateClasses"
            }
        }
    }
}
