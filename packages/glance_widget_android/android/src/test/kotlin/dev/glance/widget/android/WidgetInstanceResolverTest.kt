package dev.glance.widget.android

import dev.glance.widget.android.WidgetInstanceResolver.Instance
import dev.glance.widget.android.WidgetInstanceResolver.Resolution
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Test

/**
 * The package documents `id` as a "Unique identifier for this widget instance".
 * These tests hold [WidgetInstanceResolver] to that promise.
 */
class WidgetInstanceResolverTest {
    // JUnit's `assertTrue` carries no Kotlin contract, so narrowing has to be
    // done by the caller rather than inferred from an assertion.
    private fun targets(resolution: Resolution<String>): Resolution.Targets<String> {
        if (resolution !is Resolution.Targets) error("expected targets, got $resolution")
        return resolution
    }

    private fun targetsOf(resolution: Resolution<String>): List<String> = targets(resolution).handles

    private fun refusal(resolution: Resolution<String>): Resolution.NoTarget {
        if (resolution !is Resolution.NoTarget) error("expected refusal, got $resolution")
        return resolution
    }

    @Test
    fun `an update reaches only the instance carrying that id`() {
        // Two Simple widgets on the home screen, one showing BTC and one ETH.
        val placed = listOf(
            Instance("host-1", "btc"),
            Instance("host-2", "eth"),
        )

        assertEquals(listOf("host-1"), targetsOf(WidgetInstanceResolver.resolve(placed, "btc")))
        assertEquals(listOf("host-2"), targetsOf(WidgetInstanceResolver.resolve(placed, "eth")))
    }

    @Test
    fun `updating one id never writes into another id's instance`() {
        val placed = listOf(
            Instance("host-1", "btc"),
            Instance("host-2", "eth"),
        )

        val targets = targetsOf(WidgetInstanceResolver.resolve(placed, "btc"))

        assertTrue("host-2" !in targets, "the ETH widget must not be overwritten by a BTC update")
    }

    @Test
    fun `a freshly placed instance is claimed by the first update`() {
        val placed = listOf(Instance("host-1", null))

        val resolution = WidgetInstanceResolver.resolve(placed, "btc")

        assertEquals(listOf("host-1"), targetsOf(resolution))
        assertTrue(targets(resolution).adopted, "an unclaimed instance is adopted")
    }

    @Test
    fun `only one unclaimed instance is claimed per update`() {
        // Two fresh widgets, so `update(btc)` then `update(eth)` must fill one
        // each rather than painting both with the same data.
        val placed = listOf(
            Instance("host-1", null),
            Instance("host-2", null),
        )

        assertEquals(1, targetsOf(WidgetInstanceResolver.resolve(placed, "btc")).size)
    }

    @Test
    fun `several instances may deliberately share one id`() {
        // Placing the same widget twice is a supported thing for a user to do;
        // both copies should stay in sync.
        val placed = listOf(
            Instance("host-1", "btc"),
            Instance("host-2", "btc"),
            Instance("host-3", "eth"),
        )

        assertEquals(
            listOf("host-1", "host-2"),
            targetsOf(WidgetInstanceResolver.resolve(placed, "btc")),
        )
    }

    @Test
    fun `a second copy of a single-id app's widget is filled, not left blank`() {
        // Before routing existed every instance got every update, so placing the
        // same widget twice just worked. Claiming only one instance would have
        // regressed that into a permanently blank second copy.
        val placed = listOf(
            Instance("host-1", "main"),
            Instance("host-2", null),
        )

        assertEquals(
            listOf("host-1", "host-2"),
            targetsOf(WidgetInstanceResolver.resolve(placed, "main")),
        )
    }

    @Test
    fun `a blank instance is left alone while another id is in play`() {
        // With two ids on screen there is no way to tell which widget a blank
        // instance is meant to become, so guessing is refused.
        val placed = listOf(
            Instance("host-1", "btc"),
            Instance("host-2", "eth"),
            Instance("host-3", null),
        )

        assertEquals(listOf("host-1"), targetsOf(WidgetInstanceResolver.resolve(placed, "btc")))
    }

    @Test
    fun `a lone instance is re-keyed rather than left unreachable`() {
        // An app that changed its widget id between releases would otherwise
        // find its only widget permanently unreachable. With one instance there
        // is no ambiguity about which widget was meant.
        val placed = listOf(Instance("host-1", "old-id"))

        val resolution = WidgetInstanceResolver.resolve(placed, "new-id")

        assertEquals(listOf("host-1"), targetsOf(resolution))
        assertTrue(targets(resolution).adopted)
    }

    @Test
    fun `an id matching nothing among several instances is refused`() {
        // Guessing here is what let a BTC update erase an ETH widget.
        val placed = listOf(
            Instance("host-1", "btc"),
            Instance("host-2", "eth"),
        )

        val reason = refusal(WidgetInstanceResolver.resolve(placed, "doge")).reason

        assertTrue("btc" in reason, "the reason names the ids that do exist")
    }

    @Test
    fun `an empty home screen has no target`() {
        refusal(WidgetInstanceResolver.resolve(emptyList<Instance<String>>(), "btc"))
    }

    @Test
    fun `a blank stored id counts as unclaimed`() {
        val placed = listOf(Instance("host-1", ""))

        val resolution = WidgetInstanceResolver.resolve(placed, "btc")

        assertEquals(listOf("host-1"), targetsOf(resolution))
        assertTrue(targets(resolution).adopted)
    }
}
