package com.example.glance_widget_android

import android.content.Context
import android.content.SharedPreferences
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken

/**
 * Configuration for background widget updates.
 *
 * @param widgetId Unique identifier for the widget
 * @param template Widget template type: "simple", "progress", or "list"
 * @param apiUrl API endpoint URL to fetch data from
 * @param headers HTTP headers to include in API requests
 * @param intervalMinutes Update interval in minutes (minimum 15)
 * @param title Widget title to display
 * @param valuePath JSONPath expression to extract the main value (e.g., "$.data.price")
 * @param subtitlePath Optional JSONPath expression for subtitle
 * @param valuePrefix Optional prefix for the value (e.g., "$")
 * @param valueSuffix Optional suffix for the value (e.g., "%")
 * @param enabled Whether background updates are enabled
 */
data class BackgroundUpdateConfig(
    val widgetId: String,
    val template: String,
    val apiUrl: String,
    val headers: Map<String, String> = emptyMap(),
    val intervalMinutes: Int = 15,
    val title: String,
    val valuePath: String,
    val subtitlePath: String? = null,
    val valuePrefix: String? = null,
    val valueSuffix: String? = null,
    val enabled: Boolean = true
) {
    companion object {
        private const val PREFS_NAME = "glance_widget_background_configs"
        private const val KEY_PREFIX = "config_"
        private val gson = Gson()

        /**
         * Save configuration to SharedPreferences
         */
        fun save(context: Context, config: BackgroundUpdateConfig) {
            val prefs = getPrefs(context)
            val json = gson.toJson(config)
            prefs.edit().putString("$KEY_PREFIX${config.widgetId}", json).apply()
        }

        /**
         * Load configuration from SharedPreferences
         */
        fun load(context: Context, widgetId: String): BackgroundUpdateConfig? {
            val prefs = getPrefs(context)
            val json = prefs.getString("$KEY_PREFIX$widgetId", null) ?: return null
            return try {
                gson.fromJson(json, BackgroundUpdateConfig::class.java)
            } catch (e: Exception) {
                null
            }
        }

        /**
         * Delete configuration from SharedPreferences
         */
        fun delete(context: Context, widgetId: String) {
            val prefs = getPrefs(context)
            prefs.edit().remove("$KEY_PREFIX$widgetId").apply()
        }

        /**
         * Get all saved configurations
         */
        fun getAll(context: Context): List<BackgroundUpdateConfig> {
            val prefs = getPrefs(context)
            return prefs.all.mapNotNull { (key, value) ->
                if (key.startsWith(KEY_PREFIX) && value is String) {
                    try {
                        gson.fromJson(value, BackgroundUpdateConfig::class.java)
                    } catch (e: Exception) {
                        null
                    }
                } else {
                    null
                }
            }
        }

        /**
         * Create config from Flutter method call arguments
         */
        fun fromMap(map: Map<String, Any?>): BackgroundUpdateConfig {
            @Suppress("UNCHECKED_CAST")
            return BackgroundUpdateConfig(
                widgetId = map["widgetId"] as String,
                template = map["template"] as String,
                apiUrl = map["apiUrl"] as String,
                headers = (map["headers"] as? Map<String, String>) ?: emptyMap(),
                intervalMinutes = (map["intervalMinutes"] as? Int) ?: 15,
                title = map["title"] as String,
                valuePath = map["valuePath"] as String,
                subtitlePath = map["subtitlePath"] as? String,
                valuePrefix = map["valuePrefix"] as? String,
                valueSuffix = map["valueSuffix"] as? String,
                enabled = (map["enabled"] as? Boolean) ?: true
            )
        }

        private fun getPrefs(context: Context): SharedPreferences {
            return context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        }
    }
}
