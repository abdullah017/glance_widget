import CoreGraphics
import SwiftUI
import Testing
import WidgetKit

/// The lock screen layouts are the one part of the widget templates nothing
/// renders in CI: the extension build proves they compile, and a simulator
/// would be needed to prove they draw. What can be pinned without a render is
/// the arithmetic they hand to SwiftUI, and that is where the bugs live -- a
/// family classified wrong, a `Gauge` handed a NaN, a divide by a `maxValue`
/// of zero.
///
/// These types are compiled into this test target directly from
/// `packages/glance_widget_ios/example/ios/GlanceWidgets/`, so a change to the
/// template a developer copies is a change to the code under test here.
struct GlanceFamilyTests {

    // MARK: - System families

    @Test("each system family gets the layout its size wants", arguments: [
        (WidgetFamily.systemSmall, GlanceSystemSize.small),
        (WidgetFamily.systemMedium, GlanceSystemSize.medium),
        (WidgetFamily.systemLarge, GlanceSystemSize.large),
    ])
    func systemSizes(family: WidgetFamily, expected: GlanceSystemSize) {
        #expect(GlanceSystemSize(family) == expected)
    }

    /// The bug this enum was introduced for. `.systemExtraLarge` is the iPad
    /// family; it has existed since iOS 15 and is not unknown at all, but every
    /// template switched on `WidgetFamily` with an `@unknown default` arm, so
    /// it silently took `systemMedium`'s fonts and padding on a widget more
    /// than twice the size.
    @Test("the iPad family is laid out large, not medium")
    func extraLargeIsLarge() {
        #expect(GlanceSystemSize(.systemExtraLarge) == .large)
    }

    // MARK: - Accessory families

    @Test("each lock screen family is recognised", arguments: [
        (WidgetFamily.accessoryCircular, GlanceAccessorySize.circular),
        (WidgetFamily.accessoryRectangular, GlanceAccessorySize.rectangular),
        (WidgetFamily.accessoryInline, GlanceAccessorySize.inline),
    ])
    func accessorySizes(family: WidgetFamily, expected: GlanceAccessorySize) {
        #expect(GlanceAccessorySize(family) == expected)
    }

    /// The routing in every template's `body` is `if let accessory =
    /// GlanceAccessorySize(family)`. A system family answering non-nil here
    /// would send a home screen widget to the lock screen layout.
    @Test("a system family is not an accessory family", arguments: [
        WidgetFamily.systemSmall,
        WidgetFamily.systemMedium,
        WidgetFamily.systemLarge,
        WidgetFamily.systemExtraLarge,
    ])
    func systemFamiliesAreNotAccessories(family: WidgetFamily) {
        #expect(GlanceAccessorySize(family) == nil)
    }
}

struct GlanceAccessoryFormatTests {

    @Test("a whole number loses its decimal point", arguments: [
        (65.0, "65"), (0.0, "0"), (-4.0, "-4"), (100.0, "100"),
    ])
    func wholeNumbers(value: Double, expected: String) {
        #expect(GlanceAccessoryFormat.value(value) == expected)
    }

    @Test("a fractional number keeps one place", arguments: [
        (4.2, "4.2"), (65.5, "65.5"), (-1.6, "-1.6"), (0.7, "0.7"),
    ])
    func fractions(value: Double, expected: String) {
        #expect(GlanceAccessoryFormat.value(value) == expected)
    }

    /// `String(Int(value))` -- which is what the home screen templates do --
    /// traps on both of these. The lock screen path answers them instead,
    /// because a widget extension that traps leaves a blank rectangle on the
    /// user's lock screen that they cannot remove without editing it.
    @Test("a non-finite value reads as unknown rather than trapping", arguments: [
        Double.infinity, -Double.infinity, Double.nan,
    ])
    func nonFinite(value: Double) {
        #expect(GlanceAccessoryFormat.value(value) == "--")
    }

    @Test("a value past Int's range is printed, not truncated")
    func hugeValue() {
        #expect(GlanceAccessoryFormat.value(1e18) == "1000000000000000000")
    }

    @Test("a percentage is whole and clamped to the bar", arguments: [
        (0.0, "0%"), (0.68, "68%"), (1.0, "100%"), (1.5, "100%"), (-0.2, "0%"),
    ])
    func percentages(progress: Double, expected: String) {
        #expect(GlanceAccessoryFormat.percent(progress) == expected)
    }

    @Test("a non-finite percentage reads as unknown")
    func nonFinitePercent() {
        #expect(GlanceAccessoryFormat.percent(.nan) == "--%")
        #expect(GlanceAccessoryFormat.percent(.infinity) == "--%")
    }

    /// `Gauge(value:)` outside 0...1 draws past its own track, and a NaN makes
    /// it draw nothing while logging. Every fraction on the lock screen goes
    /// through here first.
    @Test("a fraction is pinned into the gauge's range", arguments: [
        (0.5, 0.5), (2.0, 1.0), (-3.0, 0.0), (Double.nan, 0.0),
        (Double.infinity, 1.0), (-Double.infinity, 0.0),
    ])
    func clamping(input: Double, expected: Double) {
        #expect(input.clamped01() == expected)
    }
}

struct GlanceSparklineTests {
    private let box = CGRect(x: 0, y: 0, width: 100, height: 50)

    /// One point is not a line. Drawing it as one would put a dot in a corner
    /// that reads as a trend.
    @Test("fewer than two points draw nothing", arguments: [[Double](), [7.0]])
    func tooFewPoints(points: [Double]) {
        #expect(GlanceSparkline(dataPoints: points).path(in: box).isEmpty)
    }

    /// A flat series has a range of zero. Scaling by it would divide by zero
    /// and hand SwiftUI a NaN coordinate.
    @Test("a flat series is a horizontal line down the middle")
    func flatSeries() {
        let bounds = GlanceSparkline(dataPoints: [3, 3, 3]).path(in: box).boundingRect
        #expect(bounds.minY == box.midY)
        #expect(bounds.maxY == box.midY)
        #expect(bounds.width == box.width)
    }

    @Test("a rising series fills the box, low point to high point")
    func risingSeries() {
        let bounds = GlanceSparkline(dataPoints: [0, 5, 10]).path(in: box).boundingRect
        #expect(bounds.minY == box.minY)
        #expect(bounds.maxY == box.maxY)
        #expect(bounds.width == box.width)
    }

    /// A `Double` decoded from JSON can be a NaN, and one NaN in the series
    /// would otherwise poison `min()` and every coordinate after it.
    @Test("a non-finite reading is dropped rather than poisoning the line")
    func nonFinitePoint() {
        let path = GlanceSparkline(dataPoints: [1, .nan, 3]).path(in: box)
        #expect(!path.isEmpty)
        #expect(path.boundingRect.width == box.width)
    }

    @Test("a series that is entirely unusable draws nothing")
    func allNonFinite() {
        #expect(GlanceSparkline(dataPoints: [.nan, .infinity]).path(in: box).isEmpty)
    }
}
