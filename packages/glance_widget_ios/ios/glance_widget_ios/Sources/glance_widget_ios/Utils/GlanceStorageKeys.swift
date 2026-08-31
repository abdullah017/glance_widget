import Foundation

/// The template a stored payload belongs to.
public enum GlanceWidgetKind: String, CaseIterable, Sendable {
    case simple
    case progress
    case list
    case calendar
    case image
    case chart
    case gauge
}

/// The App Group key layout shared by the plugin and the widget extension.
///
/// The plugin writes `"<prefix><widgetId>"`; the extension reads those keys back
/// to answer two questions -- "what is the payload for this id" and "which ids
/// does this template have data for", the latter being what the widget's
/// configuration picker offers.
///
/// These were seven private string literals in `GlanceWidgetManager`, duplicated
/// by hand in the templates. A rename on either side did not fail anything: the
/// picker would simply have gone empty and every configured widget would have
/// rendered nothing. The literals are asserted in `GlanceStorageKeysTests`, so
/// changing one now breaks a test that names the templates to update.
public enum GlanceStorageKeys {
    /// Key under which the plugin records every id it has ever written.
    public static let activeWidgetIds = "activeWidgetIds"

    /// Key under which the widget extension queues interactions it handled
    /// while the app was not running. Drained by the plugin, never by the
    /// extension. See `GlanceActionQueue`.
    public static let pendingActions = "pendingWidgetActions"

    public static func prefix(for kind: GlanceWidgetKind) -> String {
        "\(kind.rawValue)WidgetData_"
    }

    public static func key(_ kind: GlanceWidgetKind, widgetId: String) -> String {
        "\(prefix(for: kind))\(widgetId)"
    }

    /// The id a key carries, or `nil` if the key belongs to another template.
    ///
    /// A bare prefix with nothing after it is not an id -- returning `""` would
    /// put an unselectable blank row in the configuration picker.
    public static func widgetId(fromKey key: String, kind: GlanceWidgetKind) -> String? {
        let prefix = prefix(for: kind)
        guard key.hasPrefix(prefix) else { return nil }
        let id = String(key.dropFirst(prefix.count))
        return id.isEmpty ? nil : id
    }

    /// The ids one template has data for, in a stable order.
    ///
    /// This is the rule `WidgetStorage.knownWidgetIds(prefix:)` implements in the
    /// widget extension, where it cannot import this package.
    public static func widgetIds(in keys: some Sequence<String>, kind: GlanceWidgetKind) -> [String] {
        keys.compactMap { widgetId(fromKey: $0, kind: kind) }.sorted()
    }
}
