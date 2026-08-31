import Foundation

/// Where the plugin's App Group identifier comes from.
///
/// It used to come from nowhere: a `public static var` holding
/// `group.com.example.glancewidget` that nothing ever assigned. An app whose
/// group was anything else -- which is every app but the example -- had the
/// plugin writing to a suite it holds no entitlement for, so
/// `UserDefaults(suiteName:)` returned nil and every update quietly did
/// nothing.
///
/// The app declares it in its own `Info.plist` instead. That is available
/// before any Dart runs, which matters: widget updates can be requested at
/// launch, and a setter called from Dart would arrive too late.
public enum GlanceAppGroup {

    /// The `Info.plist` key an app sets to name its App Group.
    public static let infoPlistKey = "GlanceWidgetAppGroup"

    /// Kept so apps that already set `GlanceWidgetManager.appGroupId` by hand,
    /// the only escape hatch that used to exist, are not broken by this change.
    public static let legacyDefault = "group.com.example.glancewidget"

    /// What was resolved, and whether it was actually chosen by anyone.
    public struct Resolution: Equatable {
        /// The App Group to use.
        public let identifier: String

        /// True when nothing usable was configured and [legacyDefault] was
        /// used. Callers surface this, because the old code could not tell a
        /// deliberate choice from a default nobody had noticed.
        public let isFallback: Bool
    }

    /// Resolves the App Group from an explicit override, then the app's
    /// `Info.plist`, then the legacy default.
    ///
    /// Anything that could not work is refused rather than passed on: a blank
    /// string from an unsubstituted build setting, a value of the wrong type,
    /// or an identifier that is not an App Group at all. Each of those would
    /// otherwise fail inside `UserDefaults(suiteName:)`, far from the mistake.
    public static func resolve(
        infoPlist: [String: Any]?,
        override: String? = nil
    ) -> Resolution {
        if let candidate = valid(override) {
            return Resolution(identifier: candidate, isFallback: false)
        }
        if let candidate = valid(infoPlist?[infoPlistKey]) {
            return Resolution(identifier: candidate, isFallback: false)
        }
        return Resolution(identifier: legacyDefault, isFallback: true)
    }

    private static func valid(_ value: Any?) -> String? {
        guard let string = value as? String else { return nil }
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        // An App Group identifier always begins with "group."; Apple enforces
        // it when the capability is added. A bundle id pasted in by mistake
        // would otherwise produce exactly the same silence as no group at all.
        guard trimmed.hasPrefix("group.") else { return nil }
        // "group." on its own is a prefix, not an identifier.
        guard trimmed.count > "group.".count else { return nil }
        return trimmed
    }
}
