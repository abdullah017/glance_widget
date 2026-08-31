package dev.glance.widget.android

import android.content.Context
import android.util.Log
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONArray
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL

/**
 * CoroutineWorker that fetches data from API and updates widgets.
 *
 * This worker runs in the background even when the app is closed,
 * ensuring widgets stay up-to-date with the latest data.
 */
class GlanceWidgetWorker(
    context: Context,
    params: WorkerParameters
) : CoroutineWorker(context, params) {

    companion object {
        private const val TAG = "GlanceWidgetWorker"
        private const val CONNECT_TIMEOUT = 15000 // 15 seconds
        private const val READ_TIMEOUT = 15000 // 15 seconds
    }

    override suspend fun doWork(): Result {
        val widgetId = inputData.getString("widgetId")
        if (widgetId == null) {
            Log.e(TAG, "Widget ID not provided")
            return Result.failure()
        }

        Log.d(TAG, "Starting background update for widget: $widgetId")

        val config = BackgroundUpdateConfig.load(applicationContext, widgetId)
        if (config == null) {
            Log.e(TAG, "No configuration found for widget: $widgetId")
            return Result.failure()
        }

        if (!config.enabled) {
            Log.d(TAG, "Background updates disabled for widget: $widgetId")
            return Result.success()
        }

        return try {
            // 1. Fetch data from API
            val response = fetchData(config.apiUrl, config.headers)
            Log.d(TAG, "API response received for widget: $widgetId")

            // 2. Parse response using JSONPath
            val data = parseResponse(response, config)
            Log.d(TAG, "Parsed data for widget $widgetId: $data")

            // 3. Update widget
            updateWidget(widgetId, config.template, data, config)

            Log.d(TAG, "Background update completed successfully for widget: $widgetId")
            Result.success()
        } catch (e: Exception) {
            Log.e(TAG, "Background update failed for widget: $widgetId", e)
            // Retry on failure (up to 3 times by default)
            Result.retry()
        }
    }

    /**
     * Fetches data from the given URL with optional headers.
     */
    private suspend fun fetchData(url: String, headers: Map<String, String>): String {
        return withContext(Dispatchers.IO) {
            val connection = URL(url).openConnection() as HttpURLConnection
            try {
                connection.connectTimeout = CONNECT_TIMEOUT
                connection.readTimeout = READ_TIMEOUT
                connection.requestMethod = "GET"

                // Add custom headers
                headers.forEach { (key, value) ->
                    connection.setRequestProperty(key, value)
                }

                // Add default headers
                connection.setRequestProperty("Accept", "application/json")

                val responseCode = connection.responseCode
                if (responseCode != HttpURLConnection.HTTP_OK) {
                    throw Exception("HTTP error code: $responseCode")
                }

                connection.inputStream.bufferedReader().use { it.readText() }
            } finally {
                connection.disconnect()
            }
        }
    }

    /**
     * Parses the JSON response using simple JSONPath-like expressions.
     *
     * Supports paths like:
     * - "$.data.price" -> json.data.price
     * - "$.items[0].value" -> json.items[0].value
     * - "price" -> json.price (simple key)
     */
    private fun parseResponse(json: String, config: BackgroundUpdateConfig): Map<String, Any?> {
        val jsonObject = JSONObject(json)

        val value = extractValue(jsonObject, config.valuePath)
        val formattedValue = formatValue(value, config.valuePrefix, config.valueSuffix)

        val subtitle = config.subtitlePath?.let { path ->
            val subtitleValue = extractValue(jsonObject, path)
            formatSubtitle(subtitleValue)
        }

        return mapOf(
            "title" to config.title,
            "value" to formattedValue,
            "subtitle" to subtitle
        )
    }

    /**
     * Extracts a value from a JSONObject using a simple path expression.
     *
     * @param json The JSON object to extract from
     * @param path Path expression (e.g., "$.data.price", "data.price", "price")
     * @return The extracted value as a string, or null if not found
     */
    private fun extractValue(json: JSONObject, path: String): Any? {
        // Remove leading "$." if present
        val cleanPath = path.removePrefix("$.").removePrefix("$")

        if (cleanPath.isEmpty()) {
            return json.toString()
        }

        var current: Any = json

        // Split path by "." and "[" to handle array access
        val parts = cleanPath.split(".", "[", "]").filter { it.isNotEmpty() }

        for (part in parts) {
            current = when (current) {
                is JSONObject -> {
                    if (current.has(part)) {
                        current.get(part)
                    } else {
                        return null
                    }
                }
                is JSONArray -> {
                    val index = part.toIntOrNull()
                    if (index != null && index >= 0 && index < current.length()) {
                        current.get(index)
                    } else {
                        return null
                    }
                }
                else -> return null
            }
        }

        return current
    }

    /**
     * Formats a value with optional prefix and suffix.
     */
    private fun formatValue(value: Any?, prefix: String?, suffix: String?): String {
        if (value == null) return ""

        val strValue = when (value) {
            is Double -> {
                // Format numbers nicely
                if (value == value.toLong().toDouble()) {
                    value.toLong().toString()
                } else {
                    String.format("%.2f", value)
                }
            }
            is Number -> {
                val doubleVal = value.toDouble()
                if (doubleVal == doubleVal.toLong().toDouble()) {
                    value.toLong().toString()
                } else {
                    String.format("%.2f", doubleVal)
                }
            }
            else -> value.toString()
        }

        val prefixStr = prefix ?: ""
        val suffixStr = suffix ?: ""

        return "$prefixStr$strValue$suffixStr"
    }

    /**
     * Formats subtitle value (handles percentage changes, etc.)
     */
    private fun formatSubtitle(value: Any?): String? {
        if (value == null) return null

        return when (value) {
            is Number -> {
                val doubleVal = value.toDouble()
                val sign = if (doubleVal >= 0) "+" else ""
                "$sign${String.format("%.2f", doubleVal)}%"
            }
            else -> value.toString()
        }
    }

    /**
     * Updates the widget with the parsed data.
     */
    private suspend fun updateWidget(
        widgetId: String,
        template: String,
        data: Map<String, Any?>,
        config: BackgroundUpdateConfig
    ) {
        when (template) {
            "simple" -> {
                val result = GlanceWidgetManager.updateSimpleWidgetWithResult(
                    applicationContext,
                    widgetId,
                    data,
                    null // Theme is already set on widget
                )
                if (result is UpdateResult.Error) {
                    Log.e(TAG, "Widget update error: ${result.code} - ${result.message}")
                }
            }
            "progress" -> {
                // For progress widget, parse progress value if provided
                val progressData = data.toMutableMap()
                data["value"]?.toString()?.let { valueStr ->
                    // Try to extract numeric value for progress
                    val numericValue = valueStr.replace(Regex("[^0-9.]"), "").toDoubleOrNull()
                    if (numericValue != null) {
                        // Assume it's a percentage (0-100) and convert to 0-1
                        progressData["progress"] = (numericValue / 100.0).coerceIn(0.0, 1.0)
                    }
                }

                val result = GlanceWidgetManager.updateProgressWidgetWithResult(
                    applicationContext,
                    widgetId,
                    progressData,
                    null
                )
                if (result is UpdateResult.Error) {
                    Log.e(TAG, "Widget update error: ${result.code} - ${result.message}")
                }
            }
            "list" -> {
                // List widget needs special handling for items
                Log.w(TAG, "List widget background updates not fully supported yet")
            }
            else -> {
                Log.e(TAG, "Unknown template type: $template")
            }
        }
    }
}
