package dev.glance.widget.android

import android.content.Context
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch

/**
 * GlanceWidgetPlugin - Flutter plugin for Jetpack Glance widgets.
 */
class GlanceWidgetPlugin : FlutterPlugin, MethodCallHandler, EventChannel.StreamHandler {
    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private lateinit var context: Context
    private var eventSink: EventChannel.EventSink? = null

    /**
     * Method channel replies must be delivered on the main thread, so this scope
     * is deliberately main-dispatched even though the work it awaits is not.
     * A [SupervisorJob] keeps one failed reply from cancelling the rest.
     */
    private val replyScope = CoroutineScope(Dispatchers.Main.immediate + SupervisorJob())

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext

        methodChannel = MethodChannel(
            binding.binaryMessenger,
            "dev.glance.widget/methods"
        )
        methodChannel.setMethodCallHandler(this)

        eventChannel = EventChannel(
            binding.binaryMessenger,
            "dev.glance.widget/events"
        )
        eventChannel.setStreamHandler(this)

        // Initialize the widget manager
        GlanceWidgetManager.initialize(context, eventSink)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        replyScope.cancel()
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        eventSink = null
        GlanceWidgetManager.cleanup()
    }

    /**
     * Runs [update] and answers the Dart caller with what it actually returned.
     *
     * The fire-and-forget `GlanceWidgetManager.updateXWidget` helpers compute an
     * [UpdateResult] and drop it on the floor, so every update used to report
     * success even when no widget instance existed to update. Everything routed
     * through here reports the real outcome instead.
     */
    private fun replyWith(result: Result, update: suspend () -> UpdateResult) {
        replyScope.launch {
            val outcome = try {
                update()
            } catch (e: CancellationException) {
                throw e
            } catch (e: Throwable) {
                UpdateResult.Error(
                    UpdateResult.ERROR_UPDATE_FAILED,
                    e.message ?: e.toString()
                )
            }
            when (outcome) {
                is UpdateResult.Success -> result.success(true)
                is UpdateResult.Error -> result.error(outcome.code, outcome.message, null)
            }
        }
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "updateSimpleWidget" -> {
                val widgetId = call.argument<String>("widgetId")
                val data = call.argument<Map<String, Any?>>("data")
                val theme = call.argument<Map<String, Any?>>("theme")

                if (widgetId != null && data != null) {
                    replyWith(result) {
                        GlanceWidgetManager.updateSimpleWidgetWithResult(
                            context, widgetId, data, theme
                        )
                    }
                } else {
                    result.error("INVALID_ARGS", "Missing widgetId or data", null)
                }
            }

            "updateProgressWidget" -> {
                val widgetId = call.argument<String>("widgetId")
                val data = call.argument<Map<String, Any?>>("data")
                val theme = call.argument<Map<String, Any?>>("theme")

                if (widgetId != null && data != null) {
                    replyWith(result) {
                        GlanceWidgetManager.updateProgressWidgetWithResult(
                            context, widgetId, data, theme
                        )
                    }
                } else {
                    result.error("INVALID_ARGS", "Missing widgetId or data", null)
                }
            }

            "updateListWidget" -> {
                val widgetId = call.argument<String>("widgetId")
                val data = call.argument<Map<String, Any?>>("data")
                val theme = call.argument<Map<String, Any?>>("theme")

                if (widgetId != null && data != null) {
                    replyWith(result) {
                        GlanceWidgetManager.updateListWidgetWithResult(
                            context, widgetId, data, theme
                        )
                    }
                } else {
                    result.error("INVALID_ARGS", "Missing widgetId or data", null)
                }
            }

            "updateCalendarWidget" -> {
                val widgetId = call.argument<String>("widgetId")
                val data = call.argument<Map<String, Any?>>("data")
                val theme = call.argument<Map<String, Any?>>("theme")

                if (widgetId != null && data != null) {
                    replyWith(result) {
                        GlanceWidgetManager.updateCalendarWidgetWithResult(
                            context, widgetId, data, theme
                        )
                    }
                } else {
                    result.error("INVALID_ARGS", "Missing widgetId or data", null)
                }
            }

            "updateImageWidget" -> {
                val widgetId = call.argument<String>("widgetId")
                val data = call.argument<Map<String, Any?>>("data")
                val theme = call.argument<Map<String, Any?>>("theme")

                if (widgetId != null && data != null) {
                    replyWith(result) {
                        GlanceWidgetManager.updateImageWidgetWithResult(
                            context, widgetId, data, theme
                        )
                    }
                } else {
                    result.error("INVALID_ARGS", "Missing widgetId or data", null)
                }
            }

            "updateChartWidget" -> {
                val widgetId = call.argument<String>("widgetId")
                val data = call.argument<Map<String, Any?>>("data")
                val theme = call.argument<Map<String, Any?>>("theme")

                if (widgetId != null && data != null) {
                    replyWith(result) {
                        GlanceWidgetManager.updateChartWidgetWithResult(
                            context, widgetId, data, theme
                        )
                    }
                } else {
                    result.error("INVALID_ARGS", "Missing widgetId or data", null)
                }
            }

            "updateGaugeWidget" -> {
                val widgetId = call.argument<String>("widgetId")
                val data = call.argument<Map<String, Any?>>("data")
                val theme = call.argument<Map<String, Any?>>("theme")

                if (widgetId != null && data != null) {
                    replyWith(result) {
                        GlanceWidgetManager.updateGaugeWidgetWithResult(
                            context, widgetId, data, theme
                        )
                    }
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
