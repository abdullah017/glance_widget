package dev.glance.widget.android

import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Test

/**
 * The scale exists so seven templates shrink the same way. Left to each
 * template these numbers drift, and two widgets sitting next to each other on
 * the same home screen end up disagreeing about what a title looks like.
 *
 * These assert the relationships rather than the literals: that text never
 * grows as the slot shrinks, that the value stays the largest thing on screen,
 * and that padding gets out of the way when there is none to spare. A literal
 * is a design decision and may change; a title larger than its own value is a
 * bug in any design.
 */
class WidgetTypeScaleTest {

    private val bands = listOf(
        WidgetSizeClass.COMPACT,
        WidgetSizeClass.MEDIUM,
        WidgetSizeClass.EXPANDED
    )

    @Test
    fun `nothing grows as the slot shrinks`() {
        for (i in 0 until bands.size - 1) {
            val smaller = bands[i]
            val larger = bands[i + 1]
            assertTrue(
                WidgetTypeScale.title(smaller).value <= WidgetTypeScale.title(larger).value,
                "title grew going from $larger down to $smaller"
            )
            assertTrue(
                WidgetTypeScale.value(smaller).value <= WidgetTypeScale.value(larger).value,
                "value grew going from $larger down to $smaller"
            )
            assertTrue(
                WidgetTypeScale.caption(smaller).value <= WidgetTypeScale.caption(larger).value,
                "caption grew going from $larger down to $smaller"
            )
        }
    }

    @Test
    fun `the value is the largest thing in every band`() {
        for (band in bands) {
            val value = WidgetTypeScale.value(band).value
            assertTrue(
                value > WidgetTypeScale.title(band).value,
                "$band: value $value is not larger than its title"
            )
            assertTrue(
                value > WidgetTypeScale.caption(band).value,
                "$band: value $value is not larger than its caption"
            )
        }
    }

    @Test
    fun `padding shrinks with the slot`() {
        assertTrue(
            WidgetTypeScale.padding(WidgetSizeClass.COMPACT).value <
                WidgetTypeScale.padding(WidgetSizeClass.MEDIUM).value,
            "compact padding should be tighter than medium"
        )
        assertEquals(
            WidgetTypeScale.padding(WidgetSizeClass.MEDIUM),
            WidgetTypeScale.padding(WidgetSizeClass.EXPANDED)
        )
    }

    @Test
    fun `every band is legible`() {
        // Below about 10sp text stops being readable at arm's length on a home
        // screen, which is the only distance a widget is ever read from.
        for (band in bands) {
            assertTrue(
                WidgetTypeScale.caption(band).value >= 10f,
                "$band caption is ${WidgetTypeScale.caption(band).value}sp"
            )
        }
    }

    @Test
    fun `compact leaves room by dropping to a single readable line`() {
        // The compact band is the one that used to overflow. Its whole budget
        // is roughly 40dp of slot minus padding, so the value has to fit in it.
        val compact = WidgetTypeScale.value(WidgetSizeClass.COMPACT).value
        val padding = WidgetTypeScale.padding(WidgetSizeClass.COMPACT).value
        assertTrue(
            compact * 1.3f + padding * 2 <= 40f,
            "compact value ${compact}sp plus ${padding}dp padding does not fit 40dp"
        )
    }
}
