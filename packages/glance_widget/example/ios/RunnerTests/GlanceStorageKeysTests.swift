import Foundation
import Testing
@testable import glance_widget_ios

/// The App Group key layout is a contract between two halves that cannot see
/// each other: the plugin writes the keys, and the widget extension -- which
/// cannot import this package -- reads them back with the same literals typed
/// out by hand in `SharedModels.swift`.
///
/// Nothing failed when those drifted. The picker would go empty and every
/// configured widget would render nothing, silently. So these assert the exact
/// strings rather than round-tripping through the API: a rename has to break
/// here, and the failure names the templates that need updating.
struct GlanceStorageKeysTests {
    @Test("the stored prefixes are exactly what the widget templates hardcode", arguments: [
        (GlanceWidgetKind.simple, "simpleWidgetData_"),
        (GlanceWidgetKind.progress, "progressWidgetData_"),
        (GlanceWidgetKind.list, "listWidgetData_"),
        (GlanceWidgetKind.calendar, "calendarWidgetData_"),
        (GlanceWidgetKind.image, "imageWidgetData_"),
        (GlanceWidgetKind.chart, "chartWidgetData_"),
        (GlanceWidgetKind.gauge, "gaugeWidgetData_"),
    ])
    func prefixes(kind: GlanceWidgetKind, expected: String) {
        #expect(GlanceStorageKeys.prefix(for: kind) == expected)
    }

    @Test("every template is covered, so a new one cannot be added without a prefix")
    func allKindsCovered() {
        #expect(GlanceWidgetKind.allCases.count == 7)
    }

    @Test("the key for an id is the prefix plus the id")
    func keyLayout() {
        #expect(GlanceStorageKeys.key(.simple, widgetId: "btc") == "simpleWidgetData_btc")
    }

    @Test("a key gives its id back")
    func roundTrip() {
        let key = GlanceStorageKeys.key(.chart, widgetId: "revenue")

        #expect(GlanceStorageKeys.widgetId(fromKey: key, kind: .chart) == "revenue")
    }

    /// The prefixes share a suffix, so a sloppy match would let `simple` claim
    /// keys belonging to every other template.
    @Test("a key belonging to another template is not claimed")
    func foreignKeyRejected() {
        #expect(GlanceStorageKeys.widgetId(fromKey: "chartWidgetData_x", kind: .simple) == nil)
        #expect(GlanceStorageKeys.widgetId(fromKey: "globalTheme", kind: .simple) == nil)
        #expect(GlanceStorageKeys.widgetId(fromKey: "activeWidgetIds", kind: .simple) == nil)
    }

    /// A bare prefix would otherwise yield `""` and put a blank, unselectable
    /// row in the widget's configuration picker.
    @Test("a bare prefix carries no id")
    func barePrefixHasNoId() {
        #expect(GlanceStorageKeys.widgetId(fromKey: "simpleWidgetData_", kind: .simple) == nil)
    }

    /// An id may legitimately contain the separator; only the first prefix is
    /// stripped.
    @Test("an id containing an underscore survives")
    func idWithSeparator() {
        let key = GlanceStorageKeys.key(.list, widgetId: "todo_today")

        #expect(GlanceStorageKeys.widgetId(fromKey: key, kind: .list) == "todo_today")
    }

    @Test("only this template's ids are offered, in a stable order")
    func idsForOneKind() {
        let keys = [
            "simpleWidgetData_eth",
            "simpleWidgetData_btc",
            "chartWidgetData_revenue",
            "globalTheme",
            "simpleWidgetData_",
        ]

        #expect(GlanceStorageKeys.widgetIds(in: keys, kind: .simple) == ["btc", "eth"])
        #expect(GlanceStorageKeys.widgetIds(in: keys, kind: .chart) == ["revenue"])
        #expect(GlanceStorageKeys.widgetIds(in: keys, kind: .gauge).isEmpty)
    }

    /// What `forgetWidget` deletes.
    ///
    /// Nothing ties one id to one template -- an app can write "btc" as a
    /// simple widget today and as a chart tomorrow -- so dropping an id has to
    /// drop all seven keys. Deriving them from `allCases` means a template
    /// added later is covered; this pins that it really is all of them, so
    /// adding a case to `GlanceWidgetKind` without a payload key fails here
    /// rather than leaking a payload nothing can reach.
    @Test("forgetting an id covers every template")
    func allKeysForOneId() {
        let keys = GlanceStorageKeys.allKeys(forWidgetId: "btc")

        #expect(keys.count == GlanceWidgetKind.allCases.count)
        #expect(Set(keys).count == keys.count)
        #expect(keys.contains("simpleWidgetData_btc"))
        #expect(keys.contains("gaugeWidgetData_btc"))
        for kind in GlanceWidgetKind.allCases {
            #expect(keys.contains(GlanceStorageKeys.key(kind, widgetId: "btc")))
        }
    }

    /// The keys are per id, not shared. Forgetting one widget must not name a
    /// key belonging to another.
    @Test("forgetting one id names no other id's keys")
    func allKeysAreScopedToTheId() {
        let keys = GlanceStorageKeys.allKeys(forWidgetId: "btc")

        #expect(!keys.contains { GlanceStorageKeys.widgetId(fromKey: $0, kind: .simple) == "eth" })
        for key in keys {
            let ids = GlanceWidgetKind.allCases.compactMap {
                GlanceStorageKeys.widgetId(fromKey: key, kind: $0)
            }
            #expect(ids.allSatisfy { $0 == "btc" })
        }
    }
}
