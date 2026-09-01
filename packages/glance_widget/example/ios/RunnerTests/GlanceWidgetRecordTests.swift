import Foundation
import Testing
@testable import glance_widget_ios

/// The record `getWidgetData` reads back.
///
/// Nothing here turns a record into a widget: that mapping lives in Dart on
/// purpose, and writing it a second time in Swift is the drift this record
/// exists to avoid. What Swift owns is that the payload goes in untouched, that
/// the text is the same shape Android writes, and that the key it is filed
/// under cannot be mistaken for a template's.
///
/// See #37.
@Suite("Widget record")
struct GlanceWidgetRecordTests {

    private let simpleData: [String: Any] = [
        "title": "Bitcoin",
        "value": "$64,120",
        "subtitle": NSNull(),
        "subtitleColor": 4283215696,
        "deepLinkUri": "myapp://coin/btc"
    ]

    private func decode(_ record: String) throws -> [String: Any] {
        let data = try #require(record.data(using: .utf8))
        return try #require(
            try JSONSerialization.jsonObject(with: data) as? [String: Any]
        )
    }

    @Test("the record carries the id, the template and the time")
    func envelope() throws {
        let record = try #require(GlanceWidgetRecord.encode(
            widgetId: "btc", kind: .simple, data: simpleData,
            theme: nil, updatedAt: 1_756_000_000_000
        ))

        let decoded = try decode(record)
        #expect(decoded["widgetId"] as? String == "btc")
        #expect(decoded["template"] as? String == "simple")
        // Milliseconds, matching Android. Seconds would be a valid-looking
        // timestamp forty-five years out, which no test of "is it a number"
        // would catch.
        #expect(decoded["updatedAt"] as? Int == 1_756_000_000_000)
    }

    @Test("the template name is the one Dart sends")
    func templateNames() throws {
        // These seven strings are the wire contract with Dart's GlanceTemplate.
        // A rename here is invisible to both compilers.
        let expected = ["simple", "progress", "list", "calendar", "image", "chart", "gauge"]
        #expect(Set(GlanceWidgetKind.allCases.map(\.rawValue)) == Set(expected))
    }

    @Test("the payload is stored exactly as it arrived")
    func payloadUntouched() throws {
        let record = try #require(GlanceWidgetRecord.encode(
            widgetId: "btc", kind: .simple, data: simpleData, theme: nil, updatedAt: 1
        ))

        let data = try #require(try decode(record)["data"] as? [String: Any])
        #expect(data["title"] as? String == "Bitcoin")
        #expect(data["deepLinkUri"] as? String == "myapp://coin/btc")
        // 0xFF4CAF50 does not fit in a signed 32-bit int; a colour that comes
        // back changed is a colour the widget is not showing.
        #expect(data["subtitleColor"] as? Int == 4_283_215_696)
        // A field the app explicitly cleared stays cleared rather than
        // disappearing into "never set".
        #expect(data["subtitle"] is NSNull)
    }

    @Test("nested lists survive")
    func nestedLists() throws {
        let record = try #require(GlanceWidgetRecord.encode(
            widgetId: "shopping",
            kind: .list,
            data: [
                "title": "Groceries",
                "items": [
                    ["text": "Milk", "checked": true],
                    ["text": "Bread", "checked": false]
                ],
                "maxItems": 5
            ],
            theme: nil,
            updatedAt: 1
        ))

        let data = try #require(try decode(record)["data"] as? [String: Any])
        let items = try #require(data["items"] as? [[String: Any]])
        #expect(items.count == 2)
        #expect(items[0]["text"] as? String == "Milk")
        #expect(items[0]["checked"] as? Bool == true)
    }

    @Test("a theme is kept when one was sent and absent when it was not")
    func theme() throws {
        let withTheme = try #require(GlanceWidgetRecord.encode(
            widgetId: "btc", kind: .simple, data: simpleData,
            theme: ["backgroundColor": 4_278_190_080, "isDark": true], updatedAt: 1
        ))
        let theme = try #require(try decode(withTheme)["theme"] as? [String: Any])
        #expect(theme["isDark"] as? Bool == true)

        let without = try #require(GlanceWidgetRecord.encode(
            widgetId: "btc", kind: .simple, data: simpleData, theme: nil, updatedAt: 1
        ))
        #expect(try decode(without)["theme"] == nil)
    }

    @Test("the same payload always produces the same text")
    func deterministic() throws {
        let first = GlanceWidgetRecord.encode(
            widgetId: "btc", kind: .simple, data: simpleData, theme: nil, updatedAt: 7
        )
        let second = GlanceWidgetRecord.encode(
            widgetId: "btc", kind: .simple, data: simpleData, theme: nil, updatedAt: 7
        )
        #expect(first == second)
    }

    @Test("a payload that is not JSON is refused rather than crashing")
    func unencodable() {
        // `JSONSerialization.data` raises an Objective-C exception on an
        // invalid object, which Swift cannot catch -- so the validity check has
        // to happen before the call, not in a `catch`.
        let record = GlanceWidgetRecord.encode(
            widgetId: "btc",
            kind: .simple,
            data: ["title": Date(timeIntervalSince1970: 0)],
            theme: nil,
            updatedAt: 1
        )
        #expect(record == nil)
    }

    @Test("the record key cannot be mistaken for a template's")
    func keyIsOutsideTheTemplateFamily() {
        // The configuration picker lists ids by scanning `<template>WidgetData_`
        // keys. A record filed under that prefix would add a phantom row for a
        // template the id was never written as.
        let key = GlanceStorageKeys.recordKey(widgetId: "btc")
        for kind in GlanceWidgetKind.allCases {
            #expect(GlanceStorageKeys.widgetId(fromKey: key, kind: kind) == nil)
        }
        #expect(!GlanceStorageKeys.allKeys(forWidgetId: "btc").contains(key))
    }

    /// The pure tests above check the format. This one checks the wiring: that
    /// an update actually calls the recorder, under the key the reader looks
    /// at, and that forgetting drops it. Those three are what a rename or a
    /// missed call site breaks, and none of them is visible in `encode`.
    @Test("an update records, and forgetting drops the record")
    func throughTheManager() throws {
        let manager = GlanceWidgetManager.shared
        let widgetId = "record-wiring-test"

        manager.updateSimpleWidget(
            widgetId: widgetId,
            data: ["title": "Bitcoin", "value": "$64,120"],
            theme: nil
        )

        let record = try #require(
            manager.widgetRecord(widgetId),
            "an update wrote no record"
        )
        let decoded = try decode(record)
        #expect(decoded["template"] as? String == "simple")
        let data = try #require(decoded["data"] as? [String: Any])
        #expect(data["value"] as? String == "$64,120")

        manager.forgetWidget(widgetId)
        #expect(manager.widgetRecord(widgetId) == nil)
    }

    @Test("one widget's record is not another's")
    func perWidget() {
        #expect(
            GlanceStorageKeys.recordKey(widgetId: "btc")
                != GlanceStorageKeys.recordKey(widgetId: "eth")
        )
    }
}
