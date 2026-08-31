import SwiftUI
import WidgetKit

// MARK: - Formatting

/// Number formatting shared by the lock screen layouts.
///
/// Pulled out of the templates so a value reads the same whether it is drawn
/// on the home screen or beside the clock, and so it can be tested without a
/// render: `GlanceAccessoryFormatTests` covers the edges the inline `if value
/// == value.rounded() { String(Int(value)) }` in the templates traps on.
enum GlanceAccessoryFormat {

    /// Renders [value] the way the home screen templates do: whole numbers
    /// without a decimal point, everything else to one place.
    ///
    /// The templates write this as `if value == value.rounded() { String(Int(value)) }`,
    /// which traps on an infinity and on anything past `Int.max` -- both are
    /// equal to their own `rounded()`, and `Int(_:)` refuses both. A NaN takes
    /// the other arm and prints "nan". None of that is reachable from the
    /// plugin's own API, but the payload arrives over a method channel and a
    /// widget extension that traps leaves a blank rectangle the user cannot
    /// remove, so the non-finite cases are answered here instead.
    static func value(_ value: Double) -> String {
        guard value.isFinite else { return "--" }
        guard value.magnitude < 1e15 else { return String(format: "%.0f", value) }
        if value == value.rounded() {
            return String(Int(value))
        }
        return String(format: "%.1f", value)
    }

    /// Renders [progress] as a whole percentage, clamped to 0...100.
    static func percent(_ progress: Double) -> String {
        guard progress.isFinite else { return "--%" }
        return "\(Int((progress.clamped01() * 100).rounded()))%"
    }
}

extension Double {
    /// This value pinned into 0...1, with a NaN read as empty.
    ///
    /// A `Gauge` given a value outside its range draws past its own track, and
    /// given a NaN draws nothing while logging. Both infinities clamp like any
    /// other number; a NaN compares false against everything, so `min`/`max`
    /// would carry it straight through and it is answered first.
    func clamped01() -> Double {
        guard !isNaN else { return 0 }
        return Swift.min(Swift.max(self, 0), 1)
    }
}

// MARK: - Circular

/// A circular accessory showing one short value, over an optional caption.
///
/// The lock screen tints everything a single colour, so this deliberately
/// carries no theme: `WidgetThemeData.accentColor` would be quietly discarded
/// by the renderer, and a template that passed it would read as if it worked.
struct GlanceCircularText: View {
    /// The line drawn large in the middle.
    let value: String

    /// A smaller line under it, if there is room for one.
    var caption: String?

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 0) {
                Text(value)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .minimumScaleFactor(0.4)
                    .lineLimit(1)
                if let caption, !caption.isEmpty {
                    Text(caption)
                        .font(.system(size: 10))
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                }
            }
            .padding(6)
        }
        .clipShape(Circle())
    }
}

/// A circular accessory drawn as a ring, with [label] inside it.
struct GlanceCircularGauge: View {
    /// How far round the ring runs, 0 to 1.
    let progress: Double

    /// The text in the middle. Kept to three or four characters.
    let label: String

    var body: some View {
        Gauge(value: progress.clamped01()) {
            EmptyView()
        } currentValueLabel: {
            Text(label)
                .minimumScaleFactor(0.4)
                .lineLimit(1)
        }
        .gaugeStyle(.accessoryCircularCapacity)
    }
}

// MARK: - Rectangular

/// The rectangular slot: an accented title, then up to two lines under it.
///
/// `widgetAccentable()` marks the title as the part the system draws in the
/// user's accent colour when the lock screen is set to accented rendering; the
/// rest stays in the plain tint. Without it the whole view is one flat colour
/// and the title stops reading as a heading.
struct GlanceRectangularStack<Content: View>: View {
    /// The heading line.
    let title: String

    /// What goes under it.
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.headline)
                .lineLimit(1)
                .widgetAccentable()
            content
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

/// A thin capacity bar for the rectangular slot, labelled on both ends.
struct GlanceRectangularGauge: View {
    /// How full the bar is, 0 to 1.
    let progress: Double

    /// The name of what is being measured.
    let label: String

    /// The reading, drawn right-aligned above the bar.
    let value: String

    var body: some View {
        Gauge(value: progress.clamped01()) {
            EmptyView()
        } currentValueLabel: {
            HStack(spacing: 4) {
                Text(label).lineLimit(1)
                Spacer(minLength: 2)
                Text(value).lineLimit(1)
            }
            .font(.system(size: 11))
        }
        .gaugeStyle(.accessoryLinearCapacity)
    }
}

// MARK: - Sparkline

/// The chart reduced to a bare line, for the rectangular slot.
///
/// The home screen chart draws grid lines, dots and a gradient fill. None of
/// those survive a single tint colour in a 160x72pt box, so this draws the
/// shape only -- which is the part that carries the information.
struct GlanceSparkline: Shape {
    /// The values to plot, left to right.
    let dataPoints: [Double]

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let usable = dataPoints.filter { $0.isFinite }
        guard usable.count > 1 else { return path }

        let minValue = usable.min() ?? 0
        let maxValue = usable.max() ?? 0
        let range = maxValue - minValue
        let step = rect.width / CGFloat(usable.count - 1)

        for (index, value) in usable.enumerated() {
            // A flat series has no range to scale into; draw it down the
            // middle rather than dividing by zero.
            let fraction = range == 0 ? 0.5 : (value - minValue) / range
            let point = CGPoint(
                x: rect.minX + CGFloat(index) * step,
                y: rect.maxY - CGFloat(fraction) * rect.height
            )
            if index == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        return path
    }
}

// MARK: - Container background

/// Paints the theme's background behind a home screen widget, and leaves an
/// accessory family transparent.
///
/// Every template ends `.containerBackground(for: .widget) { themeColour }`,
/// which is right on the home screen and wrong on the lock screen: an
/// accessory widget sits on the user's wallpaper and is expected to be
/// see-through, and the parts that want a backdrop ask for
/// `AccessoryWidgetBackground()` themselves. The family is read from the
/// environment here because the widget's content closure -- the only place the
/// modifier can go -- is handed an entry and not a family.
struct GlanceContainerBackground: ViewModifier {
    /// The colour a home screen widget is drawn on.
    let color: Color

    @Environment(\.widgetFamily) private var family

    @ViewBuilder
    func body(content: Content) -> some View {
        if GlanceAccessorySize(family) == nil {
            content.containerBackground(for: .widget) { color }
        } else {
            content.containerBackground(for: .widget) { Color.clear }
        }
    }
}

extension View {
    /// Applies `GlanceContainerBackground` with the widget's own background.
    func glanceContainerBackground(_ color: Color) -> some View {
        modifier(GlanceContainerBackground(color: color))
    }
}
