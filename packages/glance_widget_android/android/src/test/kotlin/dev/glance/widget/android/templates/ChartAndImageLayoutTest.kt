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
 * Chart and Image share a shape the other templates do not: their content is a
 * picture that takes whatever is left after the text, rather than text that
 * takes what it needs. Every line drawn above or below is subtracted from the
 * thing the widget exists to show.
 *
 * At the 110dp slot both manifests allow:
 *
 * - Chart: 32dp padding + 29dp header + 26dp subtitle left the plot 23dp.
 * - Image: 32dp padding + 29dp title + 44dp two-line caption left it 5dp.
 *
 * Neither drew a wrong pixel; they just left almost nothing to draw in. These
 * assert what is composed, not how many pixels it takes.
 */
@RunWith(RobolectricTestRunner::class)
class ChartAndImageLayoutTest {

    private val chartPrefs = mutablePreferencesOf(
        GlanceWidgetManager.titleKey to "Revenue",
        GlanceWidgetManager.chartTypeKey to "bar",
        GlanceWidgetManager.subtitleKey to "Last 7 days"
    )

    private val imagePrefs = mutablePreferencesOf(
        GlanceWidgetManager.titleKey to "Cover",
        GlanceWidgetManager.subtitleKey to "Shot on a rainy afternoon"
    )

    // Chart

    @Test
    fun `chart keeps the plot at the smallest slot`() = runGlanceAppWidgetUnitTest {
        setAppWidgetSize(DpSize(110.dp, 40.dp))
        provideComposable { ChartWidgetContent(chartPrefs) }
        // No bitmap was supplied, so the plot area is the placeholder -- which
        // is the point: it is still there, and it is what has the room.
        onNode(hasText("No chart data")).assertExists()
        onNode(hasText("Revenue")).assertDoesNotExist()
        onNode(hasText("Last 7 days")).assertDoesNotExist()
    }

    @Test
    fun `chart shows its title once there is room`() = runGlanceAppWidgetUnitTest {
        setAppWidgetSize(DpSize(180.dp, 110.dp))
        provideComposable { ChartWidgetContent(chartPrefs) }
        onNode(hasText("Revenue")).assertExists()
        // The chart type labels a picture that is about to be drawn anyway, and
        // says least of anything on screen, so it waits for the expanded slot.
        onNode(hasText("Bar")).assertDoesNotExist()
    }

    @Test
    fun `chart shows everything in a tall slot`() = runGlanceAppWidgetUnitTest {
        setAppWidgetSize(DpSize(250.dp, 250.dp))
        provideComposable { ChartWidgetContent(chartPrefs) }
        onNode(hasText("Revenue")).assertExists()
        onNode(hasText("Bar")).assertExists()
        onNode(hasText("Last 7 days")).assertExists()
    }

    @Test
    fun `chart renders at a zero-height slot`() = runGlanceAppWidgetUnitTest {
        setAppWidgetSize(DpSize(0.dp, 0.dp))
        provideComposable { ChartWidgetContent(chartPrefs) }
        onNode(hasText("No chart data")).assertExists()
    }

    // Image

    @Test
    fun `image keeps the picture at the smallest slot`() = runGlanceAppWidgetUnitTest {
        setAppWidgetSize(DpSize(110.dp, 40.dp))
        provideComposable { ImageWidgetContent(imagePrefs) }
        onNode(hasText("No image")).assertExists()
        onNode(hasText("Cover")).assertDoesNotExist()
        onNode(hasText("Shot on a rainy afternoon")).assertDoesNotExist()
    }

    @Test
    fun `image shows title and caption once there is room`() =
        runGlanceAppWidgetUnitTest {
            setAppWidgetSize(DpSize(180.dp, 110.dp))
            provideComposable { ImageWidgetContent(imagePrefs) }
            onNode(hasText("Cover")).assertExists()
            onNode(hasText("Shot on a rainy afternoon")).assertExists()
        }

    @Test
    fun `image renders at a zero-height slot`() = runGlanceAppWidgetUnitTest {
        setAppWidgetSize(DpSize(0.dp, 0.dp))
        provideComposable { ImageWidgetContent(imagePrefs) }
        onNode(hasText("No image")).assertExists()
    }

    @Test
    fun `an untitled image is not broken by any slot`() = runGlanceAppWidgetUnitTest {
        setAppWidgetSize(DpSize(250.dp, 250.dp))
        provideComposable { ImageWidgetContent(mutablePreferencesOf()) }
        onNode(hasText("No image")).assertExists()
    }
}
