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
            name: "com.example.glance_widget/methods",
            binaryMessenger: registrar.messenger()
        )
        let eventChannel = FlutterEventChannel(
            name: "com.example.glance_widget/events",
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
        case "updateSimpleWidget":
            handleUpdateSimpleWidget(call, result: result)
        case "updateProgressWidget":
            handleUpdateProgressWidget(call, result: result)
        case "updateListWidget":
            handleUpdateListWidget(call, result: result)
        case "setGlobalTheme":
            handleSetGlobalTheme(call, result: result)
        case "forceRefreshAll":
            handleForceRefreshAll(result: result)
        case "getActiveWidgetIds":
            handleGetActiveWidgetIds(result: result)
        case "getWidgetPushToken":
            handleGetWidgetPushToken(result: result)
        case "isWidgetPushSupported":
            handleIsWidgetPushSupported(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Method Handlers

    private func handleUpdateSimpleWidget(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let widgetId = args["widgetId"] as? String,
              let data = args["data"] as? [String: Any] else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing widgetId or data", details: nil))
            return
        }

        let theme = args["theme"] as? [String: Any]
        widgetManager.updateSimpleWidget(widgetId: widgetId, data: data, theme: theme)
        result(true)
    }

    private func handleUpdateProgressWidget(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let widgetId = args["widgetId"] as? String,
              let data = args["data"] as? [String: Any] else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing widgetId or data", details: nil))
            return
        }

        let theme = args["theme"] as? [String: Any]
        widgetManager.updateProgressWidget(widgetId: widgetId, data: data, theme: theme)
        result(true)
    }

    private func handleUpdateListWidget(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let widgetId = args["widgetId"] as? String,
              let data = args["data"] as? [String: Any] else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing widgetId or data", details: nil))
            return
        }

        let theme = args["theme"] as? [String: Any]
        widgetManager.updateListWidget(widgetId: widgetId, data: data, theme: theme)
        result(true)
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

    // MARK: - FlutterStreamHandler

    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        widgetManager.setEventSink(events)
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
