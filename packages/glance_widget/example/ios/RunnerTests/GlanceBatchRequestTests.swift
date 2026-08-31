import Foundation
import Testing

@testable import glance_widget_ios

/// The Dart side writes this payload and `GlanceBatchRequest` reads it. The
/// Dart, Kotlin and Swift tests all pin the same key names, because a rename
/// that lands on only one side is silent -- the native side simply reads nil
/// forever, which is exactly how `imageFit` went unread for a release.
struct GlanceBatchRequestTests {

    private func entries(_ parsed: GlanceBatchParse) throws -> [GlanceBatchEntry] {
        guard case .ok(let entries) = parsed else {
            Issue.record("expected a parsed batch, got \(parsed)")
            throw CancellationError()
        }
        return entries
    }

    private func reason(_ parsed: GlanceBatchParse) throws -> String {
        guard case .invalid(let reason) = parsed else {
            Issue.record("expected a rejection, got \(parsed)")
            throw CancellationError()
        }
        return reason
    }

    private func update(
        _ widgetId: String,
        template: String = "simple",
        data: [String: Any] = ["title": "T", "value": "1"],
        theme: [String: Any]? = nil
    ) -> [String: Any] {
        var update: [String: Any] = [
            "widgetId": widgetId,
            "template": template,
            "data": data,
        ]
        if let theme { update["theme"] = theme }
        return update
    }

    private let darkTheme: [String: Any] = ["isDark": true]
    private let lightTheme: [String: Any] = ["isDark": false]

    @Test("reads the updates in the order they were sent")
    func preservesOrder() throws {
        let parsed = GlanceBatchRequest.parse([
            "updates": [update("a"), update("b"), update("c")]
        ])

        #expect(try entries(parsed).map(\.widgetId) == ["a", "b", "c"])
    }

    @Test("the batch theme applies to every widget that has none of its own")
    func batchThemeFillsIn() throws {
        let parsed = GlanceBatchRequest.parse([
            "theme": darkTheme,
            "updates": [update("a"), update("b")],
        ])

        for entry in try entries(parsed) {
            #expect(entry.theme?["isDark"] as? Bool == true)
        }
    }

    @Test("a widget's own theme wins over the batch theme")
    func ownThemeWins() throws {
        let parsed = GlanceBatchRequest.parse([
            "theme": darkTheme,
            "updates": [update("a"), update("b", theme: lightTheme)],
        ])

        let parsedEntries = try entries(parsed)
        #expect(parsedEntries[0].theme?["isDark"] as? Bool == true)
        #expect(parsedEntries[1].theme?["isDark"] as? Bool == false)
    }

    @Test("no theme anywhere leaves the widget without one")
    func noThemeAtAll() throws {
        let parsed = GlanceBatchRequest.parse(["updates": [update("a")]])

        #expect(try entries(parsed).first?.theme == nil)
    }

    @Test("an explicit null theme is read as absent, not as a value")
    func nullThemeIsAbsent() throws {
        let parsed = GlanceBatchRequest.parse([
            "theme": NSNull(),
            "updates": [update("a")],
        ])

        #expect(try entries(parsed).first?.theme == nil)
    }

    @Test("the payload is carried through untouched")
    func payloadUntouched() throws {
        let parsed = GlanceBatchRequest.parse([
            "updates": [update("a", data: ["title": "T", "progress": 0.25])]
        ])

        let data = try #require(try entries(parsed).first?.data)
        #expect(data["title"] as? String == "T")
        #expect(data["progress"] as? Double == 0.25)
    }

    @Test("the template travels with each entry so a batch can mix them")
    func mixedTemplates() throws {
        let parsed = GlanceBatchRequest.parse([
            "updates": [
                update("a", template: "simple"),
                update("b", template: "chart"),
                update("c", template: "gauge"),
            ]
        ])

        #expect(try entries(parsed).map(\.template) == ["simple", "chart", "gauge"])
    }

    @Test("an empty updates list parses to an empty batch rather than an error")
    func emptyBatch() throws {
        #expect(try entries(GlanceBatchRequest.parse(["updates": [Any]()])).isEmpty)
    }

    // The same widget twice would race: whichever landed last would win, and
    // the caller would have no way to know which.
    @Test("the same widgetId twice is refused")
    func duplicateWidgetId() throws {
        let message = try reason(
            GlanceBatchRequest.parse(["updates": [update("same"), update("same")]])
        )

        #expect(message.contains("same"))
        #expect(message.contains("more than once"))
    }

    @Test("an empty widgetId is refused")
    func emptyWidgetId() throws {
        #expect(try reason(GlanceBatchRequest.parse(["updates": [update("")]]))
            .contains("empty widgetId"))
    }

    @Test("an entry with no template is refused")
    func missingTemplate() throws {
        let entry: [String: Any] = ["widgetId": "a", "data": ["title": "T"]]

        #expect(try reason(GlanceBatchRequest.parse(["updates": [entry]]))
            .contains("no template"))
    }

    @Test("an entry with no data is refused")
    func missingData() throws {
        let entry: [String: Any] = ["widgetId": "a", "template": "simple"]

        #expect(try reason(GlanceBatchRequest.parse(["updates": [entry]]))
            .contains("no data"))
    }

    @Test("arguments that are not a map at all are refused")
    func notAMap() {
        if case .ok = GlanceBatchRequest.parse("nonsense") {
            Issue.record("a string should not parse as a batch")
        }
        if case .ok = GlanceBatchRequest.parse(nil) {
            Issue.record("nil should not parse as a batch")
        }
    }

    @Test("a missing updates key is refused")
    func missingUpdates() throws {
        #expect(try reason(GlanceBatchRequest.parse(["theme": darkTheme]))
            .contains("updates"))
    }

    @Test("updates that is not a list is refused")
    func updatesNotAList() throws {
        #expect(try reason(GlanceBatchRequest.parse(["updates": "one"]))
            .contains("must be a list"))
    }

    @Test("the offending index is named so the caller can find it")
    func namesTheIndex() throws {
        #expect(try reason(
            GlanceBatchRequest.parse(["updates": [update("a"), "not a map"]])
        ).contains("updates[1]"))
    }
}
