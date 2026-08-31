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
 * This was the worst of the seven templates at small sizes, and unlike
 * `SimpleWidget` it overflowed at a slot the launcher can reach through this
 * plugin's own `progress_widget_info.xml`:
 *
 * ```
 * progress_widget_info.xml:  minHeight="180dp"  minResizeHeight="110dp"
 * ```
 *
 * The circular layout was 16dp of padding either side plus an 80dp dial: 112dp
 * before a single character was drawn, against a 110dp floor. Adding the title,
 * two gaps and the subtitle brought it to roughly 166dp. What gets cut is the
 * bottom, and the dial -- with the percentage inside it -- is in the middle.
 *
 * These assert what is composed, not how many pixels it takes. The arithmetic
 * above is the argument that the old layout did not fit; these guard that the
 * new one drops the right things.
 */
@RunWith(RobolectricTestRunner::class)
class ProgressWidgetLayoutTest {

    private fun prefs(type: String) = mutablePreferencesOf(
        GlanceWidgetManager.titleKey to "Downloading",
        GlanceWidgetManager.progressKey to 0.42f,
        GlanceWidgetManager.subtitleKey to "3 of 7 files",
        GlanceWidgetManager.progressTypeKey to type
    )

    // The harness takes one size per test -- setAppWidgetSize has to precede
    // provideComposable and cannot be called again -- so the slots are separate
    // tests rather than a loop.

    @Test
    fun `the percentage survives the smallest slot`() = runGlanceAppWidgetUnitTest {
        setAppWidgetSize(DpSize(110.dp, 40.dp))
        provideComposable { ProgressWidgetContent(prefs("circular")) }
        onNode(hasText("42%")).assertExists()
    }

    @Test
    fun `the smallest slot shows the percentage alone`() = runGlanceAppWidgetUnitTest {
        setAppWidgetSize(DpSize(110.dp, 40.dp))
        provideComposable { ProgressWidgetContent(prefs("circular")) }

        onNode(hasText("42%")).assertExists()
        // Both are labels for a number that is already on screen.
        onNode(hasText("Downloading")).assertDoesNotExist()
        onNode(hasText("3 of 7 files")).assertDoesNotExist()
    }

    @Test
    fun `the percentage survives the slot the manifest allows`() =
        runGlanceAppWidgetUnitTest {
            // 110dp is minResizeHeight in progress_widget_info.xml -- the
            // smallest slot a launcher can hand this template today.
            setAppWidgetSize(DpSize(110.dp, 110.dp))
            provideComposable { ProgressWidgetContent(prefs("circular")) }

            onNode(hasText("42%")).assertExists()
            onNode(hasText("Downloading")).assertExists()
        }

    @Test
    fun `a tall slot shows everything`() = runGlanceAppWidgetUnitTest {
        setAppWidgetSize(DpSize(250.dp, 250.dp))
        provideComposable { ProgressWidgetContent(prefs("circular")) }

        onNode(hasText("Downloading")).assertExists()
        onNode(hasText("42%")).assertExists()
        onNode(hasText("3 of 7 files")).assertExists()
    }

    @Test
    fun `the linear bar keeps its title once there is room`() =
        runGlanceAppWidgetUnitTest {
            setAppWidgetSize(DpSize(180.dp, 110.dp))
            provideComposable { ProgressWidgetContent(prefs("linear")) }
            onNode(hasText("Downloading")).assertExists()
        }

    @Test
    fun `the linear bar drops its title at the smallest slot`() =
        runGlanceAppWidgetUnitTest {
            // The bar is the widget. A title with no bar under it reports
            // nothing at all, so the title is what goes.
            setAppWidgetSize(DpSize(110.dp, 40.dp))
            provideComposable { ProgressWidgetContent(prefs("linear")) }
            onNode(hasText("Downloading")).assertDoesNotExist()
        }

    @Test
    fun `a widget with no subtitle is not broken by the expanded layout`() =
        runGlanceAppWidgetUnitTest {
            setAppWidgetSize(DpSize(250.dp, 250.dp))
            provideComposable {
                ProgressWidgetContent(
                    mutablePreferencesOf(
                        GlanceWidgetManager.titleKey to "Downloading",
                        GlanceWidgetManager.progressKey to 0.42f,
                        GlanceWidgetManager.progressTypeKey to "circular"
                    )
                )
            }
            onNode(hasText("42%")).assertExists()
        }

    @Test
    fun `a zero-height slot still renders`() = runGlanceAppWidgetUnitTest {
        // LocalSize has been seen reporting zero during the first composition
        // after a resize. Compact fits everywhere, so it is the safe answer.
        setAppWidgetSize(DpSize(0.dp, 0.dp))
        provideComposable { ProgressWidgetContent(prefs("circular")) }
        onNode(hasText("42%")).assertExists()
    }
}
