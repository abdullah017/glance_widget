package dev.glance.widget.android

import android.content.Context
import android.content.SharedPreferences
import android.util.Log
import androidx.datastore.preferences.core.*
import androidx.glance.GlanceId
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetManager
import androidx.glance.appwidget.state.getAppWidgetState
import androidx.glance.appwidget.state.updateAppWidgetState
import androidx.glance.state.PreferencesGlanceStateDefinition
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Path
import android.graphics.RectF
import android.util.Base64
import dev.glance.widget.android.templates.CalendarGlanceWidget
import dev.glance.widget.android.templates.ChartGlanceWidget
import dev.glance.widget.android.templates.GaugeGlanceWidget
import dev.glance.widget.android.templates.ImageGlanceWidget
import dev.glance.widget.android.templates.ListGlanceWidget
import dev.glance.widget.android.templates.ProgressGlanceWidget
import dev.glance.widget.android.templates.SimpleGlanceWidget
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import io.flutter.plugin.common.EventChannel
import kotlinx.coroutines.*
import java.io.ByteArrayOutputStream

/**
 * Result type for widget update operations.
 * Provides structured error information for proper error handling.
 */
sealed class UpdateResult {
    object Success : UpdateResult()
    data class Error(val code: String, val message: String) : UpdateResult()

    val isSuccess: Boolean get() = this is Success
    val isError: Boolean get() = this is Error

    companion object {
        // Error codes
        const val ERROR_NO_WIDGET_INSTANCE = "NO_WIDGET_INSTANCE"
        const val ERROR_UPDATE_FAILED = "UPDATE_FAILED"
        const val ERROR_INVALID_DATA = "INVALID_DATA"
        const val ERROR_SERIALIZATION_FAILED = "SERIALIZATION_FAILED"
    }
}

/**
 * Manages Glance widget updates and state.
 */
object GlanceWidgetManager {
    private const val TAG = "GlanceWidgetManager"
    private const val PREFS_NAME = "glance_widget_prefs"
    private const val ACTIVE_WIDGETS_KEY = "active_widget_ids"

    // Managed coroutine scope with SupervisorJob for proper lifecycle management
    private val supervisorJob = SupervisorJob()
    private val scope = CoroutineScope(Dispatchers.IO + supervisorJob)

    // Thread-safe event sink management
    private var eventSink: EventChannel.EventSink? = null
    private val eventSinkLock = Any()

    // Gson instance for JSON serialization
    private val gson = Gson()

    // Active widget tracking
    private val activeWidgetIds = mutableSetOf<String>()

    // Preference keys
    val widgetIdKey = stringPreferencesKey("widgetId")
    val titleKey = stringPreferencesKey("title")
    val valueKey = stringPreferencesKey("value")
    val subtitleKey = stringPreferencesKey("subtitle")
    val subtitleColorKey = intPreferencesKey("subtitleColor")
    val iconNameKey = stringPreferencesKey("iconName")
    val progressKey = floatPreferencesKey("progress")
    val progressTypeKey = stringPreferencesKey("progressType")
    val progressColorKey = intPreferencesKey("progressColor")
    val trackColorKey = intPreferencesKey("trackColor")
    val itemsKey = stringPreferencesKey("items")
    val showCheckboxesKey = booleanPreferencesKey("showCheckboxes")
    val timestampKey = longPreferencesKey("timestamp")

    // Calendar keys
    val dateKey = stringPreferencesKey("date")
    val eventsKey = stringPreferencesKey("events")
    val maxEventsKey = intPreferencesKey("maxEvents")

    // Image keys
    val imageBase64Key = stringPreferencesKey("imageBase64")
    val imagePathKey = stringPreferencesKey("imagePath")
    val imageFitKey = stringPreferencesKey("imageFit")

    // Chart keys
    val dataPointsKey = stringPreferencesKey("dataPoints")
    val chartTypeKey = stringPreferencesKey("chartType")
    val chartColorKey = intPreferencesKey("chartColor")
    val chartBitmapKey = stringPreferencesKey("chartBitmap")

    // Gauge keys
    val metricsKey = stringPreferencesKey("metrics")
    val gaugeTypeKey = stringPreferencesKey("gaugeType")
    val gaugeBitmapKey = stringPreferencesKey("gaugeBitmap")

    // Deep link key
    val deepLinkUriKey = stringPreferencesKey("deepLinkUri")

    // Theme keys
    val backgroundColorKey = intPreferencesKey("backgroundColor")
    val textColorKey = intPreferencesKey("textColor")
    val secondaryTextColorKey = intPreferencesKey("secondaryTextColor")
    val accentColorKey = intPreferencesKey("accentColor")
    val borderRadiusKey = floatPreferencesKey("borderRadius")
    val isDarkKey = booleanPreferencesKey("isDark")

    fun initialize(context: Context, sink: EventChannel.EventSink?) {
        synchronized(eventSinkLock) {
            eventSink = sink
        }
        // Load persisted active widget IDs
        loadActiveWidgetIds(context)
        Log.d(TAG, "GlanceWidgetManager initialized")
    }

    /**
     * Attaches or detaches the Dart listener.
     *
     * Attaching one is the first moment a queued interaction can be delivered,
     * so the backlog is drained here. [context] is what reaches the shared
     * preferences the widget process wrote to; without it the queue is left
     * alone rather than discarded.
     */
    fun setEventSink(sink: EventChannel.EventSink?, context: Context? = null) {
        synchronized(eventSinkLock) {
            eventSink = sink
            Log.d(TAG, "EventSink ${if (sink != null) "set" else "cleared"}")
        }
        if (sink != null && context != null) {
            drainPendingActions(context)
        }
    }

    /**
     * Replays the interactions the widget process handled on its own.
     *
     * A Glance `ActionCallback` runs in the app's process, which the system
     * starts for the broadcast if it is not already up -- with no Flutter
     * engine in it. Events sent from there had nowhere to go and were dropped,
     * so a checkbox ticked from the home screen while the app was closed did
     * nothing at all. `ToggleListItemAction` queues them instead; this empties
     * the queue.
     *
     * Nothing is drained while no listener is attached: the event sink discards
     * what it is handed then, so clearing the queue would throw the backlog
     * away in exactly the situation the queue exists for.
     */
    fun drainPendingActions(context: Context) {
        val listening = synchronized(eventSinkLock) { eventSink != null }
        if (!listening) return

        scope.launch {
            try {
                val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                val stored = ActionQueue.read(prefs.getString(ActionQueue.STORAGE_KEY, null))
                if (stored.isEmpty()) return@launch

                // Cleared before replaying: an entry that fails to decode is
                // still consumed, so one unreadable action cannot make the
                // queue un-drainable and let it grow behind it forever.
                prefs.edit().remove(ActionQueue.STORAGE_KEY).apply()

                val events = ActionQueue.decode(stored).map { ActionQueue.eventFor(it) }
                withContext(Dispatchers.Main) {
                    synchronized(eventSinkLock) {
                        events.forEach { event -> eventSink?.success(event) }
                    }
                }
                Log.d(TAG, "Replayed ${events.size} queued widget actions")
            } catch (e: CancellationException) {
                // Cancellation is not a delivery failure. Swallowing it would
                // break structured concurrency for every caller upstream.
                throw e
            } catch (e: Exception) {
                Log.e(TAG, "Failed to replay queued widget actions", e)
            }
        }
    }

    /**
     * Reports [actionType] to Dart, or queues it when nobody is listening.
     *
     * This is what an `ActionCallback` calls. It cannot assume a Flutter engine
     * exists: its own process may have been started by the system purely to
     * deliver the tap.
     */
    fun recordActionEvent(
        context: Context,
        widgetId: String,
        actionType: String,
        payload: Map<String, Any?>? = null
    ) {
        val listening = synchronized(eventSinkLock) { eventSink != null }
        if (listening) {
            sendActionEvent(widgetId, actionType, payload)
            return
        }

        scope.launch {
            try {
                val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                val queue = ActionQueue.read(prefs.getString(ActionQueue.STORAGE_KEY, null))
                val appended = ActionQueue.appending(
                    PendingAction(
                        widgetId = widgetId,
                        type = actionType,
                        payload = ActionQueue.payloadOf(payload),
                        timestamp = System.currentTimeMillis()
                    ),
                    queue
                )
                prefs.edit().putString(ActionQueue.STORAGE_KEY, ActionQueue.write(appended)).apply()
                Log.d(TAG, "Queued $actionType for $widgetId; no Dart listener attached")
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.e(TAG, "Failed to queue widget action", e)
            }
        }
    }

    /**
     * Cleans up resources. Call this when the plugin is detached.
     */
    fun cleanup() {
        Log.d(TAG, "Cleaning up GlanceWidgetManager")
        supervisorJob.cancel()
        synchronized(eventSinkLock) {
            eventSink = null
        }
    }

    /**
     * Updates a Simple Widget with the given data.
     */
    fun updateSimpleWidget(
        context: Context,
        widgetId: String,
        data: Map<String, Any?>,
        theme: Map<String, Any?>?
    ) {
        scope.launch {
            updateSimpleWidgetWithResult(context, widgetId, data, theme)
        }
    }

    /**
     * Picks the placed instances an update is addressed to.
     *
     * `getGlanceIds` answers with every instance of a template at once, which is
     * why updates used to be written to all of them -- data for one widget id
     * would overwrite another's. The id an instance carries lives in its own
     * state under [widgetIdKey]; reading it back is what makes `widgetId` the
     * "unique identifier for this widget instance" the API promises.
     */
    private suspend fun resolveTargets(
        context: Context,
        widgetClass: Class<out GlanceAppWidget>,
        widgetId: String
    ): WidgetInstanceResolver.Resolution<GlanceId> {
        val instances = GlanceAppWidgetManager(context).getGlanceIds(widgetClass).map { glanceId ->
            val stored =
                getAppWidgetState(context, PreferencesGlanceStateDefinition, glanceId)[widgetIdKey]
            WidgetInstanceResolver.Instance(glanceId, stored)
        }
        return WidgetInstanceResolver.resolve(instances, widgetId)
    }

    /**
     * Updates a Simple Widget with the given data and returns a result.
     * Use this method when you need to handle errors.
     */
    suspend fun updateSimpleWidgetWithResult(
        context: Context,
        widgetId: String,
        data: Map<String, Any?>,
        theme: Map<String, Any?>?
    ): UpdateResult {
        return try {
            Log.d(TAG, "Updating simple widget: $widgetId")
            val widget = SimpleGlanceWidget()
            val glanceIds =
                when (val targets = resolveTargets(context, SimpleGlanceWidget::class.java, widgetId)) {
                    is WidgetInstanceResolver.Resolution.NoTarget -> {
                        Log.w(TAG, "SimpleGlanceWidget \"$widgetId\": ${targets.reason}")
                        return UpdateResult.Error(
                            UpdateResult.ERROR_NO_WIDGET_INSTANCE,
                            "SimpleGlanceWidget \"$widgetId\": ${targets.reason}"
                        )
                    }
                    is WidgetInstanceResolver.Resolution.Targets -> targets.handles
                }

            glanceIds.forEach { glanceId ->
                updateAppWidgetState(context, PreferencesGlanceStateDefinition, glanceId) { prefs ->
                    prefs.toMutablePreferences().apply {
                        this[widgetIdKey] = widgetId
                        this[titleKey] = data["title"] as? String ?: ""
                        this[valueKey] = data["value"] as? String ?: ""
                        data["subtitle"]?.let { this[subtitleKey] = it as String }
                        (data["subtitleColor"] as? Number)?.let { this[subtitleColorKey] = it.toInt() }
                        data["iconName"]?.let { this[iconNameKey] = it as String }
                        data["deepLinkUri"]?.let { this[deepLinkUriKey] = it as String }
                        this[timestampKey] = System.currentTimeMillis()

                        // Apply theme if provided
                        theme?.let { applyTheme(this, it) }
                    }
                }
                widget.update(context, glanceId)
            }

            // Track this widget as active
            trackWidgetId(context, widgetId)
            Log.d(TAG, "Simple widget updated successfully: $widgetId")
            UpdateResult.Success
        } catch (e: CancellationException) {
            // Cancellation is not an update failure. Swallowing it here would
            // report a cancelled coroutine as a rejected update and break
            // structured concurrency for every caller upstream.
            throw e
        } catch (e: Exception) {
            Log.e(TAG, "Failed to update simple widget: $widgetId", e)
            UpdateResult.Error(
                UpdateResult.ERROR_UPDATE_FAILED,
                "Failed to update simple widget: ${e.message}"
            )
        }
    }

    /**
     * Updates a Progress Widget with the given data.
     */
    fun updateProgressWidget(
        context: Context,
        widgetId: String,
        data: Map<String, Any?>,
        theme: Map<String, Any?>?
    ) {
        scope.launch {
            updateProgressWidgetWithResult(context, widgetId, data, theme)
        }
    }

    /**
     * Updates a Progress Widget with the given data and returns a result.
     * Use this method when you need to handle errors.
     */
    suspend fun updateProgressWidgetWithResult(
        context: Context,
        widgetId: String,
        data: Map<String, Any?>,
        theme: Map<String, Any?>?
    ): UpdateResult {
        return try {
            Log.d(TAG, "Updating progress widget: $widgetId")
            val widget = ProgressGlanceWidget()
            val glanceIds =
                when (val targets = resolveTargets(context, ProgressGlanceWidget::class.java, widgetId)) {
                    is WidgetInstanceResolver.Resolution.NoTarget -> {
                        Log.w(TAG, "ProgressGlanceWidget \"$widgetId\": ${targets.reason}")
                        return UpdateResult.Error(
                            UpdateResult.ERROR_NO_WIDGET_INSTANCE,
                            "ProgressGlanceWidget \"$widgetId\": ${targets.reason}"
                        )
                    }
                    is WidgetInstanceResolver.Resolution.Targets -> targets.handles
                }

            glanceIds.forEach { glanceId ->
                updateAppWidgetState(context, PreferencesGlanceStateDefinition, glanceId) { prefs ->
                    prefs.toMutablePreferences().apply {
                        this[widgetIdKey] = widgetId
                        this[titleKey] = data["title"] as? String ?: ""
                        this[progressKey] = (data["progress"] as? Number)?.toFloat()?.coerceIn(0f, 1f) ?: 0f
                        data["subtitle"]?.let { this[subtitleKey] = it as String }
                        this[progressTypeKey] = data["progressType"] as? String ?: "circular"
                        (data["progressColor"] as? Number)?.let { this[progressColorKey] = it.toInt() }
                        (data["trackColor"] as? Number)?.let { this[trackColorKey] = it.toInt() }
                        data["deepLinkUri"]?.let { this[deepLinkUriKey] = it as String }
                        this[timestampKey] = System.currentTimeMillis()

                        // Apply theme if provided
                        theme?.let { applyTheme(this, it) }
                    }
                }
                widget.update(context, glanceId)
            }

            // Track this widget as active
            trackWidgetId(context, widgetId)
            Log.d(TAG, "Progress widget updated successfully: $widgetId")
            UpdateResult.Success
        } catch (e: CancellationException) {
            // Cancellation is not an update failure. Swallowing it here would
            // report a cancelled coroutine as a rejected update and break
            // structured concurrency for every caller upstream.
            throw e
        } catch (e: Exception) {
            Log.e(TAG, "Failed to update progress widget: $widgetId", e)
            UpdateResult.Error(
                UpdateResult.ERROR_UPDATE_FAILED,
                "Failed to update progress widget: ${e.message}"
            )
        }
    }

    /**
     * Updates a List Widget with the given data.
     */
    fun updateListWidget(
        context: Context,
        widgetId: String,
        data: Map<String, Any?>,
        theme: Map<String, Any?>?
    ) {
        scope.launch {
            updateListWidgetWithResult(context, widgetId, data, theme)
        }
    }

    /**
     * Updates a List Widget with the given data and returns a result.
     * Use this method when you need to handle errors.
     */
    suspend fun updateListWidgetWithResult(
        context: Context,
        widgetId: String,
        data: Map<String, Any?>,
        theme: Map<String, Any?>?
    ): UpdateResult {
        return try {
            Log.d(TAG, "Updating list widget: $widgetId")
            val widget = ListGlanceWidget()
            val glanceIds =
                when (val targets = resolveTargets(context, ListGlanceWidget::class.java, widgetId)) {
                    is WidgetInstanceResolver.Resolution.NoTarget -> {
                        Log.w(TAG, "ListGlanceWidget \"$widgetId\": ${targets.reason}")
                        return UpdateResult.Error(
                            UpdateResult.ERROR_NO_WIDGET_INSTANCE,
                            "ListGlanceWidget \"$widgetId\": ${targets.reason}"
                        )
                    }
                    is WidgetInstanceResolver.Resolution.Targets -> targets.handles
                }

            glanceIds.forEach { glanceId ->
                updateAppWidgetState(context, PreferencesGlanceStateDefinition, glanceId) { prefs ->
                    prefs.toMutablePreferences().apply {
                        this[widgetIdKey] = widgetId
                        this[titleKey] = data["title"] as? String ?: ""
                        // Serialize items as JSON string
                        @Suppress("UNCHECKED_CAST")
                        val items = data["items"] as? List<Map<String, Any?>> ?: emptyList()
                        this[itemsKey] = serializeItems(items)
                        this[showCheckboxesKey] = data["showCheckboxes"] as? Boolean ?: false
                        data["deepLinkUri"]?.let { this[deepLinkUriKey] = it as String }
                        this[timestampKey] = System.currentTimeMillis()

                        // Apply theme if provided
                        theme?.let { applyTheme(this, it) }
                    }
                }
                widget.update(context, glanceId)
            }

            // Track this widget as active
            trackWidgetId(context, widgetId)
            Log.d(TAG, "List widget updated successfully: $widgetId")
            UpdateResult.Success
        } catch (e: CancellationException) {
            // Cancellation is not an update failure. Swallowing it here would
            // report a cancelled coroutine as a rejected update and break
            // structured concurrency for every caller upstream.
            throw e
        } catch (e: Exception) {
            Log.e(TAG, "Failed to update list widget: $widgetId", e)
            UpdateResult.Error(
                UpdateResult.ERROR_UPDATE_FAILED,
                "Failed to update list widget: ${e.message}"
            )
        }
    }

    /**
     * Updates a Calendar Widget with the given data.
     */
    fun updateCalendarWidget(
        context: Context,
        widgetId: String,
        data: Map<String, Any?>,
        theme: Map<String, Any?>?
    ) {
        scope.launch {
            updateCalendarWidgetWithResult(context, widgetId, data, theme)
        }
    }

    /**
     * Updates a Calendar Widget with the given data and returns a result.
     */
    suspend fun updateCalendarWidgetWithResult(
        context: Context,
        widgetId: String,
        data: Map<String, Any?>,
        theme: Map<String, Any?>?
    ): UpdateResult {
        return try {
            Log.d(TAG, "Updating calendar widget: $widgetId")
            val widget = CalendarGlanceWidget()
            val glanceIds =
                when (val targets = resolveTargets(context, CalendarGlanceWidget::class.java, widgetId)) {
                    is WidgetInstanceResolver.Resolution.NoTarget -> {
                        Log.w(TAG, "CalendarGlanceWidget \"$widgetId\": ${targets.reason}")
                        return UpdateResult.Error(
                            UpdateResult.ERROR_NO_WIDGET_INSTANCE,
                            "CalendarGlanceWidget \"$widgetId\": ${targets.reason}"
                        )
                    }
                    is WidgetInstanceResolver.Resolution.Targets -> targets.handles
                }

            glanceIds.forEach { glanceId ->
                updateAppWidgetState(context, PreferencesGlanceStateDefinition, glanceId) { prefs ->
                    prefs.toMutablePreferences().apply {
                        this[widgetIdKey] = widgetId
                        this[titleKey] = data["title"] as? String ?: "Calendar"
                        data["date"]?.let { this[dateKey] = it as String }
                        // Serialize events as JSON string
                        @Suppress("UNCHECKED_CAST")
                        val events = data["events"] as? List<Map<String, Any?>> ?: emptyList()
                        this[eventsKey] = serializeItems(events)
                        (data["maxEvents"] as? Number)?.let { this[maxEventsKey] = it.toInt() }
                        data["deepLinkUri"]?.let { this[deepLinkUriKey] = it as String }
                        this[timestampKey] = System.currentTimeMillis()

                        // Apply theme if provided
                        theme?.let { applyTheme(this, it) }
                    }
                }
                widget.update(context, glanceId)
            }

            trackWidgetId(context, widgetId)
            Log.d(TAG, "Calendar widget updated successfully: $widgetId")
            UpdateResult.Success
        } catch (e: CancellationException) {
            // Cancellation is not an update failure. Swallowing it here would
            // report a cancelled coroutine as a rejected update and break
            // structured concurrency for every caller upstream.
            throw e
        } catch (e: Exception) {
            Log.e(TAG, "Failed to update calendar widget: $widgetId", e)
            UpdateResult.Error(
                UpdateResult.ERROR_UPDATE_FAILED,
                "Failed to update calendar widget: ${e.message}"
            )
        }
    }

    /**
     * Updates an Image Widget with the given data.
     */
    fun updateImageWidget(
        context: Context,
        widgetId: String,
        data: Map<String, Any?>,
        theme: Map<String, Any?>?
    ) {
        scope.launch {
            updateImageWidgetWithResult(context, widgetId, data, theme)
        }
    }

    /**
     * Updates an Image Widget with the given data and returns a result.
     */
    suspend fun updateImageWidgetWithResult(
        context: Context,
        widgetId: String,
        data: Map<String, Any?>,
        theme: Map<String, Any?>?
    ): UpdateResult {
        return try {
            Log.d(TAG, "Updating image widget: $widgetId")

            // Resolved here rather than in the template: `imageUrl` needs the
            // network and every picture needs downsampling, and a Glance
            // composition runs in the host's process on the host's schedule.
            val stored = ImageStore.store(
                context,
                widgetId,
                data["imageBase64"] as? String,
                data["imageUrl"] as? String
            )
            if (stored is ImageStore.Result.Failed) {
                Log.w(TAG, "Image widget \"$widgetId\": ${stored.reason}")
                return UpdateResult.Error(UpdateResult.ERROR_INVALID_DATA, stored.reason)
            }

            val widget = ImageGlanceWidget()
            val glanceIds =
                when (val targets = resolveTargets(context, ImageGlanceWidget::class.java, widgetId)) {
                    is WidgetInstanceResolver.Resolution.NoTarget -> {
                        Log.w(TAG, "ImageGlanceWidget \"$widgetId\": ${targets.reason}")
                        return UpdateResult.Error(
                            UpdateResult.ERROR_NO_WIDGET_INSTANCE,
                            "ImageGlanceWidget \"$widgetId\": ${targets.reason}"
                        )
                    }
                    is WidgetInstanceResolver.Resolution.Targets -> targets.handles
                }

            glanceIds.forEach { glanceId ->
                updateAppWidgetState(context, PreferencesGlanceStateDefinition, glanceId) { prefs ->
                    prefs.toMutablePreferences().apply {
                        this[widgetIdKey] = widgetId
                        this[titleKey] = data["title"] as? String ?: ""
                        data["subtitle"]?.let { this[subtitleKey] = it as String }
                        when (stored) {
                            is ImageStore.Result.Stored -> this[imagePathKey] = stored.path
                            // A widget that used to show a picture and no longer
                            // has one must stop showing the old one.
                            else -> remove(imagePathKey)
                        }
                        // Dart sends `fit`; this read `imageFit`, so the setting
                        // silently never applied.
                        data["fit"]?.let { this[imageFitKey] = it as String }
                        data["deepLinkUri"]?.let { this[deepLinkUriKey] = it as String }
                        this[timestampKey] = System.currentTimeMillis()

                        // Apply theme if provided
                        theme?.let { applyTheme(this, it) }
                    }
                }
                widget.update(context, glanceId)
            }

            trackWidgetId(context, widgetId)
            Log.d(TAG, "Image widget updated successfully: $widgetId")
            UpdateResult.Success
        } catch (e: CancellationException) {
            // Cancellation is not an update failure. Swallowing it here would
            // report a cancelled coroutine as a rejected update and break
            // structured concurrency for every caller upstream.
            throw e
        } catch (e: Exception) {
            Log.e(TAG, "Failed to update image widget: $widgetId", e)
            UpdateResult.Error(
                UpdateResult.ERROR_UPDATE_FAILED,
                "Failed to update image widget: ${e.message}"
            )
        }
    }

    /**
     * Updates a Chart Widget with the given data.
     */
    fun updateChartWidget(
        context: Context,
        widgetId: String,
        data: Map<String, Any?>,
        theme: Map<String, Any?>?
    ) {
        scope.launch {
            updateChartWidgetWithResult(context, widgetId, data, theme)
        }
    }

    /**
     * Updates a Chart Widget with the given data and returns a result.
     * Renders the chart as a bitmap using Android Canvas before storing in preferences.
     */
    suspend fun updateChartWidgetWithResult(
        context: Context,
        widgetId: String,
        data: Map<String, Any?>,
        theme: Map<String, Any?>?
    ): UpdateResult {
        return try {
            Log.d(TAG, "Updating chart widget: $widgetId")
            val widget = ChartGlanceWidget()
            val glanceIds =
                when (val targets = resolveTargets(context, ChartGlanceWidget::class.java, widgetId)) {
                    is WidgetInstanceResolver.Resolution.NoTarget -> {
                        Log.w(TAG, "ChartGlanceWidget \"$widgetId\": ${targets.reason}")
                        return UpdateResult.Error(
                            UpdateResult.ERROR_NO_WIDGET_INSTANCE,
                            "ChartGlanceWidget \"$widgetId\": ${targets.reason}"
                        )
                    }
                    is WidgetInstanceResolver.Resolution.Targets -> targets.handles
                }

            // Extract chart parameters
            val chartType = data["chartType"] as? String ?: "line"
            val chartColor = (data["chartColor"] as? Number)?.toInt() ?: 0xFF2196F3.toInt()
            @Suppress("UNCHECKED_CAST")
            val dataPoints = data["dataPoints"] as? List<Number> ?: emptyList()
            val isDark = theme?.get("isDark") as? Boolean ?: true

            // Render chart bitmap
            val chartBitmapBase64 = if (dataPoints.isNotEmpty()) {
                renderChartBitmap(dataPoints.map { it.toFloat() }, chartType, chartColor, isDark)
            } else {
                ""
            }

            glanceIds.forEach { glanceId ->
                updateAppWidgetState(context, PreferencesGlanceStateDefinition, glanceId) { prefs ->
                    prefs.toMutablePreferences().apply {
                        this[widgetIdKey] = widgetId
                        this[titleKey] = data["title"] as? String ?: ""
                        data["subtitle"]?.let { this[subtitleKey] = it as String }
                        this[chartTypeKey] = chartType
                        this[chartColorKey] = chartColor
                        this[dataPointsKey] = serializeItems(dataPoints.map { mapOf("v" to it) })
                        this[chartBitmapKey] = chartBitmapBase64
                        data["deepLinkUri"]?.let { this[deepLinkUriKey] = it as String }
                        this[timestampKey] = System.currentTimeMillis()

                        // Apply theme if provided
                        theme?.let { applyTheme(this, it) }
                    }
                }
                widget.update(context, glanceId)
            }

            trackWidgetId(context, widgetId)
            Log.d(TAG, "Chart widget updated successfully: $widgetId")
            UpdateResult.Success
        } catch (e: CancellationException) {
            // Cancellation is not an update failure. Swallowing it here would
            // report a cancelled coroutine as a rejected update and break
            // structured concurrency for every caller upstream.
            throw e
        } catch (e: Exception) {
            Log.e(TAG, "Failed to update chart widget: $widgetId", e)
            UpdateResult.Error(
                UpdateResult.ERROR_UPDATE_FAILED,
                "Failed to update chart widget: ${e.message}"
            )
        }
    }

    /**
     * Updates a Gauge Widget with the given data.
     */
    fun updateGaugeWidget(
        context: Context,
        widgetId: String,
        data: Map<String, Any?>,
        theme: Map<String, Any?>?
    ) {
        scope.launch {
            updateGaugeWidgetWithResult(context, widgetId, data, theme)
        }
    }

    /**
     * Updates a Gauge Widget with the given data and returns a result.
     * For radial type, renders the gauge arc as a bitmap using Android Canvas.
     * For dashboard type, metrics are stored as JSON and rendered by the widget.
     */
    suspend fun updateGaugeWidgetWithResult(
        context: Context,
        widgetId: String,
        data: Map<String, Any?>,
        theme: Map<String, Any?>?
    ): UpdateResult {
        return try {
            Log.d(TAG, "Updating gauge widget: $widgetId")
            val widget = GaugeGlanceWidget()
            val glanceIds =
                when (val targets = resolveTargets(context, GaugeGlanceWidget::class.java, widgetId)) {
                    is WidgetInstanceResolver.Resolution.NoTarget -> {
                        Log.w(TAG, "GaugeGlanceWidget \"$widgetId\": ${targets.reason}")
                        return UpdateResult.Error(
                            UpdateResult.ERROR_NO_WIDGET_INSTANCE,
                            "GaugeGlanceWidget \"$widgetId\": ${targets.reason}"
                        )
                    }
                    is WidgetInstanceResolver.Resolution.Targets -> targets.handles
                }

            val gaugeType = data["gaugeType"] as? String ?: "radial"
            val isDark = theme?.get("isDark") as? Boolean ?: true

            // For radial gauge, render bitmap. Everything it draws comes out
            // of the first metric -- see RadialGaugeParams for why it cannot be
            // read straight off `data`.
            val accentColor = (theme?.get("accentColor") as? Number)?.toInt()
                ?: 0xFF2196F3.toInt()
            val gaugeBitmapBase64 = if (gaugeType == "radial") {
                val params = GaugeMetrics.forRadial(data, accentColor, isDark)
                if (params == null) {
                    ""
                } else {
                    renderGaugeBitmap(
                        params.progress,
                        params.gaugeColor,
                        params.trackColor,
                        params.valueText,
                        params.minLabel,
                        params.maxLabel,
                        isDark
                    )
                }
            } else {
                ""
            }

            // Serialize metrics for dashboard type. The template reads a
            // formatted `value` string and a ready `progress` fraction, which
            // is not the shape Dart sends -- GaugeMetrics does the translation.
            val metrics = GaugeMetrics.forDashboard(data)
            val metricsJson = if (metrics.isNotEmpty()) serializeItems(metrics) else "[]"

            glanceIds.forEach { glanceId ->
                updateAppWidgetState(context, PreferencesGlanceStateDefinition, glanceId) { prefs ->
                    prefs.toMutablePreferences().apply {
                        this[widgetIdKey] = widgetId
                        this[titleKey] = data["title"] as? String ?: ""
                        this[gaugeTypeKey] = gaugeType
                        this[gaugeBitmapKey] = gaugeBitmapBase64
                        this[metricsKey] = metricsJson
                        data["deepLinkUri"]?.let { this[deepLinkUriKey] = it as String }
                        this[timestampKey] = System.currentTimeMillis()

                        // Apply theme if provided
                        theme?.let { applyTheme(this, it) }
                    }
                }
                widget.update(context, glanceId)
            }

            trackWidgetId(context, widgetId)
            Log.d(TAG, "Gauge widget updated successfully: $widgetId")
            UpdateResult.Success
        } catch (e: CancellationException) {
            // Cancellation is not an update failure. Swallowing it here would
            // report a cancelled coroutine as a rejected update and break
            // structured concurrency for every caller upstream.
            throw e
        } catch (e: Exception) {
            Log.e(TAG, "Failed to update gauge widget: $widgetId", e)
            UpdateResult.Error(
                UpdateResult.ERROR_UPDATE_FAILED,
                "Failed to update gauge widget: ${e.message}"
            )
        }
    }

    /**
     * Sets the global theme for all widgets.
     */
    fun setGlobalTheme(context: Context, theme: Map<String, Any?>) {
        scope.launch {
            try {
                Log.d(TAG, "Setting global theme")
                // Update all widget types
                listOf(
                    SimpleGlanceWidget::class.java to SimpleGlanceWidget(),
                    ProgressGlanceWidget::class.java to ProgressGlanceWidget(),
                    ListGlanceWidget::class.java to ListGlanceWidget(),
                    CalendarGlanceWidget::class.java to CalendarGlanceWidget(),
                    ImageGlanceWidget::class.java to ImageGlanceWidget(),
                    ChartGlanceWidget::class.java to ChartGlanceWidget(),
                    GaugeGlanceWidget::class.java to GaugeGlanceWidget()
                ).forEach { (clazz, widget) ->
                    val manager = GlanceAppWidgetManager(context)
                    val glanceIds = manager.getGlanceIds(clazz)

                    glanceIds.forEach { glanceId ->
                        updateAppWidgetState(context, PreferencesGlanceStateDefinition, glanceId) { prefs ->
                            prefs.toMutablePreferences().apply {
                                applyTheme(this, theme)
                                this[timestampKey] = System.currentTimeMillis()
                            }
                        }
                        widget.update(context, glanceId)
                    }
                }
                Log.d(TAG, "Global theme set successfully")
            } catch (e: CancellationException) {
            // Cancellation is not an update failure. Swallowing it here would
            // report a cancelled coroutine as a rejected update and break
            // structured concurrency for every caller upstream.
            throw e
        } catch (e: Exception) {
                Log.e(TAG, "Failed to set global theme", e)
            }
        }
    }

    /**
     * Force refreshes all widgets.
     */
    fun forceRefreshAll(context: Context) {
        scope.launch {
            try {
                Log.d(TAG, "Force refreshing all widgets")
                listOf(
                    SimpleGlanceWidget::class.java to SimpleGlanceWidget(),
                    ProgressGlanceWidget::class.java to ProgressGlanceWidget(),
                    ListGlanceWidget::class.java to ListGlanceWidget(),
                    CalendarGlanceWidget::class.java to CalendarGlanceWidget(),
                    ImageGlanceWidget::class.java to ImageGlanceWidget(),
                    ChartGlanceWidget::class.java to ChartGlanceWidget(),
                    GaugeGlanceWidget::class.java to GaugeGlanceWidget()
                ).forEach { (clazz, widget) ->
                    val manager = GlanceAppWidgetManager(context)
                    val glanceIds = manager.getGlanceIds(clazz)
                    glanceIds.forEach { glanceId ->
                        widget.update(context, glanceId)
                    }
                }
                Log.d(TAG, "All widgets refreshed successfully")
            } catch (e: CancellationException) {
            // Cancellation is not an update failure. Swallowing it here would
            // report a cancelled coroutine as a rejected update and break
            // structured concurrency for every caller upstream.
            throw e
        } catch (e: Exception) {
                Log.e(TAG, "Failed to force refresh all widgets", e)
            }
        }
    }

    /**
     * Gets the list of active widget IDs.
     */
    fun getActiveWidgetIds(context: Context): List<String> {
        return synchronized(activeWidgetIds) {
            activeWidgetIds.toList()
        }
    }

    /**
     * Sends an action event to Flutter.
     */
    fun sendActionEvent(widgetId: String, actionType: String, payload: Map<String, Any?>? = null) {
        val event = mutableMapOf<String, Any?>(
            "widgetId" to widgetId,
            "type" to actionType,
            "timestamp" to System.currentTimeMillis()
        )
        payload?.let { event["payload"] = it }

        // Use main dispatcher for UI thread safety
        CoroutineScope(Dispatchers.Main).launch {
            synchronized(eventSinkLock) {
                try {
                    eventSink?.success(event)
                    Log.d(TAG, "Action event sent: $actionType for widget $widgetId")
                } catch (e: CancellationException) {
            // Cancellation is not an update failure. Swallowing it here would
            // report a cancelled coroutine as a rejected update and break
            // structured concurrency for every caller upstream.
            throw e
        } catch (e: Exception) {
                    Log.e(TAG, "Failed to send action event", e)
                }
            }
        }
    }

    private fun applyTheme(prefs: MutablePreferences, theme: Map<String, Any?>) {
        (theme["backgroundColor"] as? Number)?.let { prefs[backgroundColorKey] = it.toInt() }
        (theme["textColor"] as? Number)?.let { prefs[textColorKey] = it.toInt() }
        (theme["secondaryTextColor"] as? Number)?.let { prefs[secondaryTextColorKey] = it.toInt() }
        (theme["accentColor"] as? Number)?.let { prefs[accentColorKey] = it.toInt() }
        (theme["borderRadius"] as? Number)?.let { prefs[borderRadiusKey] = it.toFloat() }
        (theme["isDark"] as? Boolean)?.let { prefs[isDarkKey] = it }
    }

    /**
     * Serializes list items to JSON string.
     */
    private fun serializeItems(items: List<Map<String, Any?>>): String {
        return try {
            gson.toJson(items)
        } catch (e: CancellationException) {
            // Cancellation is not an update failure. Swallowing it here would
            // report a cancelled coroutine as a rejected update and break
            // structured concurrency for every caller upstream.
            throw e
        } catch (e: Exception) {
            Log.e(TAG, "Failed to serialize items", e)
            "[]"
        }
    }

    /**
     * Deserializes list items from JSON string.
     */
    fun deserializeItems(json: String): List<Map<String, Any?>> {
        return try {
            if (json.isEmpty() || json == "[]") {
                emptyList()
            } else {
                val type = object : TypeToken<List<Map<String, Any?>>>() {}.type
                gson.fromJson(json, type) ?: emptyList()
            }
        } catch (e: CancellationException) {
            // Cancellation is not an update failure. Swallowing it here would
            // report a cancelled coroutine as a rejected update and break
            // structured concurrency for every caller upstream.
            throw e
        } catch (e: Exception) {
            Log.e(TAG, "Failed to deserialize items", e)
            emptyList()
        }
    }

    /**
     * Tracks a widget ID as active.
     */
    private fun trackWidgetId(context: Context, widgetId: String) {
        synchronized(activeWidgetIds) {
            activeWidgetIds.add(widgetId)
        }
        persistActiveWidgetIds(context)
    }

    /**
     * Removes a widget ID from active tracking.
     */
    fun removeWidgetId(context: Context, widgetId: String) {
        synchronized(activeWidgetIds) {
            activeWidgetIds.remove(widgetId)
        }
        persistActiveWidgetIds(context)
    }

    /**
     * Persists active widget IDs to SharedPreferences.
     */
    private fun persistActiveWidgetIds(context: Context) {
        scope.launch {
            try {
                val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                val json = synchronized(activeWidgetIds) {
                    gson.toJson(activeWidgetIds.toList())
                }
                prefs.edit().putString(ACTIVE_WIDGETS_KEY, json).apply()
            } catch (e: CancellationException) {
            // Cancellation is not an update failure. Swallowing it here would
            // report a cancelled coroutine as a rejected update and break
            // structured concurrency for every caller upstream.
            throw e
        } catch (e: Exception) {
                Log.e(TAG, "Failed to persist active widget IDs", e)
            }
        }
    }

    /**
     * Loads active widget IDs from SharedPreferences.
     */
    private fun loadActiveWidgetIds(context: Context) {
        try {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val json = prefs.getString(ACTIVE_WIDGETS_KEY, "[]") ?: "[]"
            val type = object : TypeToken<List<String>>() {}.type
            val ids: List<String> = gson.fromJson(json, type) ?: emptyList()
            synchronized(activeWidgetIds) {
                activeWidgetIds.clear()
                activeWidgetIds.addAll(ids)
            }
            Log.d(TAG, "Loaded ${ids.size} active widget IDs")
        } catch (e: CancellationException) {
            // Cancellation is not an update failure. Swallowing it here would
            // report a cancelled coroutine as a rejected update and break
            // structured concurrency for every caller upstream.
            throw e
        } catch (e: Exception) {
            Log.e(TAG, "Failed to load active widget IDs", e)
        }
    }

    /**
     * Renders a chart as a bitmap and returns it as a base64-encoded PNG string.
     * Supports line, bar, and sparkline chart types.
     */
    private fun renderChartBitmap(
        dataPoints: List<Float>,
        chartType: String,
        chartColor: Int,
        isDark: Boolean
    ): String {
        if (dataPoints.isEmpty()) return ""

        val width = 600
        val height = 300
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)

        // Background is transparent so the widget background shows through
        canvas.drawColor(android.graphics.Color.TRANSPARENT)

        val paint = Paint().apply {
            isAntiAlias = true
            color = chartColor
            strokeWidth = 4f
        }

        val minVal = dataPoints.min()
        val maxVal = dataPoints.max()
        val range = if (maxVal - minVal == 0f) 1f else maxVal - minVal

        val paddingLeft = 16f
        val paddingRight = 16f
        val paddingTop = 16f
        val paddingBottom = 16f
        val chartWidth = width - paddingLeft - paddingRight
        val chartHeight = height - paddingTop - paddingBottom

        // Draw grid lines
        val gridPaint = Paint().apply {
            isAntiAlias = true
            color = if (isDark) 0x33FFFFFF else 0x33000000
            strokeWidth = 1f
            style = Paint.Style.STROKE
        }
        for (i in 0..4) {
            val y = paddingTop + chartHeight * i / 4f
            canvas.drawLine(paddingLeft, y, width - paddingRight, y, gridPaint)
        }

        when (chartType) {
            "bar" -> {
                val barWidth = chartWidth / dataPoints.size * 0.7f
                val gap = chartWidth / dataPoints.size * 0.3f

                dataPoints.forEachIndexed { index, value ->
                    val normalizedHeight = ((value - minVal) / range) * chartHeight
                    val x = paddingLeft + index * (barWidth + gap)
                    val top = paddingTop + chartHeight - normalizedHeight
                    val bottom = paddingTop + chartHeight

                    paint.style = Paint.Style.FILL
                    paint.alpha = 200
                    canvas.drawRect(x, top, x + barWidth, bottom, paint)
                    paint.alpha = 255
                }
            }
            "sparkline" -> {
                // Sparkline: thin line with area fill
                paint.style = Paint.Style.STROKE
                paint.strokeWidth = 3f

                val path = Path()
                val fillPath = Path()

                dataPoints.forEachIndexed { index, value ->
                    val x = paddingLeft + (index.toFloat() / (dataPoints.size - 1).coerceAtLeast(1)) * chartWidth
                    val normalizedY = ((value - minVal) / range) * chartHeight
                    val y = paddingTop + chartHeight - normalizedY

                    if (index == 0) {
                        path.moveTo(x, y)
                        fillPath.moveTo(x, paddingTop + chartHeight)
                        fillPath.lineTo(x, y)
                    } else {
                        path.lineTo(x, y)
                        fillPath.lineTo(x, y)
                    }
                }

                // Area fill
                val lastX = paddingLeft + chartWidth
                fillPath.lineTo(lastX, paddingTop + chartHeight)
                fillPath.close()

                val fillPaint = Paint().apply {
                    isAntiAlias = true
                    color = chartColor
                    alpha = 40
                    style = Paint.Style.FILL
                }
                canvas.drawPath(fillPath, fillPaint)

                // Line stroke
                canvas.drawPath(path, paint)
            }
            else -> {
                // Line chart (default)
                paint.style = Paint.Style.STROKE
                paint.strokeWidth = 4f
                paint.strokeCap = Paint.Cap.ROUND
                paint.strokeJoin = Paint.Join.ROUND

                val path = Path()

                dataPoints.forEachIndexed { index, value ->
                    val x = paddingLeft + (index.toFloat() / (dataPoints.size - 1).coerceAtLeast(1)) * chartWidth
                    val normalizedY = ((value - minVal) / range) * chartHeight
                    val y = paddingTop + chartHeight - normalizedY

                    if (index == 0) {
                        path.moveTo(x, y)
                    } else {
                        path.lineTo(x, y)
                    }
                }

                canvas.drawPath(path, paint)

                // Draw data point dots
                val dotPaint = Paint().apply {
                    isAntiAlias = true
                    color = chartColor
                    style = Paint.Style.FILL
                }
                dataPoints.forEachIndexed { index, value ->
                    val x = paddingLeft + (index.toFloat() / (dataPoints.size - 1).coerceAtLeast(1)) * chartWidth
                    val normalizedY = ((value - minVal) / range) * chartHeight
                    val y = paddingTop + chartHeight - normalizedY
                    canvas.drawCircle(x, y, 5f, dotPaint)
                }
            }
        }

        return bitmapToBase64(bitmap)
    }

    /**
     * Renders a radial gauge as a bitmap and returns it as a base64-encoded PNG string.
     */
    private fun renderGaugeBitmap(
        progress: Float,
        gaugeColor: Int,
        trackColor: Int,
        valueText: String,
        minLabel: String,
        maxLabel: String,
        isDark: Boolean
    ): String {
        val size = 400
        val bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)

        canvas.drawColor(android.graphics.Color.TRANSPARENT)

        val strokeWidth = 28f
        val padding = strokeWidth / 2 + 20f
        val rect = RectF(padding, padding, size - padding, size - padding)

        // Arc angles: start from bottom-left (135 degrees), sweep 270 degrees total
        val startAngle = 135f
        val sweepAngle = 270f

        // Draw track arc
        val trackPaint = Paint().apply {
            isAntiAlias = true
            color = trackColor
            style = Paint.Style.STROKE
            this.strokeWidth = strokeWidth
            strokeCap = Paint.Cap.ROUND
        }
        canvas.drawArc(rect, startAngle, sweepAngle, false, trackPaint)

        // Draw progress arc
        val progressPaint = Paint().apply {
            isAntiAlias = true
            color = gaugeColor
            style = Paint.Style.STROKE
            this.strokeWidth = strokeWidth
            strokeCap = Paint.Cap.ROUND
        }
        val progressSweep = sweepAngle * progress.coerceIn(0f, 1f)
        canvas.drawArc(rect, startAngle, progressSweep, false, progressPaint)

        // Draw value text in center
        val valuePaint = Paint().apply {
            isAntiAlias = true
            color = if (isDark) 0xFFFFFFFF.toInt() else 0xFF212121.toInt()
            textSize = 56f
            textAlign = Paint.Align.CENTER
            isFakeBoldText = true
        }
        val textY = size / 2f + 20f
        canvas.drawText(valueText, size / 2f, textY, valuePaint)

        // Draw min/max labels
        val labelPaint = Paint().apply {
            isAntiAlias = true
            color = if (isDark) 0xFFB0B0B0.toInt() else 0xFF757575.toInt()
            textSize = 28f
            textAlign = Paint.Align.CENTER
        }
        // Min label at bottom-left of arc
        val labelY = size - 20f
        canvas.drawText(minLabel, padding + strokeWidth, labelY, labelPaint)
        // Max label at bottom-right of arc
        canvas.drawText(maxLabel, size - padding - strokeWidth, labelY, labelPaint)

        return bitmapToBase64(bitmap)
    }

    /**
     * Converts a Bitmap to a base64-encoded PNG string.
     */
    private fun bitmapToBase64(bitmap: Bitmap): String {
        return try {
            val outputStream = ByteArrayOutputStream()
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, outputStream)
            val bytes = outputStream.toByteArray()
            bitmap.recycle()
            Base64.encodeToString(bytes, Base64.NO_WRAP)
        } catch (e: CancellationException) {
            // Cancellation is not an update failure. Swallowing it here would
            // report a cancelled coroutine as a rejected update and break
            // structured concurrency for every caller upstream.
            throw e
        } catch (e: Exception) {
            Log.e(TAG, "Failed to encode bitmap to base64", e)
            ""
        }
    }
}
