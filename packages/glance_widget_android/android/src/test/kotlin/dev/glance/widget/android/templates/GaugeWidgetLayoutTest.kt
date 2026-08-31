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
 * The dashboard gauge drew every metric row whatever height it had. A row is
 * around 76dp, so six metrics is 228dp of grid against the 110dp
 * `minResizeHeight` that `gauge_widget_info.xml` allows -- everything below the
 * first row was cut off the bottom, with nothing on screen to say it existed.
 *
 * Drawing fewer rows is not less information than drawing some of them
 * invisibly. It is the same information, minus the false impression that the
 * rest is not there.
 *
 * These assert what is composed, not how many pixels it takes.
 */
@RunWith(RobolectricTestRunner::class)
class GaugeWidgetLayoutTest {

    private val sixMetrics = """
        [
          {"label":"CPU","value":"41%","progress":0.41},
          {"label":"Memory","value":"6.2GB","progress":0.62},
          {"label":"Disk","value":"88%","progress":0.88},
          {"label":"Network","value":"12MB/s"},
          {"label":"Battery","value":"73%","progress":0.73},
          {"label":"Uptime","value":"9d"}
        ]
    """.trimIndent()

    private val prefs = mutablePreferencesOf(
        GlanceWidgetManager.titleKey to "System",
        GlanceWidgetManager.gaugeTypeKey to "dashboard",
        GlanceWidgetManager.metricsKey to sixMetrics
    )

    @Test
    fun `a tall slot shows every metric`() = runGlanceAppWidgetUnitTest {
        setAppWidgetSize(DpSize(250.dp, 250.dp))
        provideComposable { GaugeWidgetContent(prefs) }

        onNode(hasText("CPU")).assertExists()
        onNode(hasText("Uptime")).assertExists()
        onNode(hasText("System")).assertExists()
    }

    @Test
    fun `the default slot shows two rows and stops`() = runGlanceAppWidgetUnitTest {
        setAppWidgetSize(DpSize(180.dp, 110.dp))
        provideComposable { GaugeWidgetContent(prefs) }

        // Rows one and two.
        onNode(hasText("CPU")).assertExists()
        onNode(hasText("Disk")).assertExists()
        // Row three would not have been visible anyway.
        onNode(hasText("Battery")).assertDoesNotExist()
        onNode(hasText("Uptime")).assertDoesNotExist()
    }

    @Test
    fun `the smallest slot shows one row and no title`() = runGlanceAppWidgetUnitTest {
        setAppWidgetSize(DpSize(110.dp, 40.dp))
        provideComposable { GaugeWidgetContent(prefs) }

        onNode(hasText("CPU")).assertExists()
        onNode(hasText("41%")).assertExists()
        onNode(hasText("Disk")).assertDoesNotExist()
        onNode(hasText("System")).assertDoesNotExist()
    }

    @Test
    fun `metric labels survive every size`() = runGlanceAppWidgetUnitTest {
        // Unlike a widget title, a metric label is not a restatement of what is
        // under it. With several readings on screen an unlabelled number does
        // not say which reading it is, so the label is never what gets dropped.
        setAppWidgetSize(DpSize(110.dp, 40.dp))
        provideComposable { GaugeWidgetContent(prefs) }
        onNode(hasText("CPU")).assertExists()
    }

    @Test
    fun `a single metric is not broken by the compact layout`() =
        runGlanceAppWidgetUnitTest {
            setAppWidgetSize(DpSize(110.dp, 40.dp))
            provideComposable {
                GaugeWidgetContent(
                    mutablePreferencesOf(
                        GlanceWidgetManager.gaugeTypeKey to "dashboard",
                        GlanceWidgetManager.metricsKey to
                            """[{"label":"CPU","value":"41%"}]"""
                    )
                )
            }
            onNode(hasText("41%")).assertExists()
        }

    @Test
    fun `a zero-height slot still renders`() = runGlanceAppWidgetUnitTest {
        setAppWidgetSize(DpSize(0.dp, 0.dp))
        provideComposable { GaugeWidgetContent(prefs) }
        onNode(hasText("41%")).assertExists()
    }
}
