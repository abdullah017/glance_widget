package dev.glance.widget.android

import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertNull
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Test

/**
 * The Dart side writes this payload and this object reads it. Both sides pin
 * the same key names, because a rename that lands on only one of them fails
 * silently -- the native side simply reads null forever.
 */
class BatchRequestTest {

    private fun ok(parsed: BatchParse): BatchParse.Ok {
        if (parsed !is BatchParse.Ok) error("expected a parsed batch, got $parsed")
        return parsed
    }

    private fun invalid(parsed: BatchParse): BatchParse.Invalid {
        if (parsed !is BatchParse.Invalid) error("expected a rejection, got $parsed")
        return parsed
    }

    private fun update(
        widgetId: String,
        template: String = "simple",
        data: Map<String, Any?> = mapOf("title" to "T", "value" to "1"),
        theme: Map<String, Any?>? = null
    ): Map<String, Any?> = buildMap {
        put("widgetId", widgetId)
        put("template", template)
        put("data", data)
        if (theme != null) put("theme", theme)
    }

    private val darkTheme = mapOf<String, Any?>("isDark" to true)
    private val lightTheme = mapOf<String, Any?>("isDark" to false)

    @Test
    fun `reads the updates in the order they were sent`() {
        val parsed = ok(
            BatchRequest.parse(
                mapOf(
                    "theme" to null,
                    "updates" to listOf(update("a"), update("b"), update("c"))
                )
            )
        )

        assertEquals(listOf("a", "b", "c"), parsed.entries.map { it.widgetId })
    }

    @Test
    fun `the batch theme applies to every widget that has none of its own`() {
        val parsed = ok(
            BatchRequest.parse(
                mapOf("theme" to darkTheme, "updates" to listOf(update("a"), update("b")))
            )
        )

        assertEquals(listOf(darkTheme, darkTheme), parsed.entries.map { it.theme })
    }

    @Test
    fun `a widget's own theme wins over the batch theme`() {
        val parsed = ok(
            BatchRequest.parse(
                mapOf(
                    "theme" to darkTheme,
                    "updates" to listOf(update("a"), update("b", theme = lightTheme))
                )
            )
        )

        assertEquals(darkTheme, parsed.entries[0].theme)
        assertEquals(lightTheme, parsed.entries[1].theme)
    }

    @Test
    fun `no theme anywhere leaves the widget without one`() {
        val parsed = ok(BatchRequest.parse(mapOf("updates" to listOf(update("a")))))

        assertNull(parsed.entries.single().theme)
    }

    @Test
    fun `the template travels with each entry so a batch can mix them`() {
        val parsed = ok(
            BatchRequest.parse(
                mapOf(
                    "updates" to listOf(
                        update("a", template = "simple"),
                        update("b", template = "chart"),
                        update("c", template = "gauge")
                    )
                )
            )
        )

        assertEquals(listOf("simple", "chart", "gauge"), parsed.entries.map { it.template })
    }

    @Test
    fun `an empty updates list parses to an empty batch rather than an error`() {
        val parsed = ok(BatchRequest.parse(mapOf("updates" to emptyList<Any?>())))

        assertTrue(parsed.entries.isEmpty())
    }

    // The same widget twice would race: whichever landed last would win, and
    // the caller would have no way to know which. Dart refuses it too, so this
    // only fires for a caller that reached the channel some other way.
    @Test
    fun `the same widgetId twice is refused`() {
        val reason = invalid(
            BatchRequest.parse(mapOf("updates" to listOf(update("same"), update("same"))))
        ).reason

        assertTrue(reason.contains("same"), reason)
        assertTrue(reason.contains("more than once"), reason)
    }

    @Test
    fun `an empty widgetId is refused`() {
        val reason = invalid(
            BatchRequest.parse(mapOf("updates" to listOf(update(""))))
        ).reason

        assertTrue(reason.contains("empty widgetId"), reason)
    }

    @Test
    fun `an entry with no template is refused`() {
        val entry = mapOf<String, Any?>("widgetId" to "a", "data" to mapOf("title" to "T"))

        val reason = invalid(BatchRequest.parse(mapOf("updates" to listOf(entry)))).reason

        assertTrue(reason.contains("no template"), reason)
    }

    @Test
    fun `an entry with no data is refused`() {
        val entry = mapOf<String, Any?>("widgetId" to "a", "template" to "simple")

        val reason = invalid(BatchRequest.parse(mapOf("updates" to listOf(entry)))).reason

        assertTrue(reason.contains("no data"), reason)
    }

    @Test
    fun `arguments that are not a map at all are refused`() {
        assertTrue(BatchRequest.parse("nonsense") is BatchParse.Invalid)
        assertTrue(BatchRequest.parse(null) is BatchParse.Invalid)
    }

    @Test
    fun `a missing updates key is refused`() {
        val reason = invalid(BatchRequest.parse(mapOf("theme" to darkTheme))).reason

        assertTrue(reason.contains("updates"), reason)
    }

    @Test
    fun `updates that is not a list is refused`() {
        val reason = invalid(BatchRequest.parse(mapOf("updates" to "one"))).reason

        assertTrue(reason.contains("must be a list"), reason)
    }

    @Test
    fun `the offending index is named so the caller can find it`() {
        val reason = invalid(
            BatchRequest.parse(mapOf("updates" to listOf(update("a"), "not a map")))
        ).reason

        assertTrue(reason.contains("updates[1]"), reason)
    }
}
