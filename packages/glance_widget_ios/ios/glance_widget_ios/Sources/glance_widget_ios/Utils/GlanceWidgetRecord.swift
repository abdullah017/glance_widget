import Foundation

/// The payload the app last pushed for a widget id, kept so it can be read back.
///
/// The plugin already stores what each *template* draws from, under a key that
/// carries the template's own name. That is not enough to answer "what is this
/// id showing": one id may have been written as a simple widget and later as a
/// chart, so the per-template keys cannot say which of them is current, and the
/// stored dictionary has by then been given a resolved image path and a
/// timestamp the caller never sent.
///
/// This keeps one record per id -- the template name plus the payload exactly
/// as it arrived from Dart -- and hands it back as text. Dart parses it. Doing
/// the parsing here would mean a second copy of the field mapping in Swift and
/// a third in Kotlin, all free to drift from the classes they stand for.
///
/// See #37.
public enum GlanceWidgetRecord {

    /// Builds the record for `widgetId`, or nil if the payload cannot be JSON.
    ///
    /// `updatedAt` is milliseconds since the epoch, matching Android. Keys are
    /// sorted so that the same input produces the same text, which is what lets
    /// a test compare records rather than parse them.
    public static func encode(
        widgetId: String,
        kind: GlanceWidgetKind,
        data: [String: Any],
        theme: [String: Any]?,
        updatedAt: Int
    ) -> String? {
        var record: [String: Any] = [
            "widgetId": widgetId,
            "template": kind.rawValue,
            "updatedAt": updatedAt,
            "data": data
        ]
        if let theme {
            record["theme"] = theme
        }

        guard JSONSerialization.isValidJSONObject(record) else {
            GlanceLog.storage.error(
                "Cannot record \(widgetId, privacy: .public): the payload is not JSON."
            )
            return nil
        }
        do {
            let encoded = try JSONSerialization.data(
                withJSONObject: record,
                options: [.sortedKeys]
            )
            return String(data: encoded, encoding: .utf8)
        } catch {
            GlanceLog.storage.error(
                "Cannot record \(widgetId, privacy: .public): \(error)"
            )
            return nil
        }
    }
}

public extension GlanceStorageKeys {
    /// Key under which the record of what one id is showing is stored.
    ///
    /// Deliberately outside the `<template>WidgetData_` family: those keys are
    /// what the widget extension reads to draw, and the configuration picker
    /// lists ids by scanning them. A record filed under that prefix would put a
    /// phantom entry in the picker for a template it does not belong to.
    static func recordKey(widgetId: String) -> String {
        "widgetRecord_\(widgetId)"
    }
}
