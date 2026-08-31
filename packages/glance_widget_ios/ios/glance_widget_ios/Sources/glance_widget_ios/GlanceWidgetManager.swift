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
    private let globalThemeKey = "globalTheme"
    private let activeWidgetsKey = GlanceStorageKeys.activeWidgetIds
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

        let saved = storage.save(widgetData, forKey: GlanceStorageKeys.key(.simple, widgetId: widgetId))
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

        let saved = storage.save(widgetData, forKey: GlanceStorageKeys.key(.progress, widgetId: widgetId))
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

        let saved = storage.save(widgetData, forKey: GlanceStorageKeys.key(.list, widgetId: widgetId))
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

        let saved = storage.save(widgetData, forKey: GlanceStorageKeys.key(.calendar, widgetId: widgetId))
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
        updateImageWidgetWithResult(widgetId: widgetId, data: data, theme: theme) { _ in }
    }

    /// Updates an Image Widget with the given data and reports the outcome.
    ///
    /// Asynchronous, unlike its siblings: `imageUrl` has to be fetched and the
    /// picture downsampled before the widget can draw it, and neither belongs in
    /// a widget extension. An extension runs under a far tighter memory budget
    /// than the app and WidgetKit will not wait for a network round trip during
    /// a timeline reload, so the work happens here instead.
    public func updateImageWidgetWithResult(
        widgetId: String,
        data: [String: Any],
        theme: [String: Any]?,
        completion: @escaping (GlanceResult) -> Void
    ) {
        guard storage.isAvailable else {
            print("GlanceWidget: App Group storage not available. Check entitlements for: \(GlanceWidgetManager.appGroupId)")
            completion(.failure(code: GlanceResult.errorAppGroupAccess,
                                message: "App Group storage not available. Check entitlements configuration."))
            return
        }

        guard let container = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: GlanceWidgetManager.appGroupId
        ) else {
            completion(.failure(code: GlanceResult.errorAppGroupAccess,
                                message: "App Group container not available. Check entitlements configuration."))
            return
        }

        GlanceImageStore.store(
            widgetId: widgetId,
            imageBase64: data["imageBase64"] as? String,
            imageUrl: data["imageUrl"] as? String,
            containerURL: container
        ) { [weak self] stored in
            guard let self = self else { return }

            var widgetData = data
            widgetData["widgetId"] = widgetId
            widgetData["timestamp"] = Date().timeIntervalSince1970

            switch stored {
            case let .failed(reason):
                completion(.failure(code: GlanceResult.errorInvalidData, message: reason))
                return
            case let .stored(path):
                widgetData["imagePath"] = path
            case .empty:
                // A widget that used to show a picture and no longer has one
                // must stop showing the old one. The file behind it is dropped
                // by `GlanceImageStore` itself.
                widgetData["imagePath"] = nil
            }

            // The raw bytes are not carried into storage: the picture now lives
            // in a file, and a base64 string of it would be dead weight in the
            // App Group defaults every widget reload has to read.
            widgetData["imageBase64"] = nil

            if let theme = theme {
                widgetData["theme"] = theme
            }

            let saved = self.storage.save(widgetData, forKey: GlanceStorageKeys.key(.image, widgetId: widgetId))
            if !saved {
                completion(.failure(code: GlanceResult.errorSaveFailed,
                                    message: "Failed to save widget data to App Group storage"))
                return
            }

            self.trackWidgetId(widgetId)
            WidgetCenter.shared.reloadTimelines(ofKind: "ImageWidget")
            completion(.success)
        }
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

        let saved = storage.save(widgetData, forKey: GlanceStorageKeys.key(.chart, widgetId: widgetId))
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

        let saved = storage.save(widgetData, forKey: GlanceStorageKeys.key(.gauge, widgetId: widgetId))
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
    /// Emits a widget interaction to Dart.
    ///
    /// [occurredAt] defaults to now, which is right for an action arriving by
    /// URL while the app is running. A queued action carries the time the
    /// widget extension handled it, which can be hours earlier -- stamping
    /// those with `Date()` would tell Dart every backlogged tap happened at
    /// once, at launch.

    // MARK: - Queued Actions

    /// Replays the interactions the widget extension handled on its own.
    ///
    /// A widget button on iOS 17 runs its `AppIntent` inside the extension,
    /// which may be the only part of the app alive. It writes what happened to
    /// the App Group; this drains that queue into the event channel.
    ///
    /// Nothing is drained while Dart is not listening. The event sink drops
    /// what it is handed when there is no listener, so clearing the queue then
    /// would throw the backlog away in silence -- which is exactly the failure
    /// the queue exists to prevent.
    public func drainPendingActions() {
        eventSinkLock.lock()
        let listening = eventSink != nil
        eventSinkLock.unlock()
        guard listening, storage.isAvailable else { return }

        let raw = storage.loadDataArray(forKey: GlanceStorageKeys.pendingActions) ?? []
        guard !raw.isEmpty else { return }

        // Cleared before emitting: an action that fails to decode is still
        // consumed, so a single unreadable entry cannot make the queue
        // un-drainable and grow forever behind it.
        storage.remove(forKey: GlanceStorageKeys.pendingActions)

        for action in GlanceActionQueue.decode(raw) {
            sendActionEvent(
                widgetId: action.widgetId,
                actionType: action.type,
                payload: GlanceActionQueue.eventPayload(for: action),
                occurredAt: Date(timeIntervalSince1970: action.timestamp)
            )
        }
    }

    public func sendActionEvent(
        widgetId: String,
        actionType: String,
        payload: [String: Any]? = nil,
        occurredAt: Date = Date()
    ) {
        var event: [String: Any] = [
            "widgetId": widgetId,
            "type": actionType,
            "timestamp": Int(occurredAt.timeIntervalSince1970 * 1000)
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
