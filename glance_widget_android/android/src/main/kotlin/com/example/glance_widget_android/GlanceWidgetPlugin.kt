package com.example.glance_widget_android

import android.content.Context
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/**
 * GlanceWidgetPlugin - Flutter plugin for Jetpack Glance widgets.
 */
class GlanceWidgetPlugin : FlutterPlugin, MethodCallHandler, EventChannel.StreamHandler {
    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private lateinit var context: Context
    private var eventSink: EventChannel.EventSink? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext

        methodChannel = MethodChannel(
            binding.binaryMessenger,
            "com.example.glance_widget/methods"
        )
        methodChannel.setMethodCallHandler(this)

        eventChannel = EventChannel(
            binding.binaryMessenger,
            "com.example.glance_widget/events"
        )
        eventChannel.setStreamHandler(this)

        // Initialize the widget manager
        GlanceWidgetManager.initialize(context, eventSink)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        eventSink = null
        GlanceWidgetManager.cleanup()
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "updateSimpleWidget" -> {
                val widgetId = call.argument<String>("widgetId")
                val data = call.argument<Map<String, Any?>>("data")
                val theme = call.argument<Map<String, Any?>>("theme")

                if (widgetId != null && data != null) {
                    GlanceWidgetManager.updateSimpleWidget(context, widgetId, data, theme)
                    result.success(true)
                } else {
                    result.error("INVALID_ARGS", "Missing widgetId or data", null)
                }
            }

            "updateProgressWidget" -> {
                val widgetId = call.argument<String>("widgetId")
                val data = call.argument<Map<String, Any?>>("data")
                val theme = call.argument<Map<String, Any?>>("theme")

                if (widgetId != null && data != null) {
                    GlanceWidgetManager.updateProgressWidget(context, widgetId, data, theme)
                    result.success(true)
                } else {
                    result.error("INVALID_ARGS", "Missing widgetId or data", null)
                }
            }

            "updateListWidget" -> {
                val widgetId = call.argument<String>("widgetId")
                val data = call.argument<Map<String, Any?>>("data")
                val theme = call.argument<Map<String, Any?>>("theme")

                if (widgetId != null && data != null) {
                    GlanceWidgetManager.updateListWidget(context, widgetId, data, theme)
                    result.success(true)
                } else {
                    result.error("INVALID_ARGS", "Missing widgetId or data", null)
                }
            }

            "updateCalendarWidget" -> {
                val widgetId = call.argument<String>("widgetId")
                val data = call.argument<Map<String, Any?>>("data")
                val theme = call.argument<Map<String, Any?>>("theme")

                if (widgetId != null && data != null) {
                    GlanceWidgetManager.updateCalendarWidget(context, widgetId, data, theme)
                    result.success(true)
                } else {
                    result.error("INVALID_ARGS", "Missing widgetId or data", null)
                }
            }

            "updateImageWidget" -> {
                val widgetId = call.argument<String>("widgetId")
                val data = call.argument<Map<String, Any?>>("data")
                val theme = call.argument<Map<String, Any?>>("theme")

                if (widgetId != null && data != null) {
                    GlanceWidgetManager.updateImageWidget(context, widgetId, data, theme)
                    result.success(true)
                } else {
                    result.error("INVALID_ARGS", "Missing widgetId or data", null)
                }
            }

            "updateChartWidget" -> {
                val widgetId = call.argument<String>("widgetId")
                val data = call.argument<Map<String, Any?>>("data")
                val theme = call.argument<Map<String, Any?>>("theme")

                if (widgetId != null && data != null) {
                    GlanceWidgetManager.updateChartWidget(context, widgetId, data, theme)
                    result.success(true)
                } else {
                    result.error("INVALID_ARGS", "Missing widgetId or data", null)
                }
            }

            "updateGaugeWidget" -> {
                val widgetId = call.argument<String>("widgetId")
                val data = call.argument<Map<String, Any?>>("data")
                val theme = call.argument<Map<String, Any?>>("theme")

                if (widgetId != null && data != null) {
                    GlanceWidgetManager.updateGaugeWidget(context, widgetId, data, theme)
                    result.success(true)
                } else {
                    result.error("INVALID_ARGS", "Missing widgetId or data", null)
                }
            }

            "setGlobalTheme" -> {
                val theme = call.arguments as? Map<String, Any?>
                if (theme != null) {
                    GlanceWidgetManager.setGlobalTheme(context, theme)
                    result.success(true)
                } else {
                    result.error("INVALID_ARGS", "Missing theme data", null)
                }
            }

            "forceRefreshAll" -> {
                GlanceWidgetManager.forceRefreshAll(context)
                result.success(true)
            }

            "getActiveWidgetIds" -> {
                val ids = GlanceWidgetManager.getActiveWidgetIds(context)
                result.success(ids)
            }

            "isWidgetPushSupported" -> {
                // Widget Push Updates is an iOS 26+ only feature
                result.success(false)
            }

            "configureBackgroundUpdate" -> {
                @Suppress("UNCHECKED_CAST")
                val configMap = call.arguments as? Map<String, Any?>
                if (configMap != null) {
                    try {
                        val config = BackgroundUpdateConfig.fromMap(configMap)
                        // Save configuration
                        BackgroundUpdateConfig.save(context, config)
                        // Schedule work
                        BackgroundUpdateManager.scheduleWork(context, config)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("CONFIG_ERROR", "Failed to configure background update: ${e.message}", null)
                    }
                } else {
                    result.error("INVALID_ARGS", "Missing configuration data", null)
                }
            }

            "cancelBackgroundUpdate" -> {
                val widgetId = call.argument<String>("widgetId")
                if (widgetId != null) {
                    BackgroundUpdateManager.cancelWork(context, widgetId)
                    result.success(true)
                } else {
                    result.error("INVALID_ARGS", "Missing widgetId", null)
                }
            }

            "getBackgroundUpdateStatus" -> {
                val widgetId = call.argument<String>("widgetId")
                if (widgetId != null) {
                    val status = BackgroundUpdateManager.getStatus(context, widgetId)
                    result.success(status)
                } else {
                    result.error("INVALID_ARGS", "Missing widgetId", null)
                }
            }

            "completeWidgetConfiguration" -> {
                val widgetId = call.argument<String>("widgetId")
                if (widgetId != null) {
                    val prefs = context.getSharedPreferences("glance_widget_config", Context.MODE_PRIVATE)
                    prefs.edit().putBoolean("configured_$widgetId", true).apply()
                    result.success(true)
                } else {
                    result.error("INVALID_ARGS", "Missing widgetId", null)
                }
            }

            "testBackgroundUpdate" -> {
                val widgetId = call.argument<String>("widgetId")
                if (widgetId != null) {
                    BackgroundUpdateManager.runOnce(context, widgetId)
                    result.success(true)
                } else {
                    result.error("INVALID_ARGS", "Missing widgetId", null)
                }
            }

            else -> result.notImplemented()
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        GlanceWidgetManager.setEventSink(events)
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
        GlanceWidgetManager.setEventSink(null)
    }
}
