import Foundation

/// One widget's share of a batch, with its theme already resolved.
///
/// The wire format sends the batch theme once and repeats it only for a widget
/// that overrides it, which is the point of batching. By the time an entry
/// reaches here that distinction is gone: `theme` is what this widget should be
/// drawn with.
public struct GlanceBatchEntry {
    public let widgetId: String
    public let template: String

    /// The payload, untouched. The manager reads it key by key; nothing here
    /// interprets it, so it is carried through rather than converted.
    public let data: [String: Any]

    /// The theme this widget should be drawn with: its own if it sent one,
    /// otherwise the batch's.
    public let theme: [String: Any]?

    public init(widgetId: String, template: String, data: [String: Any], theme: [String: Any]?) {
        self.widgetId = widgetId
        self.template = template
        self.data = data
        self.theme = theme
    }
}

/// The result of reading an `updateBatch` call's arguments.
public enum GlanceBatchParse {
    /// The arguments described these entries, in the order they were sent.
    case ok([GlanceBatchEntry])

    /// The arguments were not a batch, and why.
    case invalid(reason: String)
}

/// Reads the arguments of an `updateBatch` call.
///
/// Free of Flutter types so the wire contract can be tested without a plugin
/// registrar. The shape it accepts is the shape `MethodChannelGlanceWidget`
/// writes, and the Dart, Kotlin and Swift tests all pin the same key names --
/// a rename that lands on only one side is otherwise silent, which is how
/// `imageFit` went unread for a whole release.
public enum GlanceBatchRequest {

    /// Reads [arguments] into entries, or explains why it could not.
    ///
    /// Parsing is separate from applying so that a malformed payload is
    /// rejected before any widget is touched: half a batch applied and then an
    /// argument error is a state the caller never asked for.
    public static func parse(_ arguments: Any?) -> GlanceBatchParse {
        guard let root = arguments as? [String: Any] else {
            return .invalid(reason: "updateBatch expects a map of arguments")
        }
        guard let rawUpdates = root["updates"] else {
            return .invalid(reason: "updateBatch is missing 'updates'")
        }
        guard let updates = rawUpdates as? [Any] else {
            return .invalid(reason: "'updates' must be a list")
        }

        let batchTheme: [String: Any]?
        switch root["theme"] {
        case nil, is NSNull:
            batchTheme = nil
        case let theme as [String: Any]:
            batchTheme = theme
        default:
            return .invalid(reason: "'theme' must be a map")
        }

        var entries: [GlanceBatchEntry] = []
        entries.reserveCapacity(updates.count)
        var seen = Set<String>()

        for (index, element) in updates.enumerated() {
            guard let update = element as? [String: Any] else {
                return .invalid(reason: "updates[\(index)] is not a map")
            }
            guard let widgetId = update["widgetId"] as? String else {
                return .invalid(reason: "updates[\(index)] has no widgetId")
            }
            guard !widgetId.isEmpty else {
                return .invalid(reason: "updates[\(index)] has an empty widgetId")
            }
            guard seen.insert(widgetId).inserted else {
                // Two entries for one widget would race: whichever landed last
                // would win, with no way for the caller to know which.
                return .invalid(reason: "widgetId '\(widgetId)' appears more than once")
            }
            guard let template = update["template"] as? String else {
                return .invalid(reason: "updates[\(index)] has no template")
            }
            guard let data = update["data"] as? [String: Any] else {
                return .invalid(reason: "updates[\(index)] has no data")
            }

            let theme: [String: Any]?
            switch update["theme"] {
            case nil, is NSNull:
                theme = batchTheme
            case let own as [String: Any]:
                theme = own
            default:
                return .invalid(reason: "updates[\(index)] has a theme that is not a map")
            }

            entries.append(
                GlanceBatchEntry(
                    widgetId: widgetId,
                    template: template,
                    data: data,
                    theme: theme
                )
            )
        }

        return .ok(entries)
    }
}
