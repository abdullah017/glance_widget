import Flutter
import UIKit
import WidgetKit

/// Flutter plugin for iOS home screen widgets using WidgetKit.
///
/// This plugin provides the native iOS implementation for the glance_widget package,
/// enabling Flutter apps to create and update home screen widgets.
public class GlanceWidgetIosPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    private var eventSink: FlutterEventSink?
    private let widgetManager: GlanceWidgetManager

    override init() {
        self.widgetManager = GlanceWidgetManager.shared
        super.init()
    }

    public static func register(with registrar: FlutterPluginRegistrar) {
        let methodChannel = FlutterMethodChannel(
            name: "dev.glance.widget/methods",
            binaryMessenger: registrar.messenger()
        )
        let eventChannel = FlutterEventChannel(
            name: "dev.glance.widget/events",
            binaryMessenger: registrar.messenger()
        )

        let instance = GlanceWidgetIosPlugin()
        registrar.addMethodCallDelegate(instance, channel: methodChannel)
        eventChannel.setStreamHandler(instance)

        // Set up URL handling for widget taps
        registrar.addApplicationDelegate(instance)
    }

    // MARK: - FlutterPlugin

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "updateBatch":
            handleUpdateBatch(call, result: result)
        case "updateSimpleWidget":
            handleUpdateSimpleWidget(call, result: result)
        case "updateProgressWidget":
            handleUpdateProgressWidget(call, result: result)
        case "updateListWidget":
            handleUpdateListWidget(call, result: result)
        case "updateCalendarWidget":
            handleUpdateCalendarWidget(call, result: result)
        case "updateImageWidget":
            handleUpdateImageWidget(call, result: result)
        case "updateChartWidget":
            handleUpdateChartWidget(call, result: result)
        case "updateGaugeWidget":
            handleUpdateGaugeWidget(call, result: result)
        case "setGlobalTheme":
            handleSetGlobalTheme(call, result: result)
        case "forceRefreshAll":
            handleForceRefreshAll(result: result)
        case "getActiveWidgetIds":
            handleGetActiveWidgetIds(result: result)
        case "forgetWidget":
            handleForgetWidget(call, result: result)
        case "getWidgetPushToken":
            handleGetWidgetPushToken(result: result)
        case "isWidgetPushSupported":
            handleIsWidgetPushSupported(result: result)
        case "configureTimelineRefresh":
            handleConfigureTimelineRefresh(call, result: result)
        case "cancelTimelineRefresh":
            handleCancelTimelineRefresh(call, result: result)
        case "completeWidgetConfiguration":
            // iOS handles configuration differently through the system.
            result(true)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Method Handlers

    /// Answers the Dart caller with what the manager actually returned.
    ///
    /// The fire-and-forget `updateXWidget` helpers discard their `GlanceResult`,
    /// so every update used to report success even when App Group storage was
    /// unreachable and nothing was written. Everything routed through here
    /// reports the real outcome instead.
    private func reply(_ result: @escaping FlutterResult, _ outcome: GlanceResult) {
        switch outcome {
        case .success:
            result(true)
        case .failure(let code, let message):
            result(FlutterError(code: code, message: message, details: nil))
        }
    }

    // MARK: - Batch

    /// Entries are applied one after another rather than at once. They all
    /// write to the same App Group container, and the win a batch is after is
    /// the single channel round trip, not parallelism.
    private let batchQueue = DispatchQueue(label: "dev.glance.widget.batch")

    private func handleUpdateBatch(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch GlanceBatchRequest.parse(call.arguments) {
        case .invalid(let reason):
            result(FlutterError(code: "INVALID_ARGS", message: reason, details: nil))
        case .ok(let entries):
            applyBatch(entries, from: 0, failures: [], result: result)
        }
    }

    /// Applies [entries] from [index] on, collecting the ones that failed.
    ///
    /// A batch does not stop at the first failure. One widget missing from the
    /// home screen is not a reason to leave the rest showing stale data, so
    /// every entry is attempted and the failures travel back together; Dart
    /// turns a non-empty list into a `GlanceWidgetBatchException`.
    ///
    /// Each step hops through `batchQueue` rather than calling the next one
    /// directly. Six of the seven templates finish synchronously, so a direct
    /// call would put the whole batch on one stack -- fine for twenty widgets
    /// and not fine for a caller that sends thousands.
    private func applyBatch(
        _ entries: [GlanceBatchEntry],
        from index: Int,
        failures: [[String: Any]],
        result: @escaping FlutterResult
    ) {
        guard index < entries.count else {
            // A FlutterResult must be called on the main thread, and the image
            // template answers from a background queue.
            DispatchQueue.main.async { result(["failures": failures]) }
            return
        }

        let entry = entries[index]
        apply(entry) { outcome in
            var collected = failures
            if case .failure(let code, let message) = outcome {
                collected.append([
                    "widgetId": entry.widgetId,
                    "message": message,
                    "code": code,
                ])
            }
            self.batchQueue.async {
                self.applyBatch(entries, from: index + 1, failures: collected, result: result)
            }
        }
    }

    /// Applies one entry, choosing the template handler by name.
    ///
    /// A template this build does not know is that one widget's failure rather
    /// than the batch's: a newer Dart side talking to an older plugin should
    /// still get its other widgets updated.
    private func apply(_ entry: GlanceBatchEntry, completion: @escaping (GlanceResult) -> Void) {
        switch entry.template {
        case "simple":
            completion(widgetManager.updateSimpleWidgetWithResult(
                widgetId: entry.widgetId, data: entry.data, theme: entry.theme))
        case "progress":
            completion(widgetManager.updateProgressWidgetWithResult(
                widgetId: entry.widgetId, data: entry.data, theme: entry.theme))
        case "list":
            completion(widgetManager.updateListWidgetWithResult(
                widgetId: entry.widgetId, data: entry.data, theme: entry.theme))
        case "calendar":
            completion(widgetManager.updateCalendarWidgetWithResult(
                widgetId: entry.widgetId, data: entry.data, theme: entry.theme))
        case "chart":
            completion(widgetManager.updateChartWidgetWithResult(
                widgetId: entry.widgetId, data: entry.data, theme: entry.theme))
        case "gauge":
            completion(widgetManager.updateGaugeWidgetWithResult(
                widgetId: entry.widgetId, data: entry.data, theme: entry.theme))
        case "image":
            // The only template that needs the network, so the only one that
            // cannot answer synchronously.
            widgetManager.updateImageWidgetWithResult(
                widgetId: entry.widgetId, data: entry.data, theme: entry.theme,
                completion: completion)
        default:
            completion(.failure(
                code: "UNKNOWN_TEMPLATE",
                message: "This version of glance_widget_ios does not know the template '\(entry.template)'"))
        }
    }

    private func handleUpdateSimpleWidget(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let widgetId = args["widgetId"] as? String,
              let data = args["data"] as? [String: Any] else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing widgetId or data", details: nil))
            return
        }

        let theme = args["theme"] as? [String: Any]
        reply(result, widgetManager.updateSimpleWidgetWithResult(
            widgetId: widgetId, data: data, theme: theme
        ))
    }

    private func handleUpdateProgressWidget(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let widgetId = args["widgetId"] as? String,
              let data = args["data"] as? [String: Any] else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing widgetId or data", details: nil))
            return
        }

        let theme = args["theme"] as? [String: Any]
        reply(result, widgetManager.updateProgressWidgetWithResult(
            widgetId: widgetId, data: data, theme: theme
        ))
    }

    private func handleUpdateListWidget(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let widgetId = args["widgetId"] as? String,
              let data = args["data"] as? [String: Any] else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing widgetId or data", details: nil))
            return
        }

        let theme = args["theme"] as? [String: Any]
        reply(result, widgetManager.updateListWidgetWithResult(
            widgetId: widgetId, data: data, theme: theme
        ))
    }

    private func handleUpdateCalendarWidget(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let widgetId = args["widgetId"] as? String,
              let data = args["data"] as? [String: Any] else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing widgetId or data", details: nil))
            return
        }

        let theme = args["theme"] as? [String: Any]
        reply(result, widgetManager.updateCalendarWidgetWithResult(
            widgetId: widgetId, data: data, theme: theme
        ))
    }

    private func handleUpdateImageWidget(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let widgetId = args["widgetId"] as? String,
              let data = args["data"] as? [String: Any] else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing widgetId or data", details: nil))
            return
        }

        let theme = args["theme"] as? [String: Any]
        // Answers on a background queue once the image has been fetched and
        // downsampled, so the reply is hopped back to the main thread: a
        // FlutterResult must be called there.
        widgetManager.updateImageWidgetWithResult(
            widgetId: widgetId, data: data, theme: theme
        ) { outcome in
            DispatchQueue.main.async { self.reply(result, outcome) }
        }
    }

    private func handleUpdateChartWidget(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let widgetId = args["widgetId"] as? String,
              let data = args["data"] as? [String: Any] else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing widgetId or data", details: nil))
            return
        }

        let theme = args["theme"] as? [String: Any]
        reply(result, widgetManager.updateChartWidgetWithResult(
            widgetId: widgetId, data: data, theme: theme
        ))
    }

    private func handleUpdateGaugeWidget(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let widgetId = args["widgetId"] as? String,
              let data = args["data"] as? [String: Any] else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing widgetId or data", details: nil))
            return
        }

        let theme = args["theme"] as? [String: Any]
        reply(result, widgetManager.updateGaugeWidgetWithResult(
            widgetId: widgetId, data: data, theme: theme
        ))
    }

    private func handleSetGlobalTheme(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let theme = call.arguments as? [String: Any] else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing theme data", details: nil))
            return
        }

        widgetManager.setGlobalTheme(theme)
        result(true)
    }

    private func handleForceRefreshAll(result: @escaping FlutterResult) {
        // This is the key insight from WWDC 2025:
        // When called while app is in foreground, this has NO budget limit!
        widgetManager.forceRefreshAll()
        result(true)
    }

    private func handleGetActiveWidgetIds(result: @escaping FlutterResult) {
        let ids = widgetManager.getActiveWidgetIds()
        result(ids)
    }

    private func handleForgetWidget(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let widgetId = args["widgetId"] as? String,
              !widgetId.isEmpty else {
            result(FlutterError(
                code: "INVALID_ARGUMENTS",
                message: "forgetWidget requires a non-empty widgetId",
                details: nil
            ))
            return
        }

        widgetManager.forgetWidget(widgetId)
        result(true)
    }

    private func handleGetWidgetPushToken(result: @escaping FlutterResult) {
        let token = widgetManager.getWidgetPushToken()
        result(token)
    }

    private func handleIsWidgetPushSupported(result: @escaping FlutterResult) {
        // Widget Push Updates are only available on iOS 26+
        if #available(iOS 26.0, *) {
            result(true)
        } else {
            result(false)
        }
    }

    private func handleConfigureTimelineRefresh(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let widgetId = args["widgetId"] as? String,
              let intervalMinutes = args["intervalMinutes"] as? Int else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing widgetId or intervalMinutes", details: nil))
            return
        }

        widgetManager.configureTimelineRefresh(widgetId: widgetId, intervalMinutes: intervalMinutes)
        result(true)
    }

    private func handleCancelTimelineRefresh(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let widgetId = args["widgetId"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing widgetId", details: nil))
            return
        }

        widgetManager.cancelTimelineRefresh(widgetId: widgetId)
        result(true)
    }

    // MARK: - FlutterStreamHandler

    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        widgetManager.setEventSink(events)
        // Anything the widget extension handled while the app was closed has
        // been waiting for a listener; this is the first moment it has one.
        widgetManager.drainPendingActions()
        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        widgetManager.setEventSink(nil)
        return nil
    }
}

// MARK: - URL Handling for Widget Actions

extension GlanceWidgetIosPlugin {
    /// Drains queued widget interactions each time the app comes forward.
    ///
    /// `onListen` covers the launch; this covers the app being backgrounded,
    /// the user ticking a box on the lock screen, and the app being resumed
    /// with the same Dart listener still attached.
    public func applicationDidBecomeActive(_ application: UIApplication) {
        widgetManager.drainPendingActions()
    }

    public func application(
        _ application: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        // Handle URLs from widget taps: glancewidget://action?widgetId=xxx&type=tap
        guard url.scheme == "glancewidget",
              url.host == "action" else {
            return false
        }

        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        var params: [String: Any] = [:]

        components?.queryItems?.forEach { item in
            if let value = item.value {
                // Try to parse as Int for index values
                if let intValue = Int(value) {
                    params[item.name] = intValue
                } else if value == "true" {
                    params[item.name] = true
                } else if value == "false" {
                    params[item.name] = false
                } else {
                    params[item.name] = value
                }
            }
        }

        if let widgetId = params["widgetId"] as? String,
           let actionType = params["type"] as? String {

            // Build payload from remaining params
            var payload: [String: Any] = [:]
            for (key, value) in params where key != "widgetId" && key != "type" {
                payload[key] = value
            }

            widgetManager.sendActionEvent(
                widgetId: widgetId,
                actionType: actionType,
                payload: payload.isEmpty ? nil : payload
            )
        }

        return true
    }
}
