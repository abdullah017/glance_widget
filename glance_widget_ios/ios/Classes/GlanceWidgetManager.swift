import Foundation
import WidgetKit

/// Result type for widget update operations.
/// Provides structured error information for proper error handling.
public enum GlanceResult {
    case success
    case failure(code: String, message: String)

    public var isSuccess: Bool {
        if case .success = self { return true }
        return false
    }

    public var isFailure: Bool {
        if case .failure = self { return true }
        return false
    }

    /// Extracts error information if this is a failure result
    public var error: (code: String, message: String)? {
        if case .failure(let code, let message) = self {
            return (code, message)
        }
        return nil
    }

    // Error codes
    public static let errorAppGroupAccess = "APP_GROUP_ACCESS_ERROR"
    public static let errorSaveFailed = "SAVE_FAILED"
    public static let errorInvalidData = "INVALID_DATA"
}

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
    private let calendarWidgetKeyPrefix = "calendarWidgetData_"
    private let imageWidgetKeyPrefix = "imageWidgetData_"
    private let chartWidgetKeyPrefix = "chartWidgetData_"
    private let gaugeWidgetKeyPrefix = "gaugeWidgetData_"
    private let globalThemeKey = "globalTheme"
    private let activeWidgetsKey = "activeWidgetIds"
    private let widgetPushTokenKey = "widgetPushToken"
    private let timelineRefreshIntervalKey = "timeline_refresh_interval"

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
        _ = updateSimpleWidgetWithResult(widgetId: widgetId, data: data, theme: theme)
    }

    /// Updates a Simple Widget with the given data and returns a result.
    /// Use this method when you need to handle errors.
    @discardableResult
    public func updateSimpleWidgetWithResult(widgetId: String, data: [String: Any], theme: [String: Any]?) -> GlanceResult {
        guard storage.isAvailable else {
            print("GlanceWidget: App Group storage not available. Check entitlements for: \(GlanceWidgetManager.appGroupId)")
            return .failure(code: GlanceResult.errorAppGroupAccess,
                          message: "App Group storage not available. Check entitlements configuration.")
        }

        var widgetData = data
        widgetData["widgetId"] = widgetId
        widgetData["timestamp"] = Date().timeIntervalSince1970

        if let theme = theme {
            widgetData["theme"] = theme
        }

        let saved = storage.save(widgetData, forKey: "\(simpleWidgetKeyPrefix)\(widgetId)")
        if !saved {
            return .failure(code: GlanceResult.errorSaveFailed,
                          message: "Failed to save widget data to App Group storage")
        }

        trackWidgetId(widgetId)

        // Trigger widget refresh
        // When app is in foreground, this is INSTANT and has NO budget limit!
        WidgetCenter.shared.reloadTimelines(ofKind: "SimpleWidget")
        return .success
    }

    /// Updates a Progress Widget with the given data
    public func updateProgressWidget(widgetId: String, data: [String: Any], theme: [String: Any]?) {
        _ = updateProgressWidgetWithResult(widgetId: widgetId, data: data, theme: theme)
    }

    /// Updates a Progress Widget with the given data and returns a result.
    /// Use this method when you need to handle errors.
    @discardableResult
    public func updateProgressWidgetWithResult(widgetId: String, data: [String: Any], theme: [String: Any]?) -> GlanceResult {
        guard storage.isAvailable else {
            print("GlanceWidget: App Group storage not available. Check entitlements for: \(GlanceWidgetManager.appGroupId)")
            return .failure(code: GlanceResult.errorAppGroupAccess,
                          message: "App Group storage not available. Check entitlements configuration.")
        }

        var widgetData = data
        widgetData["widgetId"] = widgetId
        widgetData["timestamp"] = Date().timeIntervalSince1970

        if let theme = theme {
            widgetData["theme"] = theme
        }

        let saved = storage.save(widgetData, forKey: "\(progressWidgetKeyPrefix)\(widgetId)")
        if !saved {
            return .failure(code: GlanceResult.errorSaveFailed,
                          message: "Failed to save widget data to App Group storage")
        }

        trackWidgetId(widgetId)
        WidgetCenter.shared.reloadTimelines(ofKind: "ProgressWidget")
        return .success
    }

    /// Updates a List Widget with the given data
    public func updateListWidget(widgetId: String, data: [String: Any], theme: [String: Any]?) {
        _ = updateListWidgetWithResult(widgetId: widgetId, data: data, theme: theme)
    }

    /// Updates a List Widget with the given data and returns a result.
    /// Use this method when you need to handle errors.
    @discardableResult
    public func updateListWidgetWithResult(widgetId: String, data: [String: Any], theme: [String: Any]?) -> GlanceResult {
        guard storage.isAvailable else {
            print("GlanceWidget: App Group storage not available. Check entitlements for: \(GlanceWidgetManager.appGroupId)")
            return .failure(code: GlanceResult.errorAppGroupAccess,
                          message: "App Group storage not available. Check entitlements configuration.")
        }

        var widgetData = data
        widgetData["widgetId"] = widgetId
        widgetData["timestamp"] = Date().timeIntervalSince1970

        if let theme = theme {
            widgetData["theme"] = theme
        }

        let saved = storage.save(widgetData, forKey: "\(listWidgetKeyPrefix)\(widgetId)")
        if !saved {
            return .failure(code: GlanceResult.errorSaveFailed,
                          message: "Failed to save widget data to App Group storage")
        }

        trackWidgetId(widgetId)
        WidgetCenter.shared.reloadTimelines(ofKind: "ListWidget")
        return .success
    }

    /// Updates a Calendar Widget with the given data
    public func updateCalendarWidget(widgetId: String, data: [String: Any], theme: [String: Any]?) {
        _ = updateCalendarWidgetWithResult(widgetId: widgetId, data: data, theme: theme)
    }

    /// Updates a Calendar Widget with the given data and returns a result.
    /// Use this method when you need to handle errors.
    @discardableResult
    public func updateCalendarWidgetWithResult(widgetId: String, data: [String: Any], theme: [String: Any]?) -> GlanceResult {
        guard storage.isAvailable else {
            print("GlanceWidget: App Group storage not available. Check entitlements for: \(GlanceWidgetManager.appGroupId)")
            return .failure(code: GlanceResult.errorAppGroupAccess,
                          message: "App Group storage not available. Check entitlements configuration.")
        }

        var widgetData = data
        widgetData["widgetId"] = widgetId
        widgetData["timestamp"] = Date().timeIntervalSince1970

        if let theme = theme {
            widgetData["theme"] = theme
        }

        let saved = storage.save(widgetData, forKey: "\(calendarWidgetKeyPrefix)\(widgetId)")
        if !saved {
            return .failure(code: GlanceResult.errorSaveFailed,
                          message: "Failed to save widget data to App Group storage")
        }

        trackWidgetId(widgetId)
        WidgetCenter.shared.reloadTimelines(ofKind: "CalendarWidget")
        return .success
    }

    /// Updates an Image Widget with the given data
    public func updateImageWidget(widgetId: String, data: [String: Any], theme: [String: Any]?) {
        _ = updateImageWidgetWithResult(widgetId: widgetId, data: data, theme: theme)
    }

    /// Updates an Image Widget with the given data and returns a result.
    /// Use this method when you need to handle errors.
    @discardableResult
    public func updateImageWidgetWithResult(widgetId: String, data: [String: Any], theme: [String: Any]?) -> GlanceResult {
        guard storage.isAvailable else {
            print("GlanceWidget: App Group storage not available. Check entitlements for: \(GlanceWidgetManager.appGroupId)")
            return .failure(code: GlanceResult.errorAppGroupAccess,
                          message: "App Group storage not available. Check entitlements configuration.")
        }

        var widgetData = data
        widgetData["widgetId"] = widgetId
        widgetData["timestamp"] = Date().timeIntervalSince1970

        if let theme = theme {
            widgetData["theme"] = theme
        }

        let saved = storage.save(widgetData, forKey: "\(imageWidgetKeyPrefix)\(widgetId)")
        if !saved {
            return .failure(code: GlanceResult.errorSaveFailed,
                          message: "Failed to save widget data to App Group storage")
        }

        trackWidgetId(widgetId)
        WidgetCenter.shared.reloadTimelines(ofKind: "ImageWidget")
        return .success
    }

    /// Updates a Chart Widget with the given data
    public func updateChartWidget(widgetId: String, data: [String: Any], theme: [String: Any]?) {
        _ = updateChartWidgetWithResult(widgetId: widgetId, data: data, theme: theme)
    }

    /// Updates a Chart Widget with the given data and returns a result.
    /// Use this method when you need to handle errors.
    @discardableResult
    public func updateChartWidgetWithResult(widgetId: String, data: [String: Any], theme: [String: Any]?) -> GlanceResult {
        guard storage.isAvailable else {
            print("GlanceWidget: App Group storage not available. Check entitlements for: \(GlanceWidgetManager.appGroupId)")
            return .failure(code: GlanceResult.errorAppGroupAccess,
                          message: "App Group storage not available. Check entitlements configuration.")
        }

        var widgetData = data
        widgetData["widgetId"] = widgetId
        widgetData["timestamp"] = Date().timeIntervalSince1970

        if let theme = theme {
            widgetData["theme"] = theme
        }

        let saved = storage.save(widgetData, forKey: "\(chartWidgetKeyPrefix)\(widgetId)")
        if !saved {
            return .failure(code: GlanceResult.errorSaveFailed,
                          message: "Failed to save widget data to App Group storage")
        }

        trackWidgetId(widgetId)
        WidgetCenter.shared.reloadTimelines(ofKind: "ChartWidget")
        return .success
    }

    /// Updates a Gauge Widget with the given data
    public func updateGaugeWidget(widgetId: String, data: [String: Any], theme: [String: Any]?) {
        _ = updateGaugeWidgetWithResult(widgetId: widgetId, data: data, theme: theme)
    }

    /// Updates a Gauge Widget with the given data and returns a result.
    /// Use this method when you need to handle errors.
    @discardableResult
    public func updateGaugeWidgetWithResult(widgetId: String, data: [String: Any], theme: [String: Any]?) -> GlanceResult {
        guard storage.isAvailable else {
            print("GlanceWidget: App Group storage not available. Check entitlements for: \(GlanceWidgetManager.appGroupId)")
            return .failure(code: GlanceResult.errorAppGroupAccess,
                          message: "App Group storage not available. Check entitlements configuration.")
        }

        var widgetData = data
        widgetData["widgetId"] = widgetId
        widgetData["timestamp"] = Date().timeIntervalSince1970

        if let theme = theme {
            widgetData["theme"] = theme
        }

        let saved = storage.save(widgetData, forKey: "\(gaugeWidgetKeyPrefix)\(widgetId)")
        if !saved {
            return .failure(code: GlanceResult.errorSaveFailed,
                          message: "Failed to save widget data to App Group storage")
        }

        trackWidgetId(widgetId)
        WidgetCenter.shared.reloadTimelines(ofKind: "GaugeWidget")
        return .success
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

    // MARK: - Timeline Refresh Configuration

    /// Configures a periodic timeline refresh interval for widgets.
    ///
    /// When configured, widget timeline providers will use `.after(date)` policy
    /// instead of `.never`, causing WidgetKit to request new timeline entries
    /// after the specified interval.
    ///
    /// - Parameters:
    ///   - widgetId: The widget identifier requesting the refresh configuration
    ///   - intervalMinutes: The refresh interval in minutes
    public func configureTimelineRefresh(widgetId: String, intervalMinutes: Int) {
        storage.save(intervalMinutes, forKey: timelineRefreshIntervalKey)
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// Cancels the periodic timeline refresh for widgets.
    ///
    /// After cancellation, widget timeline providers will revert to `.never` policy,
    /// only updating when explicitly triggered by the app.
    ///
    /// - Parameter widgetId: The widget identifier requesting the cancellation
    public func cancelTimelineRefresh(widgetId: String) {
        storage.remove(forKey: timelineRefreshIntervalKey)
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// Returns the configured timeline refresh interval in minutes, if any.
    ///
    /// Widget extensions can call this method to determine whether to use
    /// `.after(date)` or `.never` as the timeline reload policy.
    ///
    /// - Returns: The refresh interval in minutes, or nil if no refresh is configured
    public static func getTimelineRefreshInterval() -> Int? {
        let defaults = UserDefaults(suiteName: appGroupId)
        let interval = defaults?.integer(forKey: "timeline_refresh_interval") ?? 0
        return interval > 0 ? interval : nil
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
