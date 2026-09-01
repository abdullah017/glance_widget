package dev.glance.widget.android

import android.content.Context
import android.util.Log
import com.google.gson.Gson
import kotlinx.coroutines.CancellationException

/**
 * Keeps the payload the app last pushed for a widget id, so it can be read back.
 *
 * Glance stores what a *placed instance* draws from, keyed by `GlanceId` and
 * spread across typed preference keys. Rebuilding a Dart object out of those
 * would mean a second copy of the field mapping here and a third in Swift, all
 * free to drift. So this keeps the payload exactly as it arrived from Dart,
 * under the app's own widget id, and hands it back untouched. The mapping
 * between fields and classes stays in Dart, where it is written once.
 *
 * The record's lifetime is the tracked id's lifetime -- both are written by
 * [GlanceWidgetManager.recordWidget] and both are dropped by
 * `GlanceWidgetManager.forgetWidget`, so a widget the user removed cannot keep
 * answering. See #37.
 */
internal object WidgetRecordStore {

    private const val TAG = "GlanceWidgetRecord"
    private const val PREFS_NAME = "glance_widget_records"

    private val gson = Gson()

    /** Storage key for [widgetId]. */
    internal fun keyFor(widgetId: String): String = "record_$widgetId"

    /**
     * Builds the record for [widgetId], with no Android in sight so a test can
     * check the format without a device.
     *
     * `updatedAt` is milliseconds since the epoch. The seven template names are
     * the ones Dart's `GlanceTemplate` uses -- they are the wire contract, not
     * a label, which is why the callers pass them literally rather than
     * deriving them from a class name that a rename could change silently.
     */
    internal fun encode(
        widgetId: String,
        template: String,
        data: Map<String, Any?>,
        theme: Map<String, Any?>?,
        updatedAt: Long
    ): String = gson.toJson(
        mapOf(
            "widgetId" to widgetId,
            "template" to template,
            "updatedAt" to updatedAt,
            "data" to data,
            "theme" to theme
        )
    )

    /**
     * Stores what [widgetId] is now showing.
     *
     * A failure here is logged and dropped rather than failing the update: the
     * widget on the home screen has already changed, and reporting that write
     * as failed would be a lie about the thing the caller actually asked for.
     * The next update overwrites the record, so the damage is bounded to
     * `getWidgetData` being one revision stale until then.
     */
    fun save(
        context: Context,
        widgetId: String,
        template: String,
        data: Map<String, Any?>,
        theme: Map<String, Any?>?,
        updatedAt: Long = System.currentTimeMillis()
    ) {
        try {
            context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                .edit()
                .putString(keyFor(widgetId), encode(widgetId, template, data, theme, updatedAt))
                .apply()
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.w(TAG, "Could not record what \"$widgetId\" is showing", e)
        }
    }

    /** The record for [widgetId], or null when there is none. */
    fun read(context: Context, widgetId: String): String? =
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .getString(keyFor(widgetId), null)

    /** Drops the record for [widgetId]. */
    fun delete(context: Context, widgetId: String) {
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .remove(keyFor(widgetId))
            .apply()
    }
}
