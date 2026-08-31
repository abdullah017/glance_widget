import Foundation
import Testing
@testable import glance_widget_ios

/// The widget extension ships its own copy of these two types, and that copy is
/// compiled into this target from `GlanceInteractive.swift`. A bare
/// `GlanceActionQueue` here would resolve to the copy -- target declarations
/// win over imported ones -- and quietly test one side against itself, which is
/// the one thing these tests exist to rule out.
private typealias PluginAction = glance_widget_ios.GlancePendingAction
private typealias PluginQueue = glance_widget_ios.GlanceActionQueue

/// The queue is the only channel between a widget button and the Flutter app.
///
/// A button on iOS 17 runs its `AppIntent` inside the widget extension, which
/// cannot reach the Dart isolate and may be the only part of the app alive. It
/// writes the interaction to the App Group; the plugin drains it later. Both
/// halves encode the same struct from hand-written copies, so these assert the
/// wire format rather than round-tripping through one side's own encoder: a
/// drift does not crash, it silently loses every tap the user makes.
struct GlanceActionQueueTests {

    private func action(
        _ id: String = "todo",
        type: String = "checkboxToggle",
        payload: [String: String]? = nil,
        at timestamp: Double = 1_700_000_000
    ) -> PluginAction {
        PluginAction(widgetId: id, type: type, payload: payload, timestamp: timestamp)
    }

    // MARK: - Wire format

    /// These four names are typed out again in `GlanceInteractive.swift` in the
    /// widget templates. Renaming one here without renaming it there makes
    /// every queued action undecodable, and `decode` drops what it cannot
    /// read -- so the failure would be silent.
    @Test("the encoded keys are exactly what the widget extension writes")
    func wireFormat() throws {
        let encoded = try #require(PluginQueue.encode([
            action(payload: ["itemIndex": "2", "value": "true"])
        ]).first)
        let json = try #require(
            try JSONSerialization.jsonObject(with: encoded) as? [String: Any]
        )

        #expect(Set(json.keys) == ["widgetId", "type", "payload", "timestamp"])
        #expect(json["widgetId"] as? String == "todo")
        #expect(json["type"] as? String == "checkboxToggle")
        #expect(json["timestamp"] as? Double == 1_700_000_000)
        #expect(json["payload"] as? [String: String] == ["itemIndex": "2", "value": "true"])
    }

    @Test("an action survives the round trip the two processes make")
    func roundTrip() {
        let original = action(payload: ["itemIndex": "0", "value": "false"])

        #expect(PluginQueue.decode(PluginQueue.encode([original])) == [original])
    }

    /// The queue can hold entries written by an older build of the extension
    /// that shipped in the developer's own project. One of those must not take
    /// the readable entries around it with it.
    @Test("an unreadable entry is skipped, not fatal")
    func unreadableEntry() {
        let good = action()
        let items = PluginQueue.encode([good])
            + [Data("not json".utf8)]
            + PluginQueue.encode([action("other")])

        let decoded = PluginQueue.decode(items)

        #expect(decoded.count == 2)
        #expect(decoded.map(\.widgetId) == ["todo", "other"])
    }

    // MARK: - Capacity

    @Test("actions keep the order they were made in")
    func ordering() {
        var queue: [PluginAction] = []
        for index in 0..<5 {
            queue = PluginQueue.appending(action("w\(index)"), to: queue)
        }

        #expect(queue.map(\.widgetId) == ["w0", "w1", "w2", "w3", "w4"])
    }

    /// An app that is never opened again would otherwise grow this without
    /// limit in storage the user cannot see or clear.
    @Test("the queue is capped, and it is the oldest that go")
    func capacity() {
        var queue: [PluginAction] = []
        for index in 0..<(PluginQueue.capacity + 10) {
            queue = PluginQueue.appending(action("w\(index)"), to: queue)
        }

        #expect(queue.count == PluginQueue.capacity)
        #expect(queue.first?.widgetId == "w10")
        #expect(queue.last?.widgetId == "w\(PluginQueue.capacity + 9)")
    }

    @Test("a queue exactly at capacity is not trimmed")
    func exactlyAtCapacity() {
        var queue: [PluginAction] = []
        for index in 0..<PluginQueue.capacity {
            queue = PluginQueue.appending(action("w\(index)"), to: queue)
        }

        #expect(queue.count == PluginQueue.capacity)
        #expect(queue.first?.widgetId == "w0")
    }

    // MARK: - Event payload

    /// Dart's `GlanceWidgetAction` reads `itemIndex` as an `int` and `value` as
    /// a `bool`. The queue can only store strings and stay `Codable` without a
    /// type tag, so the types are restored here -- by the same rules the URL
    /// path already uses for a tap that launches the app, so an action means
    /// the same thing whichever way it arrives.
    @Test("payload strings become the types Dart reads")
    func payloadTypes() throws {
        let payload = try #require(PluginQueue.eventPayload(
            for: action(payload: ["itemIndex": "3", "value": "true", "label": "Milk"])
        ))

        #expect(payload["itemIndex"] as? Int == 3)
        #expect(payload["value"] as? Bool == true)
        #expect(payload["label"] as? String == "Milk")
    }

    @Test("false is a bool, not the string")
    func falseIsABool() throws {
        let payload = try #require(
            PluginQueue.eventPayload(for: action(payload: ["value": "false"]))
        )

        #expect(payload["value"] as? Bool == false)
    }

    @Test("a negative index is still an index")
    func negativeIndex() throws {
        let payload = try #require(
            PluginQueue.eventPayload(for: action(payload: ["itemIndex": "-1"]))
        )

        #expect(payload["itemIndex"] as? Int == -1)
    }

    /// `sendActionEvent` omits the payload key entirely when there is nothing
    /// in it, and Dart distinguishes an absent payload from an empty map.
    @Test("no payload and an empty payload both come through as nothing")
    func emptyPayload() {
        #expect(PluginQueue.eventPayload(for: action(payload: nil)) == nil)
        #expect(PluginQueue.eventPayload(for: action(payload: [:])) == nil)
    }
}
