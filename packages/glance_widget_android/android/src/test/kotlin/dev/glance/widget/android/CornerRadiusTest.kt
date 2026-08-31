package dev.glance.widget.android

import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Test

/**
 * `GlanceTheme.borderRadius` did nothing on Android: three templates read it
 * into an unused local and four ignored it entirely (#20). These pin what the
 * templates now round by, including the values that reach a widget only because
 * the theme crosses a method channel as untyped numbers.
 */
class CornerRadiusTest {

    @Test
    fun `an unset radius falls back to the theme default`() {
        assertEquals(16f, CornerRadius.dpFor(null))
    }

    @Test
    fun `a configured radius is used as given`() {
        assertEquals(24f, CornerRadius.dpFor(24f))
    }

    // The old code was `prefs[borderRadiusKey]?.toInt() ?: 16`, so a 12.5dp
    // radius became 12dp before it was thrown away. Dart sends a double and
    // Glance takes a Float; the Int in the middle was never needed.
    @Test
    fun `a fractional radius keeps its fraction`() {
        assertEquals(12.5f, CornerRadius.dpFor(12.5f))
    }

    @Test
    fun `square corners are a legitimate choice`() {
        assertEquals(0f, CornerRadius.dpFor(0f))
    }

    // A negative radius is not a smaller corner; it is one Glance cannot lay
    // out. Square is the nearest thing the caller can have meant.
    @Test
    fun `a negative radius is squared off rather than passed on`() {
        assertEquals(0f, CornerRadius.dpFor(-8f))
    }

    @Test
    fun `a non-finite radius falls back to the default`() {
        assertEquals(16f, CornerRadius.dpFor(Float.NaN))
        assertEquals(16f, CornerRadius.dpFor(Float.POSITIVE_INFINITY))
        assertEquals(16f, CornerRadius.dpFor(Float.NEGATIVE_INFINITY))
    }

    // Larger than the widget is not an error: Android clips it to a pill, which
    // is what a caller asking for a very round widget wants.
    @Test
    fun `a very large radius is left alone`() {
        assertEquals(999f, CornerRadius.dpFor(999f))
    }
}
