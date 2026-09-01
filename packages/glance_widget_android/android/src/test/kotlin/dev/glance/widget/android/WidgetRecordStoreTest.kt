package dev.glance.widget.android

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import kotlinx.coroutines.runBlocking
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

/**
 * The record `getWidgetData` reads back.
 *
 * Nothing here parses the record into a widget: that mapping lives in Dart on
 * purpose, and writing it a second time in Kotlin is exactly the drift this
 * store exists to avoid. What Kotlin owns is that the payload goes in
 * untouched and comes out untouched, and that it dies with the widget id.
 *
 * See #37.
 */
@RunWith(RobolectricTestRunner::class)
class WidgetRecordStoreTest {

    private val context: Context get() = ApplicationProvider.getApplicationContext()

    private val gson = Gson()

    private fun parse(json: String): Map<String, Any?> =
        gson.fromJson(json, object : TypeToken<Map<String, Any?>>() {}.type)

    private val simpleData = mapOf<String, Any?>(
        "title" to "Bitcoin",
        "value" to "$64,120",
        "subtitle" to null,
        "subtitleColor" to 4283215696L,
        "deepLinkUri" to "myapp://coin/btc"
    )

    @Test
    fun `the record carries the id, the template and the time`() {
        val record = parse(
            WidgetRecordStore.encode("btc", "simple", simpleData, null, 1756000000000L)
        )

        assertEquals("btc", record["widgetId"])
        assertEquals("simple", record["template"])
        // Gson has no integer type, so this comes back as a Double here. Dart
        // reads it as `num`, which is what makes one parser serve both
        // platforms' JSON writers.
        assertEquals(1756000000000.0, record["updatedAt"] as Double, 0.0)
    }

    @Test
    fun `the payload is stored exactly as it arrived`() {
        val record = parse(
            WidgetRecordStore.encode("btc", "simple", simpleData, null, 1L)
        )

        @Suppress("UNCHECKED_CAST")
        val data = record["data"] as Map<String, Any?>
        assertEquals("Bitcoin", data["title"])
        assertEquals("$64,120", data["value"])
        assertEquals("myapp://coin/btc", data["deepLinkUri"])
        // A colour crosses as a packed ARGB integer and has to survive as one:
        // 4283215696 is 0xFF4CAF50, which does not fit in a signed 32-bit int.
        assertEquals(4283215696.0, data["subtitleColor"] as Double, 0.0)
    }

    @Test
    fun `nested lists survive`() {
        val record = parse(
            WidgetRecordStore.encode(
                "shopping",
                "list",
                mapOf(
                    "title" to "Groceries",
                    "items" to listOf(
                        mapOf("text" to "Milk", "checked" to true),
                        mapOf("text" to "Bread", "checked" to false)
                    ),
                    "maxItems" to 5L
                ),
                null,
                1L
            )
        )

        @Suppress("UNCHECKED_CAST")
        val items = (record["data"] as Map<String, Any?>)["items"] as List<Map<String, Any?>>
        assertEquals(2, items.size)
        assertEquals("Milk", items[0]["text"])
        assertEquals(true, items[0]["checked"])
    }

    @Test
    fun `a theme is kept when one was sent and absent when it was not`() {
        val withTheme = parse(
            WidgetRecordStore.encode(
                "btc", "simple", simpleData,
                mapOf("backgroundColor" to 4278190080L, "isDark" to true),
                1L
            )
        )
        @Suppress("UNCHECKED_CAST")
        val theme = withTheme["theme"] as Map<String, Any?>
        assertEquals(true, theme["isDark"])

        assertNull(parse(WidgetRecordStore.encode("btc", "simple", simpleData, null, 1L))["theme"])
    }

    @Test
    fun `what was saved is what is read`() {
        WidgetRecordStore.save(context, "btc", "simple", simpleData, null, 42L)

        val stored = WidgetRecordStore.read(context, "btc")
        assertEquals(WidgetRecordStore.encode("btc", "simple", simpleData, null, 42L), stored)
    }

    @Test
    fun `an id that was never written has no record`() {
        assertNull(WidgetRecordStore.read(context, "never-written"))
    }

    @Test
    fun `one widget's record is not another's`() {
        WidgetRecordStore.save(context, "btc", "simple", simpleData, null, 1L)
        WidgetRecordStore.save(
            context, "eth", "simple", simpleData + ("title" to "Ethereum"), null, 1L
        )

        val btc = WidgetRecordStore.read(context, "btc") ?: error("btc has no record")
        assertTrue(btc.contains("Bitcoin"))
        assertTrue(WidgetRecordStore.read(context, "eth")?.contains("Ethereum") == true)
    }

    @Test
    fun `deleting drops the record`() {
        WidgetRecordStore.save(context, "btc", "simple", simpleData, null, 1L)
        WidgetRecordStore.delete(context, "btc")

        assertNull(WidgetRecordStore.read(context, "btc"))
    }

    @Test
    fun `an update that reaches no widget records nothing`() {
        // Android differs from iOS here, and the difference is worth pinning
        // rather than discovering. An update stops at the instance lookup when
        // no widget carrying the id is on the home screen, so there is nothing
        // showing and nothing to read back. iOS writes to the App Group whether
        // or not a widget was ever placed, because WidgetKit gives an extension
        // no way to ask.
        val outcome = runBlocking {
            GlanceWidgetManager.updateSimpleWidgetWithResult(
                context, "never-placed", mapOf("title" to "T", "value" to "V"), null
            )
        }

        assertTrue(outcome.isError)
        assertNull(WidgetRecordStore.read(context, "never-placed"))
    }

    @Test
    fun `forgetting a widget drops its record`() {
        // The record and the tracked id have to die together: the removal path
        // from #13 goes through forgetWidget, and a record that outlived it
        // would keep answering for a widget the user dragged off the screen.
        WidgetRecordStore.save(context, "btc", "simple", simpleData, null, 1L)

        GlanceWidgetManager.forgetWidget(context, "btc")

        assertNull(WidgetRecordStore.read(context, "btc"))
    }
}
