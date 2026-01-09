package com.example.glance_widget_android

import android.content.Context
import android.content.SharedPreferences
import android.util.Log
import androidx.datastore.preferences.core.*
import androidx.glance.appwidget.GlanceAppWidgetManager
import androidx.glance.appwidget.state.updateAppWidgetState
import androidx.glance.state.PreferencesGlanceStateDefinition
import com.example.glance_widget_android.templates.ListGlanceWidget
import com.example.glance_widget_android.templates.ProgressGlanceWidget
import com.example.glance_widget_android.templates.SimpleGlanceWidget
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import io.flutter.plugin.common.EventChannel
import kotlinx.coroutines.*

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

    fun setEventSink(sink: EventChannel.EventSink?) {
        synchronized(eventSinkLock) {
            eventSink = sink
            Log.d(TAG, "EventSink ${if (sink != null) "set" else "cleared"}")
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
            try {
                Log.d(TAG, "Updating simple widget: $widgetId")
                val manager = GlanceAppWidgetManager(context)
                val glanceIds = manager.getGlanceIds(SimpleGlanceWidget::class.java)
                val widget = SimpleGlanceWidget()

                if (glanceIds.isEmpty()) {
                    Log.w(TAG, "No SimpleGlanceWidget instances found")
                    return@launch
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
            } catch (e: Exception) {
                Log.e(TAG, "Failed to update simple widget: $widgetId", e)
            }
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
            try {
                Log.d(TAG, "Updating progress widget: $widgetId")
                val manager = GlanceAppWidgetManager(context)
                val glanceIds = manager.getGlanceIds(ProgressGlanceWidget::class.java)
                val widget = ProgressGlanceWidget()

                if (glanceIds.isEmpty()) {
                    Log.w(TAG, "No ProgressGlanceWidget instances found")
                    return@launch
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
            } catch (e: Exception) {
                Log.e(TAG, "Failed to update progress widget: $widgetId", e)
            }
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
            try {
                Log.d(TAG, "Updating list widget: $widgetId")
                val manager = GlanceAppWidgetManager(context)
                val glanceIds = manager.getGlanceIds(ListGlanceWidget::class.java)
                val widget = ListGlanceWidget()

                if (glanceIds.isEmpty()) {
                    Log.w(TAG, "No ListGlanceWidget instances found")
                    return@launch
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
            } catch (e: Exception) {
                Log.e(TAG, "Failed to update list widget: $widgetId", e)
            }
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
                    ListGlanceWidget::class.java to ListGlanceWidget()
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
                    ListGlanceWidget::class.java to ListGlanceWidget()
                ).forEach { (clazz, widget) ->
                    val manager = GlanceAppWidgetManager(context)
                    val glanceIds = manager.getGlanceIds(clazz)
                    glanceIds.forEach { glanceId ->
                        widget.update(context, glanceId)
                    }
                }
                Log.d(TAG, "All widgets refreshed successfully")
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
        } catch (e: Exception) {
            Log.e(TAG, "Failed to load active widget IDs", e)
        }
    }
}
