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
 * The user can drag a widget to a slot far smaller than the one it was designed
 * for -- `simple_widget_info.xml` declares `minResizeHeight="40dp"` against a
 * `minHeight` of 110dp. The template used to paint the same thing into both: a
 * 14sp title, an 8dp spacer, a 28sp value, and 32dp of padding, which is around
 * 90dp of content in a 40dp slot. What gets cut is the bottom, which is where
 * the value is.
 *
 * These assert what is composed, not how many pixels it takes. The arithmetic
 * above is the argument that the old layout did not fit; these are the guard
 * that the new one drops the right things.
 */
@RunWith(RobolectricTestRunner::class)
class SimpleWidgetLayoutTest {

    private val prefs = mutablePreferencesOf(
        GlanceWidgetManager.titleKey to "BTC",
        GlanceWidgetManager.valueKey to "64120",
        GlanceWidgetManager.subtitleKey to "+2.4%"
    )

    // The harness takes one size per test -- setAppWidgetSize has to precede
    // provideComposable and cannot be called again -- so the slots are three
    // tests rather than a loop.

    @Test
    fun `the value survives the smallest slot`() = runGlanceAppWidgetUnitTest {
        setAppWidgetSize(DpSize(110.dp, 40.dp))
        provideComposable { SimpleWidgetContent(prefs) }
        onNode(hasText("64120")).assertExists()
    }

    @Test
    fun `the value survives the default slot`() = runGlanceAppWidgetUnitTest {
        setAppWidgetSize(DpSize(180.dp, 110.dp))
        provideComposable { SimpleWidgetContent(prefs) }
        onNode(hasText("64120")).assertExists()
    }

    @Test
    fun `the value survives a tall slot`() = runGlanceAppWidgetUnitTest {
        setAppWidgetSize(DpSize(250.dp, 250.dp))
        provideComposable { SimpleWidgetContent(prefs) }
        onNode(hasText("64120")).assertExists()
    }

    @Test
    fun `the smallest slot shows the value alone`() = runGlanceAppWidgetUnitTest {
        setAppWidgetSize(DpSize(110.dp, 40.dp))
        provideComposable { SimpleWidgetContent(prefs) }

        onNode(hasText("64120")).assertExists()
        // The title and the subtitle are what get dropped, in that order,
        // because neither is the number the user put the widget there to read.
        onNode(hasText("BTC")).assertDoesNotExist()
        onNode(hasText("+2.4%")).assertDoesNotExist()
    }

    @Test
    fun `the default slot shows the title and the value`() = runGlanceAppWidgetUnitTest {
        setAppWidgetSize(DpSize(180.dp, 110.dp))
        provideComposable { SimpleWidgetContent(prefs) }

        onNode(hasText("BTC")).assertExists()
        onNode(hasText("64120")).assertExists()
    }

    @Test
    fun `a tall slot shows everything`() = runGlanceAppWidgetUnitTest {
        setAppWidgetSize(DpSize(250.dp, 250.dp))
        provideComposable { SimpleWidgetContent(prefs) }

        onNode(hasText("BTC")).assertExists()
        onNode(hasText("64120")).assertExists()
        onNode(hasText("+2.4%")).assertExists()
    }

    @Test
    fun `a widget with no subtitle is not broken by the expanded layout`() =
        runGlanceAppWidgetUnitTest {
            setAppWidgetSize(DpSize(250.dp, 250.dp))
            provideComposable {
                SimpleWidgetContent(
                    mutablePreferencesOf(
                        GlanceWidgetManager.titleKey to "BTC",
                        GlanceWidgetManager.valueKey to "64120"
                    )
                )
            }

            onNode(hasText("64120")).assertExists()
        }
}
