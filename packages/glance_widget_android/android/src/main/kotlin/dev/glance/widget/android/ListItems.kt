package dev.glance.widget.android

import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import dev.glance.widget.android.templates.ListItem
import kotlinx.coroutines.CancellationException

/**
 * Reading, writing and toggling the list widget's items.
 *
 * The items live in the widget's own state as one string, in either the JSON
 * the plugin writes today or the `a::true::b|||...` format older versions wrote.
 * A checkbox tap has to read that string, flip one entry and write it back --
 * inside an `ActionCallback`, which runs in a process that may have no Flutter
 * engine and nothing to report a failure to. A wrong answer there is silent:
 * the box springs back on the next redraw and reads as the tap having failed.
 *
 * The parsing used to be two private functions in `ListGlanceWidget.kt`, where
 * nothing could reach them. It is here so both the draw and the tap use one
 * copy, and so the edges can be checked without rendering a widget -- which a
 * Glance Composable cannot be in a JVM test.
 */
internal object ListItems {

    private const val LEGACY_ITEM_SEPARATOR = "|||"
    private const val LEGACY_FIELD_SEPARATOR = "::"

    private val gson = Gson()

    /** The outcome of a checkbox tap: the state to store, and what it now is. */
    data class Toggled(val items: String, val checked: Boolean)

    /**
     * The items in [stored], in whichever format it is written.
     *
     * Returns an empty list rather than throwing for anything unreadable. This
     * runs during a widget draw, and an exception there leaves the user looking
     * at Android's "Problem loading widget" box with no way to recover it.
     *
     * [onError] is where the failure is reported. It is a parameter rather than
     * a call to `android.util.Log` because that is not mocked in a JVM unit
     * test -- logging inside here would make the malformed-input cases, the
     * ones most worth checking, the only ones that cannot be.
     */
    fun parse(stored: String?, onError: ((Throwable) -> Unit)? = null): List<ListItem> {
        if (stored.isNullOrEmpty()) return emptyList()
        if (!stored.startsWith("[")) return parseLegacy(stored)

        return try {
            val type = object : TypeToken<List<Map<String, Any?>>>() {}.type
            val raw: List<Map<String, Any?>>? = gson.fromJson(stored, type)
            raw.orEmpty().map { entry ->
                ListItem(
                    text = entry["text"] as? String ?: "",
                    checked = entry["checked"] as? Boolean ?: false,
                    secondaryText = (entry["secondaryText"] as? String)?.takeIf { it.isNotEmpty() }
                )
            }
        } catch (e: CancellationException) {
            // Cancellation is not a parse failure. Swallowing it would break
            // structured concurrency for whichever coroutine is drawing.
            throw e
        } catch (e: Exception) {
            onError?.invoke(e)
            emptyList()
        }
    }

    /**
     * [items] as the string the widget stores.
     *
     * Always the JSON form. The legacy format cannot carry an item whose text
     * contains its own separators, so writing it back would corrupt a list the
     * user can legitimately have.
     */
    fun serialize(items: List<ListItem>): String =
        gson.toJson(
            items.map { item ->
                mapOf(
                    "text" to item.text,
                    "checked" to item.checked,
                    "secondaryText" to (item.secondaryText ?: "")
                )
            }
        )

    /**
     * [stored] with the item at [index] checked the other way, or `null` when
     * there is no such item.
     *
     * A widget on screen can be several updates behind its own state, so the
     * user taps the fourth row of a list that now has two. Returning `null`
     * leaves the state untouched and the widget redraws showing the real list.
     */
    fun toggling(stored: String?, index: Int, onError: ((Throwable) -> Unit)? = null): Toggled? {
        val items = parse(stored, onError)
        if (index !in items.indices) return null

        val flipped = items.toMutableList()
        val item = items[index]
        flipped[index] = item.copy(checked = !item.checked)
        return Toggled(items = serialize(flipped), checked = !item.checked)
    }

    /**
     * The format older versions of the plugin wrote.
     *
     * Widgets holding it are on someone's home screen right now, and nothing
     * rewrites one until the app updates that widget.
     */
    private fun parseLegacy(stored: String): List<ListItem> =
        stored.split(LEGACY_ITEM_SEPARATOR).map { entry ->
            val parts = entry.split(LEGACY_FIELD_SEPARATOR)
            ListItem(
                text = parts.getOrNull(0) ?: "",
                checked = parts.getOrNull(1)?.toBoolean() ?: false,
                secondaryText = parts.getOrNull(2)?.takeIf { it.isNotEmpty() }
            )
        }
}
