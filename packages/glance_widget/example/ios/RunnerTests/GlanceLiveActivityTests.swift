import Foundation
import Testing
@testable import glance_widget_ios

/// The plugin declares `GlanceActivityAttributes` in its own module; the
/// widget extension declares its own copy, because an extension cannot import
/// a Swift package. ActivityKit matches a running activity to the presentation
/// that draws it by the attributes **type name and the shape of
/// `ContentState`** -- measured on a simulator, see
/// `findings-live-activity-module-boundary.md`.
///
/// Nothing on either side fails to compile when one of them drifts. The
/// activity simply stops appearing, on a user's Lock Screen, with no error
/// anywhere. This target is the only place both copies exist at once, so it is
/// the only place that can compare them.
///
/// Neither side is named with a bare `GlanceActivityAttributes`: that resolves
/// to whichever copy is target-local, so a rename on the template side would
/// silently make this compare the plugin's copy against itself and pass. The
/// plugin's is module-qualified; the template's is reached through an alias the
/// template file declares for exactly this reason.
private typealias PluginAttributes = glance_widget_ios.GlanceActivityAttributes
private typealias PluginStat = glance_widget_ios.GlanceActivityStat
private typealias TemplateAttributes = GlanceTemplateActivityAttributes
private typealias TemplateStat = GlanceTemplateActivityStat

struct GlanceLiveActivityContractTests {

    @Test("both copies are called GlanceActivityAttributes")
    func typeNamesMatch() {
        #expect(
            String(describing: TemplateAttributes.self)
                == String(describing: PluginAttributes.self)
        )
        #expect(String(describing: PluginAttributes.self) == "GlanceActivityAttributes")
    }

    @Test("both copies of ContentState encode the same keys")
    func contentStateShapesMatch() throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys

        let plugin = try encoder.encode(
            PluginAttributes.ContentState(
                title: "T", status: "S", progress: 0.5,
                stats: [PluginStat(label: "L", value: "V")]
            )
        )
        let template = try encoder.encode(
            TemplateAttributes.ContentState(
                title: "T", status: "S", progress: 0.5,
                stats: [TemplateStat(label: "L", value: "V")]
            )
        )

        // Byte equality, not key equality: a field that changed type -- a
        // `Double` progress becoming a `String` -- keeps every key and still
        // breaks the match.
        #expect(plugin == template)
    }

    @Test("an omitted progress encodes the same on both sides")
    func nilProgressMatches() throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys

        let plugin = try encoder.encode(
            PluginAttributes.ContentState(
                title: "T", status: "S", progress: nil, stats: []
            )
        )
        let template = try encoder.encode(
            TemplateAttributes.ContentState(
                title: "T", status: "S", progress: nil, stats: []
            )
        )

        #expect(plugin == template)
    }

    @Test("the attributes carry the caller's own id")
    func attributesCarryTheId() {
        // ActivityKit assigns an id Dart never sees. This is what `update` and
        // `end` look an activity up by, so it has to survive into the
        // attributes rather than being kept in memory.
        #expect(PluginAttributes(activityId: "delivery-42").activityId == "delivery-42")
    }
}

/// What arrives from Dart is `[String: Any]` off a method channel, so the
/// parsing is where a wrong assumption turns into an activity that never
/// starts.
struct GlanceLiveActivityContentTests {

    private func map(
        title: Any? = "Order on its way",
        status: Any? = "12 min away",
        progress: Any? = 0.4,
        stats: Any? = [
            ["label": "Driver", "value": "Sam"],
            ["label": "Items", "value": "3"],
        ]
    ) -> [String: Any] {
        var out: [String: Any] = [:]
        if let title { out["title"] = title }
        if let status { out["status"] = status }
        if let progress { out["progress"] = progress }
        if let stats { out["stats"] = stats }
        return out
    }

    @Test("a full payload round-trips")
    func fullPayload() throws {
        let state = try PluginAttributes.ContentState.from(map())

        #expect(state.title == "Order on its way")
        #expect(state.status == "12 min away")
        #expect(state.progress == 0.4)
        #expect(state.stats.map(\.label) == ["Driver", "Items"])
    }

    @Test("stats keep the order they were written in")
    func statsKeepOrder() throws {
        // They cross as a list of pairs rather than a dictionary for exactly
        // this reason: a dictionary has no order to carry, and these are drawn
        // left to right.
        let state = try PluginAttributes.ContentState.from(
            map(stats: [
                ["label": "C", "value": "3"],
                ["label": "A", "value": "1"],
                ["label": "B", "value": "2"],
            ])
        )

        #expect(state.stats.map(\.label) == ["C", "A", "B"])
    }

    @Test("progress is optional")
    func progressOptional() throws {
        let state = try PluginAttributes.ContentState.from(map(progress: nil))
        #expect(state.progress == nil)
    }

    @Test("stats are optional")
    func statsOptional() throws {
        let state = try PluginAttributes.ContentState.from(map(stats: nil))
        #expect(state.stats.isEmpty)
    }

    @Test("a half-written stat is dropped rather than failing the whole update")
    func partialStatDropped() throws {
        // The title and the status are why the activity is on screen; one
        // malformed extra is not worth losing them over.
        let state = try PluginAttributes.ContentState.from(
            map(stats: [["label": "Driver"], ["label": "Items", "value": "3"]])
        )

        #expect(state.stats.map(\.label) == ["Items"])
    }

    @Test("a missing title is refused")
    func missingTitle() {
        #expect(throws: GlanceLiveActivityError.malformedContent) {
            _ = try PluginAttributes.ContentState.from(map(title: nil))
        }
    }

    @Test("a missing status is refused")
    func missingStatus() {
        #expect(throws: GlanceLiveActivityError.malformedContent) {
            _ = try PluginAttributes.ContentState.from(map(status: nil))
        }
    }

    @Test("something that is not a map at all is refused")
    func notAMap() {
        #expect(throws: GlanceLiveActivityError.malformedContent) {
            _ = try PluginAttributes.ContentState.from("Order on its way")
        }
    }

    @Test("a title of the wrong type is refused rather than described")
    func wrongTypeTitle() {
        // `"\(any)"` would happily turn 42 into "42" and put it on the Lock
        // Screen. A caller sending a number meant something else.
        #expect(throws: GlanceLiveActivityError.malformedContent) {
            _ = try PluginAttributes.ContentState.from(map(title: 42))
        }
    }

    @Test("every error code is distinct")
    func errorCodesAreDistinct() {
        // These reach Dart as the `code` on a platform exception, so they are
        // API. Two sharing a spelling would make them indistinguishable there.
        let codes = [
            GlanceLiveActivityError.unsupportedVersion,
            .notEnabled,
            .alreadyRunning,
            .notFound,
            .malformedContent,
        ].map(\.rawValue)

        #expect(Set(codes).count == codes.count)
        #expect(codes.allSatisfy { $0.hasPrefix("LIVE_ACTIVITY_") })
    }
}
