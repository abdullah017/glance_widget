package dev.glance.widget.android

import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Test

/**
 * Android lets the user resize a widget far below the size it was designed
 * against. `simple_widget_info.xml` declares `minHeight="110dp"` but also
 * `minResizeHeight="40dp"` with `resizeMode="horizontal|vertical"`, so the slot
 * the template actually has to paint into can be a third of the one it was
 * drawn for. Every template used to render one fixed layout regardless -- a
 * 14sp title, an 8dp spacer, a 28sp value and 32dp of padding, which is roughly
 * 90dp of content, into 40dp of slot. iOS branched on size in every template;
 * Android branched in none.
 */
class WidgetSizeClassTest {

    @Test
    fun `the smallest slot a user can drag to is compact`() {
        // minResizeWidth x minResizeHeight from simple_widget_info.xml.
        assertEquals(WidgetSizeClass.COMPACT, WidgetSizeClass.of(heightDp = 40f))
    }

    @Test
    fun `the declared default slot is medium`() {
        // minWidth x minHeight from the same file -- what the user gets on drop.
        assertEquals(WidgetSizeClass.MEDIUM, WidgetSizeClass.of(heightDp = 110f))
    }

    @Test
    fun `a tall slot is expanded`() {
        assertEquals(WidgetSizeClass.EXPANDED, WidgetSizeClass.of(heightDp = 250f))
    }

    @Test
    fun `height decides, because that is what runs out first`() {
        // A wide, short slot has room for more text across but no room for
        // another line. Classifying it by width would put a 28sp value and a
        // subtitle into 48dp.
        assertEquals(WidgetSizeClass.COMPACT, WidgetSizeClass.of(heightDp = 48f))
    }

    @Test
    fun `width does not decide, only height`() {
        // A 90dp-wide slot is narrower than any template's minResizeWidth, and
        // it still gets the expanded layout, because the constraint that breaks
        // a widget is vertical. Guards against width creeping into the rule.
        assertEquals(WidgetSizeClass.EXPANDED, WidgetSizeClass.of(heightDp = 260f))
    }

    @Test
    fun `the boundaries are exact`() {
        assertEquals(WidgetSizeClass.COMPACT, WidgetSizeClass.of(heightDp = 79.9f))
        assertEquals(WidgetSizeClass.MEDIUM, WidgetSizeClass.of(heightDp = 80f))
        assertEquals(WidgetSizeClass.MEDIUM, WidgetSizeClass.of(heightDp = 179.9f))
        assertEquals(WidgetSizeClass.EXPANDED, WidgetSizeClass.of(heightDp = 180f))
    }

    @Test
    fun `a nonsense size does not crash the widget`() {
        // LocalSize has been observed as zero on some launchers during the
        // first composition after a resize. Painting the compact layout for one
        // frame is survivable; throwing is not.
        assertEquals(WidgetSizeClass.COMPACT, WidgetSizeClass.of(heightDp = 0f))
        assertEquals(WidgetSizeClass.COMPACT, WidgetSizeClass.of(heightDp = -1f))
        assertEquals(WidgetSizeClass.COMPACT, WidgetSizeClass.of(heightDp = Float.NaN))
    }
}
