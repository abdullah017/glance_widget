import Testing
@testable import glance_widget_ios

/// The App Group identifier decides which `UserDefaults` suite the plugin
/// writes to. It shipped as a hardcoded `group.com.example.glancewidget` that
/// nothing in the plugin ever assigned -- no Dart API, no method channel, no
/// Info.plist read. An app whose App Group was anything else had the plugin
/// writing to a suite it holds no entitlement for, so `UserDefaults(suiteName:)`
/// handed back nil and every widget update quietly did nothing. The widget sat
/// on placeholder data and nothing anywhere said why.
///
/// The doc comment made it worse by saying "users must configure this in their
/// app's entitlements", which is not a thing that changes a constant in Swift.
struct GlanceAppGroupTests {

    @Test("the app's declared group wins")
    func infoPlistWins() {
        let resolved = GlanceAppGroup.resolve(
            infoPlist: ["GlanceWidgetAppGroup": "group.com.acme.tracker"]
        )

        #expect(resolved.identifier == "group.com.acme.tracker")
        #expect(resolved.isFallback == false)
    }

    @Test("an explicit override beats the Info.plist")
    func overrideWins() {
        // Set from an AppDelegate. Rare, but it was the only escape hatch that
        // ever existed, so it keeps working.
        let resolved = GlanceAppGroup.resolve(
            infoPlist: ["GlanceWidgetAppGroup": "group.com.acme.tracker"],
            override: "group.com.acme.other"
        )

        #expect(resolved.identifier == "group.com.acme.other")
        #expect(resolved.isFallback == false)
    }

    @Test("a missing key falls back, and says that it did")
    func missingKeyIsReported() {
        let resolved = GlanceAppGroup.resolve(infoPlist: [:])

        #expect(resolved.identifier == "group.com.example.glancewidget")
        // The flag is the whole point: the old code could not tell a deliberate
        // choice from a default nobody had noticed.
        #expect(resolved.isFallback)
    }

    @Test("no Info.plist at all falls back")
    func noPlistIsReported() {
        #expect(GlanceAppGroup.resolve(infoPlist: nil).isFallback)
    }

    @Test("blank and whitespace values are not identifiers")
    func blankIsRejected() {
        // An unsubstituted build setting arrives as an empty string. Treating it
        // as a group name would fail later and further away.
        #expect(GlanceAppGroup.resolve(infoPlist: ["GlanceWidgetAppGroup": ""]).isFallback)
        #expect(GlanceAppGroup.resolve(infoPlist: ["GlanceWidgetAppGroup": "   "]).isFallback)
        #expect(GlanceAppGroup.resolve(infoPlist: ["GlanceWidgetAppGroup": "$(APP_GROUP)"]).isFallback)
    }

    @Test("a value of the wrong type falls back rather than crashing")
    func wrongTypeIsRejected() {
        #expect(GlanceAppGroup.resolve(infoPlist: ["GlanceWidgetAppGroup": 42]).isFallback)
        #expect(GlanceAppGroup.resolve(infoPlist: ["GlanceWidgetAppGroup": ["a"]]).isFallback)
    }

    @Test("surrounding whitespace is trimmed, because plists collect it")
    func whitespaceIsTrimmed() {
        let resolved = GlanceAppGroup.resolve(
            infoPlist: ["GlanceWidgetAppGroup": "  group.com.acme.tracker\n"]
        )

        #expect(resolved.identifier == "group.com.acme.tracker")
        #expect(resolved.isFallback == false)
    }

    @Test("an identifier that is not an App Group is reported, not accepted")
    func nonGroupPrefixIsRejected() {
        // A bundle id pasted in by mistake. UserDefaults(suiteName:) would
        // return nil and the symptom would be identical to having no group.
        let resolved = GlanceAppGroup.resolve(
            infoPlist: ["GlanceWidgetAppGroup": "com.acme.tracker"]
        )

        #expect(resolved.isFallback)
    }
}
