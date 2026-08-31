package dev.glance.widget.android

import android.content.Context
import android.util.Log
import androidx.glance.GlanceId
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetManager
import androidx.glance.appwidget.state.getAppWidgetState
import androidx.glance.state.PreferencesGlanceStateDefinition
import kotlinx.coroutines.CancellationException
import dev.glance.widget.android.templates.CalendarGlanceWidget
import dev.glance.widget.android.templates.ChartGlanceWidget
import dev.glance.widget.android.templates.GaugeGlanceWidget
import dev.glance.widget.android.templates.ImageGlanceWidget
import dev.glance.widget.android.templates.ListGlanceWidget
import dev.glance.widget.android.templates.ProgressGlanceWidget
import dev.glance.widget.android.templates.SimpleGlanceWidget

/**
 * Cleans up after a widget the user dragged off the home screen.
 *
 * Every template calls this from `onDelete`, which Glance runs before it
 * deletes the instance's own state -- so the id the instance carried is still
 * readable here, and this is the only moment at which it is.
 *
 * Glance takes care of the per-instance state. What it does not know about is
 * everything the plugin keyed by the app's own `widgetId`: the downsampled
 * image on disk, and the id itself in `getActiveWidgetIds()`. Both used to
 * outlive the widget with no way to reach them again. See #13.
 */
internal object WidgetRemoval {

    private const val TAG = "GlanceWidgetRemoval"

    /** Every template class, for finding the instances that are still placed. */
    private val templateClasses: List<Class<out GlanceAppWidget>> = listOf(
        SimpleGlanceWidget::class.java,
        ProgressGlanceWidget::class.java,
        ListGlanceWidget::class.java,
        CalendarGlanceWidget::class.java,
        ImageGlanceWidget::class.java,
        ChartGlanceWidget::class.java,
        GaugeGlanceWidget::class.java
    )

    /** Exposed so a test can check no template is missing from the list. */
    internal val templateClassesForTest: List<Class<out GlanceAppWidget>> get() = templateClasses

    /**
     * Drops what [removed] was the last widget using.
     *
     * Reads the id off the instance being removed, then asks every other
     * placed instance which id it carries. An id still on screen keeps its
     * data; one that is not is unreachable, so it goes.
     */
    suspend fun onInstanceDeleted(context: Context, removed: GlanceId) {
        // Note the absence of runCatching: it catches CancellationException as
        // well, which would report a cancelled broadcast coroutine as a failed
        // read and break structured concurrency for the caller.
        val widgetId = try {
            readWidgetId(context, removed)
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.w(TAG, "Could not read the id of the removed widget", e)
            null
        }

        val surviving = try {
            survivingWidgetIds(context, removed)
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            // Not knowing what is still placed is not the same as knowing
            // nothing is. Deleting on a failed read is how a widget still on
            // the home screen loses its image.
            Log.w(TAG, "Could not list the placed widgets; keeping \"$widgetId\"", e)
            return
        }

        if (!WidgetRemovalPolicy.shouldForget(widgetId, surviving)) return
        val id = widgetId ?: return

        Log.d(TAG, "Last widget carrying \"$id\" was removed; dropping its data")
        GlanceWidgetManager.forgetWidget(context, id)
    }

    private suspend fun readWidgetId(context: Context, glanceId: GlanceId): String? =
        getAppWidgetState(
            context,
            PreferencesGlanceStateDefinition,
            glanceId
        )[GlanceWidgetManager.widgetIdKey]

    /**
     * The ids carried by every instance still on the home screen.
     *
     * [removed] is excluded by identity rather than trusted to be gone: whether
     * the host has already dropped it by the time `onDelete` runs is not
     * something the Glance API promises either way.
     */
    private suspend fun survivingWidgetIds(context: Context, removed: GlanceId): List<String?> {
        val manager = GlanceAppWidgetManager(context)
        return templateClasses
            .flatMap { manager.getGlanceIds(it) }
            .filter { it != removed }
            // A failed read here is deliberately not swallowed. An instance
            // whose id cannot be read might be the one still rendering the id
            // being removed, and reporting it as blank would delete the data
            // out from under a widget that is on the screen. The caller keeps
            // everything instead.
            .map { readWidgetId(context, it) }
    }
}
