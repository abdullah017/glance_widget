package dev.glance.widget.android

import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertNull
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Test

/**
 * A Glance `ActionCallback` runs in the app's process, which the system starts
 * for the broadcast if it is not already up. That process has no Flutter engine
 * and no Dart listener, so an event sent from there went nowhere: ticking a
 * checkbox from the home screen while the app was closed did nothing at all,
 * silently. This queue is what carries it across.
 *
 * The interesting case is the payload's types, not the queueing.
 */
class ActionQueueTest {

    private fun action(
        widgetId: String = "todo",
        type: String = "checkboxToggle",
        payload: Map<String, String>? = null,
        timestamp: Long = 1_700_000_000_000
    ) = PendingAction(widgetId, type, payload, timestamp)

    // Ordering and capacity

    @Test
    fun `actions keep the order they were made in`() {
        var queue = emptyList<String>()
        repeat(5) { index -> queue = ActionQueue.appending(action(widgetId = "w$index"), queue) }

        assertEquals(
            listOf("w0", "w1", "w2", "w3", "w4"),
            ActionQueue.decode(queue).map { it.widgetId }
        )
    }

    // An app that is never opened again would otherwise grow this without limit
    // in storage the user cannot see or clear.
    @Test
    fun `the queue is capped, and it is the oldest that go`() {
        var queue = emptyList<String>()
        repeat(ActionQueue.CAPACITY + 10) { index ->
            queue = ActionQueue.appending(action(widgetId = "w$index"), queue)
        }
        val decoded = ActionQueue.decode(queue)

        assertEquals(ActionQueue.CAPACITY, queue.size)
        assertEquals("w10", decoded.first().widgetId)
        assertEquals("w${ActionQueue.CAPACITY + 9}", decoded.last().widgetId)
    }

    @Test
    fun `a queue exactly at capacity is not trimmed`() {
        var queue = emptyList<String>()
        repeat(ActionQueue.CAPACITY) { index ->
            queue = ActionQueue.appending(action(widgetId = "w$index"), queue)
        }

        assertEquals(ActionQueue.CAPACITY, queue.size)
        assertEquals("w0", ActionQueue.decode(queue).first().widgetId)
    }

    // Reading

    @Test
    fun `an action survives being stored and read back`() {
        val original = action(payload = mapOf("itemIndex" to "2", "value" to "true"))

        assertEquals(
            listOf(original),
            ActionQueue.decode(ActionQueue.read(ActionQueue.write(ActionQueue.appending(original, emptyList()))))
        )
    }

    @Test
    fun `an unreadable entry is skipped, not fatal`() {
        val queue = ActionQueue.appending(action(), emptyList()) +
            "not json" +
            ActionQueue.appending(action(widgetId = "other"), emptyList())

        val decoded = ActionQueue.decode(queue)

        assertEquals(listOf("todo", "other"), decoded.map { it.widgetId })
    }

    // Gson will happily decode `{}` into a PendingAction with null fields that
    // Kotlin's types say cannot be null, and the nulls only surface later, in
    // whatever touches them. An entry with no widget is not an action.
    @Test
    fun `an entry missing its widget or type is not an action`() {
        assertEquals(emptyList<PendingAction>(), ActionQueue.decode(listOf("{}")))
        assertEquals(
            emptyList<PendingAction>(),
            ActionQueue.decode(listOf("""{"widgetId":"a","timestamp":1}"""))
        )
    }

    @Test
    fun `nothing stored is an empty queue rather than an error`() {
        assertEquals(emptyList<String>(), ActionQueue.read(null))
        assertEquals(emptyList<String>(), ActionQueue.read(""))
        assertEquals(emptyList<String>(), ActionQueue.read("{not json"))
    }

    // Payload types -- the reason the payload is stored as strings at all

    /**
     * Gson has no type tag for a JSON number. A payload stored as
     * `Map<String, Any?>` comes back with `itemIndex` as `2.0`, a Double where
     * Dart's `GlanceWidgetAction` reads an int -- and it throws in the Dart
     * layer, a long way from here.
     */
    @Test
    fun `a queued index comes back an Int, not a Double`() {
        val event = ActionQueue.eventFor(action(payload = mapOf("itemIndex" to "2")))

        @Suppress("UNCHECKED_CAST")
        val payload = event["payload"] as Map<String, Any?>
        assertEquals(2, payload["itemIndex"])
        assertTrue(payload["itemIndex"] is Int)
    }

    @Test
    fun `a queued boolean comes back a Boolean`() {
        @Suppress("UNCHECKED_CAST")
        val payload = ActionQueue.eventFor(
            action(payload = mapOf("value" to "true", "other" to "false"))
        )["payload"] as Map<String, Any?>

        assertEquals(true, payload["value"])
        assertEquals(false, payload["other"])
    }

    @Test
    fun `a queued string stays a string`() {
        @Suppress("UNCHECKED_CAST")
        val payload = ActionQueue.eventFor(
            action(payload = mapOf("label" to "Milk"))
        )["payload"] as Map<String, Any?>

        assertEquals("Milk", payload["label"])
    }

    @Test
    fun `a negative index is still an index`() {
        @Suppress("UNCHECKED_CAST")
        val payload = ActionQueue.eventFor(
            action(payload = mapOf("itemIndex" to "-1"))
        )["payload"] as Map<String, Any?>

        assertEquals(-1, payload["itemIndex"])
    }

    // `sendActionEvent` omits the key entirely when there is nothing in it, and
    // Dart distinguishes an absent payload from an empty map.
    @Test
    fun `no payload and an empty payload both come through as nothing`() {
        assertNull(ActionQueue.eventFor(action(payload = null))["payload"])
        assertNull(ActionQueue.eventFor(action(payload = emptyMap()))["payload"])
        assertNull(ActionQueue.payloadOf(null))
        assertNull(ActionQueue.payloadOf(emptyMap()))
    }

    @Test
    fun `a live payload is stored as the strings that restore it`() {
        val stored = ActionQueue.payloadOf(mapOf("itemIndex" to 2, "value" to true))

        assertEquals(mapOf("itemIndex" to "2", "value" to "true"), stored)
    }

    /**
     * The point of the conversion: an action that went through the queue has to
     * reach Dart identical to one sent while the app was running.
     */
    @Test
    fun `a payload round trips through the queue unchanged`() {
        val live = mapOf<String, Any?>("itemIndex" to 3, "value" to false, "label" to "Milk")

        @Suppress("UNCHECKED_CAST")
        val restored = ActionQueue.eventFor(
            action(payload = ActionQueue.payloadOf(live))
        )["payload"] as Map<String, Any?>

        assertEquals(live, restored)
    }

    @Test
    fun `the event carries the time the interaction happened`() {
        assertEquals(
            1_700_000_000_000,
            ActionQueue.eventFor(action(timestamp = 1_700_000_000_000))["timestamp"]
        )
    }
}
