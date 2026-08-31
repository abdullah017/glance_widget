package dev.glance.widget.android

import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import kotlinx.coroutines.CancellationException

/**
 * An interaction handled while nothing was listening for it.
 *
 * A Glance `ActionCallback` runs in the app's process, which the system starts
 * for the broadcast if it is not already up. That process has no Flutter engine
 * and no Dart listener, so `GlanceWidgetManager.sendActionEvent` had nowhere to
 * put the event and dropped it: ticking a checkbox from the home screen while
 * the app was closed did nothing at all, silently.
 *
 * The payload is `Map<String, String>` rather than `Map<String, Any?>` on
 * purpose. Gson has no type tag for a JSON number, so a queued `itemIndex` of
 * `2` comes back as `2.0` -- a `Double` where Dart's `GlanceWidgetAction` reads
 * an `int`, which throws in the Dart layer, far from here. Storing strings and
 * restoring the types on the way out is what keeps a queued action identical to
 * a live one.
 */
internal data class PendingAction(
    val widgetId: String,
    val type: String,
    val payload: Map<String, String>?,
    val timestamp: Long
)

/**
 * The queue the widget process appends to and the plugin drains.
 *
 * This mirrors the iOS `GlanceActionQueue`, deliberately: an interaction should
 * reach Dart the same way and mean the same thing on both platforms.
 */
internal object ActionQueue {

    /**
     * The most actions the queue holds.
     *
     * An app that is never opened again would otherwise grow this without limit
     * in storage the user cannot see or clear. The oldest are the ones worth
     * losing.
     */
    const val CAPACITY = 100

    /** The SharedPreferences key the queue lives under. */
    const val STORAGE_KEY = "pending_widget_actions"

    private val gson = Gson()

    /** [queue] with [action] on the end, oldest first, trimmed to [CAPACITY]. */
    fun appending(action: PendingAction, queue: List<String>): List<String> {
        val encoded = encode(action) ?: return queue
        val appended = queue + encoded
        return if (appended.size > CAPACITY) appended.takeLast(CAPACITY) else appended
    }

    /**
     * The actions in [queue], skipping any entry that cannot be read.
     *
     * One unreadable entry -- written by an older build, or truncated -- must
     * not take the readable ones around it with it.
     */
    fun decode(queue: List<String>): List<PendingAction> =
        queue.mapNotNull { entry ->
            try {
                gson.fromJson(entry, PendingAction::class.java)
                    ?.takeIf { it.widgetId.isNotEmpty() && it.type.isNotEmpty() }
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                null
            }
        }

    /** [action] as the string the queue stores, or `null` if it cannot be. */
    fun encode(action: PendingAction): String? =
        try {
            gson.toJson(action)
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            null
        }

    /**
     * [action] as the event map `sendActionEvent` would have built live.
     *
     * The payload's strings become the types Dart reads -- an `itemIndex` is an
     * `int` and a `value` is a `bool` -- by the same rules on both platforms.
     * The timestamp is the one the interaction happened at, not the one the app
     * opened at; a backlog reported as all having happened at launch would be
     * worse than no timestamp.
     */
    fun eventFor(action: PendingAction): Map<String, Any?> {
        val event = mutableMapOf<String, Any?>(
            "widgetId" to action.widgetId,
            "type" to action.type,
            "timestamp" to action.timestamp
        )
        val payload = action.payload?.takeIf { it.isNotEmpty() }?.mapValues { (_, value) ->
            value.toIntOrNull() ?: when (value) {
                "true" -> true
                "false" -> false
                else -> value
            }
        }
        payload?.let { event["payload"] = it }
        return event
    }

    /** [payload]'s values as the strings the queue can store. */
    fun payloadOf(payload: Map<String, Any?>?): Map<String, String>? =
        payload?.takeIf { it.isNotEmpty() }?.mapValues { (_, value) -> value.toString() }

    /** The queue as stored, from a raw JSON array of entries. */
    fun read(stored: String?): List<String> {
        if (stored.isNullOrEmpty()) return emptyList()
        return try {
            val type = object : TypeToken<List<String>>() {}.type
            gson.fromJson<List<String>>(stored, type).orEmpty()
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            emptyList()
        }
    }

    /** [queue] as the single string SharedPreferences holds. */
    fun write(queue: List<String>): String = gson.toJson(queue)
}
