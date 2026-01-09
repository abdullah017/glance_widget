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
