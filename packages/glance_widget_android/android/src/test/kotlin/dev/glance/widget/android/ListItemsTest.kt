package dev.glance.widget.android

import dev.glance.widget.android.templates.ListItem
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertNotNull
import org.junit.jupiter.api.Assertions.assertNull
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Test

/**
 * The list's items are a JSON string in the widget's own state, and a checkbox
 * tap has to read it, flip one entry and write it back -- inside an
 * `ActionCallback`, which runs in a process that may have no Flutter engine and
 * no way to report anything. Getting it wrong there is silent: the box springs
 * back on the next redraw.
 *
 * These pin the parsing, the flip and the round trip without a widget, which a
 * Glance Composable cannot be rendered in a JVM test.
 */
class ListItemsTest {

    private fun json(vararg entries: Pair<String, Boolean>): String =
        entries.joinToString(",", "[", "]") { (text, checked) ->
            """{"text":"$text","checked":$checked,"secondaryText":""}"""
        }

    // MARK: - Parsing

    @Test
    fun `an empty string is an empty list, not an item with no text`() {
        assertEquals(emptyList<ListItem>(), ListItems.parse(""))
        assertEquals(emptyList<ListItem>(), ListItems.parse(null))
    }

    @Test
    fun `the JSON the plugin writes is read back field for field`() {
        val items = ListItems.parse(
            """[{"text":"Milk","checked":true,"secondaryText":"2 litres"}]"""
        )

        assertEquals(1, items.size)
        assertEquals("Milk", items[0].text)
        assertTrue(items[0].checked)
        assertEquals("2 litres", items[0].secondaryText)
    }

    // An empty secondary line is not a secondary line. Keeping it as "" would
    // make the template lay out a blank row under every item.
    @Test
    fun `an empty secondary line is absent rather than blank`() {
        val items = ListItems.parse("""[{"text":"Milk","checked":false,"secondaryText":""}]""")

        assertNull(items[0].secondaryText)
    }

    @Test
    fun `a missing field takes its default`() {
        val items = ListItems.parse("""[{"text":"Milk"}]""")

        assertEquals("Milk", items[0].text)
        assertEquals(false, items[0].checked)
        assertNull(items[0].secondaryText)
    }

    // Widgets written by an older version of the plugin still hold this. They
    // are on someone's home screen right now and nothing rewrites them until
    // the app updates that widget.
    @Test
    fun `the legacy delimiter format is still read`() {
        val items = ListItems.parse("Milk::true::2 litres|||Eggs::false::")

        assertEquals(2, items.size)
        assertEquals("Milk", items[0].text)
        assertTrue(items[0].checked)
        assertEquals("2 litres", items[0].secondaryText)
        assertEquals("Eggs", items[1].text)
        assertNull(items[1].secondaryText)
    }

    // A draw that throws leaves the user looking at Android's "Problem loading
    // widget" box, which they cannot recover from without removing the widget.
    @Test
    fun `malformed JSON is reported and read as empty rather than thrown`() {
        var reported: Throwable? = null

        val items = ListItems.parse("[{not json") { reported = it }

        assertEquals(emptyList<ListItem>(), items)
        assertNotNull(reported)
    }

    // MARK: - Round trip

    @Test
    fun `items survive being written and read again`() {
        val original = listOf(
            ListItem("Milk", checked = true, secondaryText = "2 litres"),
            ListItem("Eggs", checked = false, secondaryText = null)
        )

        assertEquals(original, ListItems.parse(ListItems.serialize(original)))
    }

    @Test
    fun `text that would break a delimiter format survives`() {
        val original = listOf(ListItem("a|||b::c", checked = false, secondaryText = null))

        assertEquals(original, ListItems.parse(ListItems.serialize(original)))
    }

    // MARK: - Toggling

    @Test
    fun `an unchecked item becomes checked`() {
        val result = ListItems.toggling(json("Milk" to false, "Eggs" to false), 1)!!

        assertTrue(result.checked)
        assertEquals(listOf(false, true), ListItems.parse(result.items).map { it.checked })
    }

    @Test
    fun `a checked item becomes unchecked`() {
        val result = ListItems.toggling(json("Milk" to true), 0)!!

        assertEquals(false, result.checked)
        assertEquals(listOf(false), ListItems.parse(result.items).map { it.checked })
    }

    @Test
    fun `the other items are untouched`() {
        val result = ListItems.toggling(json("a" to true, "b" to false, "c" to true), 1)!!

        assertEquals(listOf(true, true, true), ListItems.parse(result.items).map { it.checked })
    }

    @Test
    fun `everything else about the item is kept`() {
        val result = ListItems.toggling(
            """[{"text":"Milk","checked":false,"secondaryText":"2 litres"}]""", 0
        )!!
        val item = ListItems.parse(result.items).single()

        assertEquals("Milk", item.text)
        assertEquals("2 litres", item.secondaryText)
    }

    // A widget on screen can be several updates behind its own state, so the
    // user taps row four of a list that now has two. Nothing should be written.
    @Test
    fun `an index past the end of the list changes nothing`() {
        val items = json("a" to false, "b" to false)

        assertNull(ListItems.toggling(items, 2))
        assertNull(ListItems.toggling(items, 5))
        assertNull(ListItems.toggling(items, -1))
    }

    @Test
    fun `there is nothing to toggle in an empty list`() {
        assertNull(ListItems.toggling("", 0))
        assertNull(ListItems.toggling(null, 0))
        assertNull(ListItems.toggling("[]", 0))
    }

    // A widget still holding the legacy format is one nothing has updated in a
    // long time. Toggling it rewrites it as JSON, which the template reads
    // first, so the tap is not lost just because the data is old.
    @Test
    fun `toggling a legacy list rewrites it in the current format`() {
        val result = ListItems.toggling("Milk::false::|||Eggs::false::", 0)!!

        assertTrue(result.items.startsWith("["), result.items)
        assertEquals(listOf(true, false), ListItems.parse(result.items).map { it.checked })
    }
}
