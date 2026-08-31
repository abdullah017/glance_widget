package dev.glance.widget.android

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * The rule is one line, and the reason it is not simply "forget it" is the
 * second copy: `WidgetInstanceResolver` lets one id drive two placed widgets,
 * so removing one of them must leave the other's data alone.
 */
class WidgetRemovalPolicyTest {

    @Test
    fun `the last copy of an id takes its data with it`() {
        assertTrue(WidgetRemovalPolicy.shouldForget("btc", emptyList()))
    }

    @Test
    fun `a second copy keeps the data alive`() {
        // Both widgets render "btc". Deleting one leaves the other on screen,
        // and it still needs the payload and the image.
        assertFalse(WidgetRemovalPolicy.shouldForget("btc", listOf("btc")))
    }

    @Test
    fun `other ids do not keep an id alive`() {
        assertTrue(WidgetRemovalPolicy.shouldForget("btc", listOf("eth", "doge")))
    }

    @Test
    fun `an instance removed before its first update forgets nothing`() {
        // A widget dropped on the home screen and pulled off again before the
        // app ever wrote to it carries no id. Forgetting "" would be a no-op
        // at best and, if it ever matched a blank entry, a deletion of data
        // belonging to something else.
        assertFalse(WidgetRemovalPolicy.shouldForget(null, listOf("btc")))
        assertFalse(WidgetRemovalPolicy.shouldForget("", listOf("btc")))
        assertFalse(WidgetRemovalPolicy.shouldForget("   ", emptyList()))
    }

    @Test
    fun `unclaimed survivors do not keep an id alive`() {
        // A blank survivor is an instance that has never been written to. It
        // is not rendering the removed id, so it is not a reason to keep it.
        assertTrue(WidgetRemovalPolicy.shouldForget("btc", listOf(null, "", "  ")))
    }

    @Test
    fun `ids are matched exactly`() {
        // Not a prefix, not case-insensitively. "btc" and "BTC" are two
        // widgets, and so are "btc" and "btc2".
        assertTrue(WidgetRemovalPolicy.shouldForget("btc", listOf("BTC", "btc2", "abtc")))
    }
}
