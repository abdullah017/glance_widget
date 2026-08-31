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
import kotlinx.coroutines.withContext

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

    /**
     * Applies one entry of a batch, choosing the template handler by name.
     *
     * A template this build does not know is reported as that one widget's
     * failure rather than the batch's: a newer Dart side talking to an older
     * plugin should still get its other nineteen widgets updated.
     */
    private suspend fun applyBatchEntry(entry: BatchEntry): UpdateResult =
        when (entry.template) {
            "simple" -> GlanceWidgetManager.updateSimpleWidgetWithResult(
                context, entry.widgetId, entry.data, entry.theme
            )
            "progress" -> GlanceWidgetManager.updateProgressWidgetWithResult(
                context, entry.widgetId, entry.data, entry.theme
            )
            "list" -> GlanceWidgetManager.updateListWidgetWithResult(
                context, entry.widgetId, entry.data, entry.theme
            )
            "image" -> GlanceWidgetManager.updateImageWidgetWithResult(
                context, entry.widgetId, entry.data, entry.theme
            )
            "chart" -> GlanceWidgetManager.updateChartWidgetWithResult(
                context, entry.widgetId, entry.data, entry.theme
            )
            "calendar" -> GlanceWidgetManager.updateCalendarWidgetWithResult(
                context, entry.widgetId, entry.data, entry.theme
            )
            "gauge" -> GlanceWidgetManager.updateGaugeWidgetWithResult(
                context, entry.widgetId, entry.data, entry.theme
            )
            else -> UpdateResult.Error(
                "UNKNOWN_TEMPLATE",
                "This version of glance_widget_android does not know the template '${entry.template}'"
            )
        }

    /**
     * Applies every entry and answers with the ones that failed.
     *
     * A batch does not stop at the first failure. One widget missing from the
     * home screen is not a reason to leave the rest showing stale data, so the
     * reply carries a `failures` list and Dart turns a non-empty one into a
     * `GlanceWidgetBatchException`.
     */
    private fun replyWithBatch(result: Result, entries: List<BatchEntry>) {
        replyScope.launch {
            // The loop runs off the main thread even though the work inside it
            // suspends on its own. `replyScope` is `Dispatchers.Main.immediate`
            // so that a reply lands on the platform thread, which a single
            // update wants; a batch of twenty would otherwise resume on the
            // main thread twenty times and build each payload there.
            val failures = withContext(Dispatchers.Default) {
                val collected = ArrayList<Map<String, Any?>>()
                for (entry in entries) {
                    val outcome = try {
                        applyBatchEntry(entry)
                    } catch (e: CancellationException) {
                        throw e
                    } catch (e: Throwable) {
                        UpdateResult.Error(
                            UpdateResult.ERROR_UPDATE_FAILED,
                            e.message ?: e.toString()
                        )
                    }
                    if (outcome is UpdateResult.Error) {
                        collected.add(
                            mapOf(
                                "widgetId" to entry.widgetId,
                                "message" to outcome.message,
                                "code" to outcome.code
                            )
                        )
                    }
                }
                collected
            }
            // Back on the main thread: a MethodChannel reply has to be.
            result.success(mapOf("failures" to failures))
        }
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "updateBatch" -> {
                when (val parsed = BatchRequest.parse(call.arguments)) {
                    is BatchParse.Invalid ->
                        result.error("INVALID_ARGS", parsed.reason, null)
                    is BatchParse.Ok -> replyWithBatch(result, parsed.entries)
                }
            }

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

            "forgetWidget" -> {
                val widgetId = call.argument<String>("widgetId")
                if (widgetId.isNullOrEmpty()) {
                    result.error(
                        "INVALID_ARGUMENTS",
                        "forgetWidget requires a non-empty widgetId",
                        null
                    )
                } else {
                    GlanceWidgetManager.forgetWidget(context, widgetId)
                    result.success(true)
                }
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
        GlanceWidgetManager.setEventSink(events, context)
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
        GlanceWidgetManager.setEventSink(null)
    }
}
