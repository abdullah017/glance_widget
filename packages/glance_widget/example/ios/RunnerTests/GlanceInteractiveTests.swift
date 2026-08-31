import Foundation
import Testing

/// The widget extension's half of the interactive-widget contract.
///
/// `GlanceInteractive.swift` is compiled into this target directly from the
/// templates directory, so these run against the file a developer copies into
/// their own widget extension rather than a transcription of it.
///
/// The intent itself is not exercised here -- `perform()` needs an App Group
/// container and a live `WidgetCenter`. What is pinned is the decision it
/// makes and the format it writes, which is where a wrong answer is silent:
/// the box springs back, or the app never hears about the tap.
struct GlanceInteractiveTests {

    private func item(_ text: String, checked: Bool = false) -> ListItemData {
        ListItemData(text: text, checked: checked, secondaryText: nil, iconName: nil)
    }

    // MARK: - Toggling

    @Test("an unchecked item becomes checked")
    func checks() throws {
        let toggled = try #require(
            GlanceListToggle.toggling([item("Milk"), item("Eggs")], at: 1)
        )

        #expect(toggled.map(\.checked) == [false, true])
    }

    @Test("a checked item becomes unchecked")
    func unchecks() throws {
        let toggled = try #require(
            GlanceListToggle.toggling([item("Milk", checked: true)], at: 0)
        )

        #expect(toggled[0].checked == false)
    }

    @Test("everything else about the item is left alone")
    func preservesTheRest() throws {
        let original = ListItemData(
            text: "Milk", checked: false, secondaryText: "2 litres", iconName: "cart"
        )

        let toggled = try #require(GlanceListToggle.toggling([original], at: 0))

        #expect(toggled[0].text == original.text)
        #expect(toggled[0].secondaryText == original.secondaryText)
        #expect(toggled[0].iconName == original.iconName)
    }

    @Test("the other items are untouched")
    func leavesNeighbours() throws {
        let items = [item("a", checked: true), item("b"), item("c", checked: true)]

        let toggled = try #require(GlanceListToggle.toggling(items, at: 1))

        #expect(toggled.map(\.checked) == [true, true, true])
    }

    /// A widget on screen can be several updates behind what is stored, so the
    /// user taps row four of a list that now has two. Nothing should be
    /// written: the widget reloads and shows the real list.
    @Test("an index past the end of the list changes nothing", arguments: [2, 5, -1])
    func outOfRange(index: Int) {
        #expect(GlanceListToggle.toggling([item("a"), item("b")], at: index) == nil)
    }

    @Test("an empty list has nothing to toggle")
    func emptyList() {
        #expect(GlanceListToggle.toggling([], at: 0) == nil)
    }

    // MARK: - Queue

    /// These names are typed out again in the plugin's `GlancePendingAction`,
    /// which this side cannot import. `GlanceActionQueueTests` asserts the same
    /// four from there; both have to agree or every queued tap is dropped in
    /// silence when the plugin fails to decode it.
    @Test("the extension writes the keys the plugin decodes")
    func wireFormat() throws {
        let action = GlancePendingAction(
            widgetId: "todo",
            type: "checkboxToggle",
            payload: ["itemIndex": "2", "value": "true"],
            timestamp: 1_700_000_000
        )

        let encoded = try #require(GlanceActionQueue.appending(action, to: []).first)
        let json = try #require(
            try JSONSerialization.jsonObject(with: encoded) as? [String: Any]
        )

        #expect(Set(json.keys) == ["widgetId", "type", "payload", "timestamp"])
        #expect(json["widgetId"] as? String == "todo")
        #expect(json["type"] as? String == "checkboxToggle")
        #expect(json["timestamp"] as? Double == 1_700_000_000)
        #expect(json["payload"] as? [String: String] == ["itemIndex": "2", "value": "true"])
    }

    /// The plugin drops the oldest past its own `capacity`. If the extension
    /// kept more, the queue would still be trimmed -- just later, and by the
    /// other side -- so the two constants have to be the same number.
    @Test("the extension caps the queue at the same size the plugin does")
    func capacity() {
        let action = GlancePendingAction(
            widgetId: "todo", type: "checkboxToggle", payload: nil, timestamp: 1
        )
        var queue: [Data] = []
        for _ in 0..<(GlanceActionQueue.capacity + 10) {
            queue = GlanceActionQueue.appending(action, to: queue)
        }

        #expect(GlanceActionQueue.capacity == 100)
        #expect(queue.count == GlanceActionQueue.capacity)
    }

    /// The plugin reads this key. It is a string literal on both sides because
    /// neither can import the other.
    @Test("the queue is stored under the key the plugin drains")
    func storageKey() {
        #expect(GlanceActionQueue.storageKey == "pendingWidgetActions")
    }
}
