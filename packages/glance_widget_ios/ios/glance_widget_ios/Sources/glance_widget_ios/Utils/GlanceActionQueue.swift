import Foundation

/// An interaction the widget extension handled while the app was not running.
///
/// A widget button on iOS 17 runs its `AppIntent` inside the extension. That
/// process cannot reach the Flutter isolate -- it may be the only part of the
/// app alive -- so the intent records what happened here and the plugin
/// replays it into `dev.glance.widget/events` the next time Dart is listening.
public struct GlancePendingAction: Codable, Equatable, Sendable {
    /// Which widget the user touched.
    public let widgetId: String

    /// The action name Dart already knows, such as `checkboxToggle`.
    public let type: String

    /// Anything else the action carried, as strings.
    ///
    /// The extension writes this from an `AppIntent`'s parameters, which are
    /// few and simple. Keeping it `[String: String]` rather than the method
    /// channel's `[String: Any]` is what lets it be `Codable` at all, and the
    /// plugin converts the values Dart expects as numbers or booleans back on
    /// the way out.
    public let payload: [String: String]?

    /// When the extension handled it, as seconds since 1970.
    public let timestamp: Double

    /// Records that [type] happened to [widgetId] at [timestamp].
    public init(widgetId: String, type: String, payload: [String: String]?, timestamp: Double) {
        self.widgetId = widgetId
        self.type = type
        self.payload = payload
        self.timestamp = timestamp
    }
}

/// The queue an extension appends to and the plugin drains.
///
/// Both halves implement these rules: the plugin here, and the widget
/// extension by hand in `GlanceInteractive.swift`, which cannot import this
/// package. `GlanceActionQueueTests` pins the encoding so the two cannot drift
/// into each other silently -- a drift here does not crash, it just loses
/// every interaction the user makes on the lock screen.
public enum GlanceActionQueue {

    /// The most actions the queue holds.
    ///
    /// An app that is never opened again would otherwise grow this without
    /// limit in shared storage the user cannot see. A hundred taps is far more
    /// than any real backlog, and the oldest are the ones worth losing.
    public static let capacity = 100

    /// [queue] with [action] on the end, oldest first, trimmed to `capacity`.
    public static func appending(
        _ action: GlancePendingAction,
        to queue: [GlancePendingAction]
    ) -> [GlancePendingAction] {
        let appended = queue + [action]
        guard appended.count > capacity else { return appended }
        return Array(appended.suffix(capacity))
    }

    /// The actions in [items], skipping any entry that cannot be read.
    ///
    /// One unreadable entry -- written by an older build of the extension, say
    /// -- must not discard the ones around it, so this drops rather than
    /// throws.
    public static func decode(_ items: [Data]) -> [GlancePendingAction] {
        let decoder = JSONDecoder()
        return items.compactMap { try? decoder.decode(GlancePendingAction.self, from: $0) }
    }

    /// [actions] encoded the way the extension writes them.
    public static func encode(_ actions: [GlancePendingAction]) -> [Data] {
        let encoder = JSONEncoder()
        return actions.compactMap { try? encoder.encode($0) }
    }

    /// [action]'s payload as the method channel's event map wants it.
    ///
    /// The queue stores everything as a string because that is what survives
    /// `Codable` without a type tag. Dart's `GlanceWidgetAction` reads
    /// `itemIndex` as an `int` and `value` as a `bool`, and a String where a
    /// bool is expected throws in the Dart layer rather than here, so the
    /// conversion happens on the way out -- exactly as the URL path already
    /// does for a widget tap that launches the app.
    public static func eventPayload(for action: GlancePendingAction) -> [String: Any]? {
        guard let payload = action.payload, !payload.isEmpty else { return nil }
        var converted: [String: Any] = [:]
        for (key, value) in payload {
            if let intValue = Int(value) {
                converted[key] = intValue
            } else if value == "true" {
                converted[key] = true
            } else if value == "false" {
                converted[key] = false
            } else {
                converted[key] = value
            }
        }
        return converted
    }
}
