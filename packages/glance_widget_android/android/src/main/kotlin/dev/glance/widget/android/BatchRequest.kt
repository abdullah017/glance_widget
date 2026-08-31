package dev.glance.widget.android

/**
 * One widget's share of a batch, with its theme already resolved.
 *
 * The wire format sends the batch theme once and only repeats it for a widget
 * that overrides it, which is the point of batching in the first place. By the
 * time an entry reaches here the distinction is gone: [theme] is whatever this
 * widget should be drawn with.
 */
internal data class BatchEntry(
    val widgetId: String,
    val template: String,
    val data: Map<String, Any?>,
    val theme: Map<String, Any?>?
)

/** The result of reading a `updateBatch` call's arguments. */
internal sealed class BatchParse {
    /** The arguments described [entries], in the order they were sent. */
    data class Ok(val entries: List<BatchEntry>) : BatchParse()

    /** The arguments were not a batch at all, and why. */
    data class Invalid(val reason: String) : BatchParse()
}

/**
 * Reads the arguments of a `updateBatch` call.
 *
 * Kept free of Android types so the wire contract can be tested on the JVM.
 * The shape it accepts is the shape `MethodChannelGlanceWidget.updateBatch`
 * writes, and the tests on both sides pin the same key names -- a rename that
 * only lands on one side is otherwise silent, which is how `imageFit` went
 * unread for a whole release.
 */
internal object BatchRequest {

    fun parse(arguments: Any?): BatchParse {
        val root = arguments as? Map<*, *>
            ?: return BatchParse.Invalid(
                "updateBatch expects a map of arguments, got ${arguments?.javaClass?.simpleName ?: "null"}"
            )

        val rawUpdates = root["updates"]
            ?: return BatchParse.Invalid("updateBatch is missing 'updates'")
        val updates = rawUpdates as? List<*>
            ?: return BatchParse.Invalid("'updates' must be a list")

        // A batch theme is optional, and so is every field it would carry, so
        // an unusable value here is a caller mistake worth naming rather than
        // something to silently drop.
        val batchTheme = when (val theme = root["theme"]) {
            null -> null
            is Map<*, *> -> theme.stringKeyed()
            else -> return BatchParse.Invalid("'theme' must be a map")
        }

        val entries = ArrayList<BatchEntry>(updates.size)
        val seen = HashSet<String>(updates.size)

        updates.forEachIndexed { index, element ->
            val update = element as? Map<*, *>
                ?: return BatchParse.Invalid("updates[$index] is not a map")

            val widgetId = update["widgetId"] as? String
                ?: return BatchParse.Invalid("updates[$index] has no widgetId")
            if (widgetId.isEmpty()) {
                return BatchParse.Invalid("updates[$index] has an empty widgetId")
            }
            if (!seen.add(widgetId)) {
                // Two entries for one widget would race: whichever landed last
                // would win, with no way for the caller to know which.
                return BatchParse.Invalid("widgetId '$widgetId' appears more than once")
            }

            val template = update["template"] as? String
                ?: return BatchParse.Invalid("updates[$index] has no template")

            val data = (update["data"] as? Map<*, *>)?.stringKeyed()
                ?: return BatchParse.Invalid("updates[$index] has no data")

            val theme = when (val own = update["theme"]) {
                null -> batchTheme
                is Map<*, *> -> own.stringKeyed()
                else -> return BatchParse.Invalid("updates[$index] has a theme that is not a map")
            }

            entries.add(BatchEntry(widgetId, template, data, theme))
        }

        return BatchParse.Ok(entries)
    }

    /**
     * The channel hands back `Map<*, *>`; the manager reads `Map<String, Any?>`.
     * A non-string key cannot have come from the Dart side and is dropped
     * rather than crashing the whole batch.
     */
    private fun Map<*, *>.stringKeyed(): Map<String, Any?> =
        entries.mapNotNull { (key, value) ->
            (key as? String)?.let { it to value }
        }.toMap()
}
