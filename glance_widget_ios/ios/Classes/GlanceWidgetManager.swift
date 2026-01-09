import Foundation
import WidgetKit

/// Manages widget data storage and updates for iOS WidgetKit widgets.
///
/// This class handles:
/// - Saving widget data to App Group storage for widget extension access
/// - Triggering widget timeline reloads
/// - Tracking active widget IDs
/// - Sending widget action events back to Flutter
///
/// ## Update Strategy
///
/// When the app is in foreground, `reloadAllTimelines()` provides instant updates
/// with NO budget limit (WWDC 2025). This is the recommended approach for real-time
/// updates while the user is actively using the app.
public class GlanceWidgetManager {
    /// Shared singleton instance
    public static let shared = GlanceWidgetManager()

    /// App Group ID for sharing data with widget extension
    /// Users must configure this in their app's entitlements
    public static var appGroupId: String = "group.com.example.glancewidget"

    private let storage: AppGroupStorage
    private var eventSink: FlutterEventSink?
    private let eventSinkLock = NSLock()
    private var activeWidgetIds: Set<String> = []

    // Storage keys
    private let simpleWidgetKeyPrefix = "simpleWidgetData_"
    private let progressWidgetKeyPrefix = "progressWidgetData_"
    private let listWidgetKeyPrefix = "listWidgetData_"
    private let globalThemeKey = "globalTheme"
    private let activeWidgetsKey = "activeWidgetIds"
    private let widgetPushTokenKey = "widgetPushToken"

    private init() {
        storage = AppGroupStorage(appGroupId: GlanceWidgetManager.appGroupId)
        loadActiveWidgetIds()
    }

    /// Sets the Flutter event sink for sending widget actions back to Flutter
    public func setEventSink(_ sink: FlutterEventSink?) {
        eventSinkLock.lock()
        defer { eventSinkLock.unlock() }
        self.eventSink = sink
    }

    // MARK: - Widget Updates

    /// Updates a Simple Widget with the given data
    public func updateSimpleWidget(widgetId: String, data: [String: Any], theme: [String: Any]?) {
        var widgetData = data
        widgetData["widgetId"] = widgetId
        widgetData["timestamp"] = Date().timeIntervalSince1970

        if let theme = theme {
            widgetData["theme"] = theme
        }

        storage.save(widgetData, forKey: "\(simpleWidgetKeyPrefix)\(widgetId)")
        trackWidgetId(widgetId)

        // Trigger widget refresh
        // When app is in foreground, this is INSTANT and has NO budget limit!
        WidgetCenter.shared.reloadTimelines(ofKind: "SimpleWidget")
    }

    /// Updates a Progress Widget with the given data
    public func updateProgressWidget(widgetId: String, data: [String: Any], theme: [String: Any]?) {
        var widgetData = data
        widgetData["widgetId"] = widgetId
        widgetData["timestamp"] = Date().timeIntervalSince1970

        if let theme = theme {
            widgetData["theme"] = theme
        }

        storage.save(widgetData, forKey: "\(progressWidgetKeyPrefix)\(widgetId)")
        trackWidgetId(widgetId)

        WidgetCenter.shared.reloadTimelines(ofKind: "ProgressWidget")
    }

    /// Updates a List Widget with the given data
    public func updateListWidget(widgetId: String, data: [String: Any], theme: [String: Any]?) {
        var widgetData = data
        widgetData["widgetId"] = widgetId
        widgetData["timestamp"] = Date().timeIntervalSince1970

        if let theme = theme {
            widgetData["theme"] = theme
        }

        storage.save(widgetData, forKey: "\(listWidgetKeyPrefix)\(widgetId)")
        trackWidgetId(widgetId)

        WidgetCenter.shared.reloadTimelines(ofKind: "ListWidget")
    }

    /// Sets the global theme for all widgets
    public func setGlobalTheme(_ theme: [String: Any]) {
        storage.save(theme, forKey: globalThemeKey)
        forceRefreshAll()
    }

    /// Forces refresh of all widget timelines
    ///
    /// **Important**: When called while app is in foreground, this provides
    /// instant updates with NO budget limit. This is the recommended approach
    /// for real-time updates.
    public func forceRefreshAll() {
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// Returns list of active widget IDs
    public func getActiveWidgetIds() -> [String] {
        return Array(activeWidgetIds)
    }

    /// Gets the Widget Push Token for server-triggered updates (iOS 26+)
    ///
    /// This token is set by the WidgetPushHandler in the widget extension.
    /// Returns nil on iOS versions below 26 or if token is not available.
    public func getWidgetPushToken() -> String? {
        return storage.loadString(forKey: widgetPushTokenKey)
    }

    /// Sends a widget action event back to Flutter
    public func sendActionEvent(widgetId: String, actionType: String, payload: [String: Any]? = nil) {
        var event: [String: Any] = [
            "widgetId": widgetId,
            "type": actionType,
            "timestamp": Int(Date().timeIntervalSince1970 * 1000)
        ]

        if let payload = payload {
            event["payload"] = payload
        }

        eventSinkLock.lock()
        let sink = eventSink
        eventSinkLock.unlock()

        DispatchQueue.main.async {
            sink?(event)
        }
    }

    // MARK: - Private Helpers

    private func trackWidgetId(_ widgetId: String) {
        activeWidgetIds.insert(widgetId)
        persistActiveWidgetIds()
    }

    private func persistActiveWidgetIds() {
        storage.save(Array(activeWidgetIds), forKey: activeWidgetsKey)
    }

    private func loadActiveWidgetIds() {
        if let ids: [String] = storage.loadArray(forKey: activeWidgetsKey) {
            activeWidgetIds = Set(ids)
        }
    }
}

// MARK: - FlutterEventSink Type Alias

/// Type alias for Flutter event sink (avoids direct Flutter import in this file)
public typealias FlutterEventSink = (Any?) -> Void
