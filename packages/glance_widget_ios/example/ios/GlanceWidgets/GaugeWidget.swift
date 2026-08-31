import AppIntents
import WidgetKit
import SwiftUI

// MARK: - Configuration

/// The ids this template has data for, offered when the user edits the widget.
struct GaugeWidgetIdOptions: DynamicOptionsProvider {
    func results() async throws -> [String] {
        WidgetStorage.shared.knownWidgetIds(prefix: "gaugeWidgetData_")
    }
}

/// Carries the `widgetId` a placed instance should render.
///
/// `widgetId` is documented as a "unique identifier for this widget instance",
/// and without a per-instance parameter there is nothing for the extension to
/// key on: every placed widget read the most recently written payload, so two
/// widgets built from this template always showed the same thing.
struct GaugeWidgetIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Gauge Widget" }
    static var description: IntentDescription {
        IntentDescription("Choose which of your app's widgets this one shows.")
    }

    @Parameter(title: "Widget", optionsProvider: GaugeWidgetIdOptions())
    var widgetId: String?

    init() {}

    init(widgetId: String?) {
        self.widgetId = widgetId
    }
}

// MARK: - Timeline Provider

struct GaugeWidgetProvider: AppIntentTimelineProvider {
    typealias Entry = GaugeWidgetEntry
    typealias Intent = GaugeWidgetIntent

    func placeholder(in context: Context) -> GaugeWidgetEntry {
        GaugeWidgetEntry(date: Date(), data: .placeholder)
    }

    func snapshot(for configuration: GaugeWidgetIntent, in context: Context) async -> GaugeWidgetEntry {
        GaugeWidgetEntry(date: Date(), data: load(for: configuration))
    }

    func timeline(
        for configuration: GaugeWidgetIntent,
        in context: Context
    ) async -> Timeline<GaugeWidgetEntry> {
        let entry = GaugeWidgetEntry(date: Date(), data: load(for: configuration))

        // Check for configured timeline refresh interval
        let refreshInterval = WidgetStorage.shared.getTimelineRefreshInterval()
        let policy: TimelineReloadPolicy
        if let interval = refreshInterval {
            policy = .after(Date().addingTimeInterval(TimeInterval(interval * 60)))
        } else {
            policy = .never
        }
        return Timeline(entries: [entry], policy: policy)
    }

    /// An unconfigured instance falls back to the most recently updated payload
    /// so a freshly placed widget shows something rather than a placeholder.
    private func load(for configuration: GaugeWidgetIntent) -> GaugeWidgetData {
        WidgetStorage.shared.loadGaugeWidget(widgetId: configuration.widgetId) ?? .placeholder
    }
}

// MARK: - Timeline Entry

struct GaugeWidgetEntry: TimelineEntry {
    let date: Date
    let data: GaugeWidgetData
}

// MARK: - Widget View

struct GaugeWidgetEntryView: View {
    var entry: GaugeWidgetProvider.Entry
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.widgetFamily) var family

    /// The layout shape this family wants. See `GlanceSystemSize`.
    private var size: GlanceSystemSize { GlanceSystemSize(family) }

    private var theme: WidgetThemeData {
        entry.data.theme
            ?? WidgetStorage.shared.loadGlobalTheme()
            ?? (colorScheme == .dark ? .defaultDark : .defaultLight)
    }

    var body: some View {
        if let accessory = GlanceAccessorySize(family) {
            accessoryBody(accessory)
        } else {
            systemBody
        }
    }

    /// The home screen layout. A lock screen family never reaches this: it is
    /// routed to `accessoryBody` first, because scaling this down into 58pt of
    /// single-colour space produces something unreadable rather than something
    /// small.
    @ViewBuilder
    private var systemBody: some View {
        let backgroundColor = Color(argb: theme.backgroundColor)
        let textColor = Color(argb: theme.textColor)
        let secondaryTextColor = Color(argb: theme.secondaryTextColor)

        GeometryReader { geometry in
            ZStack {
                // Background
                RoundedRectangle(cornerRadius: theme.borderRadius)
                    .fill(backgroundColor)

                // Content
                VStack(spacing: contentSpacing(for: size)) {
                    // Title
                    Text(entry.data.title)
                        .font(titleFont(for: size))
                        .fontWeight(.bold)
                        .foregroundColor(textColor)
                        .lineLimit(1)

                    if entry.data.metrics.isEmpty {
                        emptyStateView(secondaryTextColor: secondaryTextColor)
                    } else if entry.data.gaugeType == "dashboard" {
                        dashboardView(
                            textColor: textColor,
                            secondaryTextColor: secondaryTextColor,
                            geometry: geometry
                        )
                    } else {
                        radialView(
                            textColor: textColor,
                            secondaryTextColor: secondaryTextColor,
                            geometry: geometry
                        )
                    }
                }
                .padding(dynamicPadding(for: size))
            }
        }
        .widgetURL(widgetURL)
    }

    // MARK: - Lock Screen

    /// The lock screen and Smart Stack layouts.
    ///
    /// The theme is deliberately not consulted here. The system renders an
    /// accessory family in a single tint of its own choosing, so a view that
    /// passed `theme.accentColor` through would read as if the colour worked
    /// while changing nothing on screen.
    @ViewBuilder
    private func accessoryBody(_ accessory: GlanceAccessorySize) -> some View {
        switch accessory {
        case .circular:
            if let metric = entry.data.metrics.first {
                GlanceCircularGauge(
                    progress: accessoryFraction(metric),
                    label: accessoryReading(metric)
                )
            } else {
                GlanceCircularText(value: "--")
            }
        case .rectangular:
            GlanceRectangularStack(title: entry.data.title) {
                if entry.data.metrics.isEmpty {
                    Text("No metrics")
                        .font(.system(size: 12))
                } else {
                    ForEach(Array(entry.data.metrics.prefix(2).enumerated()), id: \.offset) { _, metric in
                        GlanceRectangularGauge(
                            progress: accessoryFraction(metric),
                            label: metric.label,
                            value: accessoryReading(metric)
                        )
                    }
                }
            }
        case .inline:
            Text(accessoryInlineText)
        }
    }

    /// How full [metric] is, 0 to 1.
    ///
    /// A `maxValue` of zero is what an unset field decodes to, and dividing by
    /// it yields an infinity that a `Gauge` refuses to draw; it reads as empty
    /// instead, which is the truthful answer for a metric with no scale.
    private func accessoryFraction(_ metric: GaugeMetricData) -> Double {
        guard metric.maxValue > 0 else { return 0 }
        return metric.value / metric.maxValue
    }

    /// [metric]'s value with its unit, short enough for a ring.
    private func accessoryReading(_ metric: GaugeMetricData) -> String {
        GlanceAccessoryFormat.value(metric.value) + (metric.unit ?? "")
    }

    /// The first metric, named, or the widget's own title when there are none.
    private var accessoryInlineText: String {
        guard let metric = entry.data.metrics.first else { return entry.data.title }
        return "\(metric.label) \(accessoryReading(metric))"
    }

    // MARK: - Empty State

    @ViewBuilder
    private func emptyStateView(secondaryTextColor: Color) -> some View {
        Spacer()
        HStack {
            Spacer()
            Text("No metrics")
                .font(metricLabelFont(for: size))
                .foregroundColor(secondaryTextColor)
            Spacer()
        }
        Spacer()
    }

    // MARK: - Radial View

    @ViewBuilder
    private func radialView(textColor: Color, secondaryTextColor: Color, geometry: GeometryProxy) -> some View {
        let metricsToShow = metricsForRadial
        let gaugeSize = radialGaugeSize(for: size, geometry: geometry, count: metricsToShow.count)

        if metricsToShow.count == 1 {
            // Single large gauge
            singleRadialGauge(
                metric: metricsToShow[0],
                diameter: gaugeSize,
                textColor: textColor,
                secondaryTextColor: secondaryTextColor
            )
        } else {
            // Multiple gauges in a row
            HStack(spacing: gaugeSpacing(for: size)) {
                ForEach(Array(metricsToShow.enumerated()), id: \.offset) { _, metric in
                    singleRadialGauge(
                        metric: metric,
                        diameter: gaugeSize,
                        textColor: textColor,
                        secondaryTextColor: secondaryTextColor
                    )
                }
            }
        }
    }

    @ViewBuilder
    private func singleRadialGauge(metric: GaugeMetricData, diameter: CGFloat, textColor: Color, secondaryTextColor: Color) -> some View {
        let progress = metric.maxValue > 0 ? min(metric.value / metric.maxValue, 1.0) : 0
        let gaugeColor = metric.color.map { Color(argb: $0) } ?? Color(argb: theme.accentColor)
        let trackColor = secondaryTextColor.opacity(0.3)
        let arcLineWidth = arcWidth(for: size)

        VStack(spacing: 4) {
            ZStack {
                // Track arc (270 degrees, starting from bottom-left)
                Path { path in
                    path.addArc(
                        center: CGPoint(x: diameter / 2, y: diameter / 2),
                        radius: (diameter - arcLineWidth) / 2,
                        startAngle: .degrees(135),
                        endAngle: .degrees(405),
                        clockwise: false
                    )
                }
                .stroke(trackColor, style: StrokeStyle(lineWidth: arcLineWidth, lineCap: .round))

                // Progress arc
                Path { path in
                    path.addArc(
                        center: CGPoint(x: diameter / 2, y: diameter / 2),
                        radius: (diameter - arcLineWidth) / 2,
                        startAngle: .degrees(135),
                        endAngle: .degrees(135 + 270 * progress),
                        clockwise: false
                    )
                }
                .stroke(gaugeColor, style: StrokeStyle(lineWidth: arcLineWidth, lineCap: .round))

                // Value text
                VStack(spacing: 0) {
                    Text(formattedValue(metric.value))
                        .font(gaugeValueFont(for: size))
                        .fontWeight(.bold)
                        .foregroundColor(textColor)

                    if let unit = metric.unit, !unit.isEmpty {
                        Text(unit)
                            .font(gaugeUnitFont(for: size))
                            .foregroundColor(secondaryTextColor)
                    }
                }
            }
            .frame(width: diameter, height: diameter)

            // Label
            Text(metric.label)
                .font(metricLabelFont(for: size))
                .foregroundColor(secondaryTextColor)
                .lineLimit(1)
        }
    }

    // MARK: - Dashboard View

    @ViewBuilder
    private func dashboardView(textColor: Color, secondaryTextColor: Color, geometry: GeometryProxy) -> some View {
        let metricsToShow = metricsForDashboard

        if size == .small {
            VStack(spacing: dashboardSpacing(for: size)) {
                ForEach(Array(metricsToShow.enumerated()), id: \.offset) { _, metric in
                    dashboardMetricCard(
                        metric: metric,
                        textColor: textColor,
                        secondaryTextColor: secondaryTextColor,
                        geometry: geometry
                    )
                }
            }
        } else {
            let columns = size == .large ? 2 : 2
            let rows = metricsToShow.chunked(into: columns)

            VStack(spacing: dashboardSpacing(for: size)) {
                ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                    HStack(spacing: dashboardSpacing(for: size)) {
                        ForEach(Array(row.enumerated()), id: \.offset) { _, metric in
                            dashboardMetricCard(
                                metric: metric,
                                textColor: textColor,
                                secondaryTextColor: secondaryTextColor,
                                geometry: geometry
                            )
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func dashboardMetricCard(
        metric: GaugeMetricData,
        textColor: Color,
        secondaryTextColor: Color,
        geometry: GeometryProxy
    ) -> some View {
        let progress = metric.maxValue > 0 ? min(metric.value / metric.maxValue, 1.0) : 0
        let metricColor = metric.color.map { Color(argb: $0) } ?? Color(argb: theme.accentColor)

        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(metric.label)
                    .font(metricLabelFont(for: size))
                    .foregroundColor(secondaryTextColor)
                    .lineLimit(1)

                Spacer()

                HStack(spacing: 2) {
                    Text(formattedValue(metric.value))
                        .font(metricValueFont(for: size))
                        .fontWeight(.semibold)
                        .foregroundColor(textColor)

                    if let unit = metric.unit, !unit.isEmpty {
                        Text(unit)
                            .font(metricUnitFont(for: size))
                            .foregroundColor(secondaryTextColor)
                    }
                }
            }

            // Progress bar
            GeometryReader { barGeometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(secondaryTextColor.opacity(0.2))

                    RoundedRectangle(cornerRadius: 3)
                        .fill(metricColor)
                        .frame(width: barGeometry.size.width * CGFloat(progress))
                }
            }
            .frame(height: dashboardBarHeight(for: size))
        }
    }

    // MARK: - Helpers

    private var metricsForRadial: [GaugeMetricData] {
        let maxCount: Int
        switch size {
        case .small:
            maxCount = 1
        case .medium:
            maxCount = 3
        case .large:
            maxCount = 4
        }
        return Array(entry.data.metrics.prefix(maxCount))
    }

    private var metricsForDashboard: [GaugeMetricData] {
        let maxCount: Int
        switch size {
        case .small:
            maxCount = 3
        case .medium:
            maxCount = 4
        case .large:
            maxCount = 8
        }
        return Array(entry.data.metrics.prefix(maxCount))
    }

    private func formattedValue(_ value: Double) -> String {
        if value == value.rounded() {
            return String(Int(value))
        }
        return String(format: "%.1f", value)
    }

    // MARK: - Computed Properties

    private var widgetURL: URL? {
        if let deepLink = entry.data.deepLinkUri, let url = URL(string: deepLink) {
            return url
        }
        return URL(string: "glancewidget://action?widgetId=\(entry.data.widgetId)&type=tap")
    }

    // MARK: - Dynamic Sizing

    private func titleFont(for size: GlanceSystemSize) -> Font {
        switch size {
        case .small:
            return .caption
        case .medium:
            return .subheadline
        case .large:
            return .headline
        }
    }

    private func gaugeValueFont(for size: GlanceSystemSize) -> Font {
        switch size {
        case .small:
            return .title3
        case .medium:
            return .title3
        case .large:
            return .title2
        }
    }

    private func gaugeUnitFont(for size: GlanceSystemSize) -> Font {
        switch size {
        case .small:
            return .caption2
        case .medium:
            return .caption
        case .large:
            return .subheadline
        }
    }

    private func metricLabelFont(for size: GlanceSystemSize) -> Font {
        switch size {
        case .small:
            return .caption2
        case .medium:
            return .caption
        case .large:
            return .subheadline
        }
    }

    private func metricValueFont(for size: GlanceSystemSize) -> Font {
        switch size {
        case .small:
            return .caption
        case .medium:
            return .subheadline
        case .large:
            return .body
        }
    }

    private func metricUnitFont(for size: GlanceSystemSize) -> Font {
        switch size {
        case .small:
            return .caption2
        case .medium:
            return .caption
        case .large:
            return .subheadline
        }
    }

    private func radialGaugeSize(for size: GlanceSystemSize, geometry: GeometryProxy, count: Int) -> CGFloat {
        let available = min(geometry.size.width, geometry.size.height)
        switch size {
        case .small:
            return available * 0.55
        case .medium:
            let maxPerGauge = (geometry.size.width - CGFloat(count - 1) * gaugeSpacing(for: size)) / CGFloat(count)
            return min(available * 0.55, maxPerGauge * 0.85)
        case .large:
            let maxPerGauge = (geometry.size.width - CGFloat(count - 1) * gaugeSpacing(for: size)) / CGFloat(count)
            return min(available * 0.35, maxPerGauge * 0.85)
        }
    }

    private func arcWidth(for size: GlanceSystemSize) -> CGFloat {
        switch size {
        case .small:
            return 6
        case .medium:
            return 7
        case .large:
            return 8
        }
    }

    private func gaugeSpacing(for size: GlanceSystemSize) -> CGFloat {
        switch size {
        case .small:
            return 8
        case .medium:
            return 12
        case .large:
            return 16
        }
    }

    private func dashboardSpacing(for size: GlanceSystemSize) -> CGFloat {
        switch size {
        case .small:
            return 6
        case .medium:
            return 8
        case .large:
            return 10
        }
    }

    private func dashboardBarHeight(for size: GlanceSystemSize) -> CGFloat {
        switch size {
        case .small:
            return 4
        case .medium:
            return 6
        case .large:
            return 8
        }
    }

    private func contentSpacing(for size: GlanceSystemSize) -> CGFloat {
        switch size {
        case .small:
            return 6
        case .medium:
            return 8
        case .large:
            return 10
        }
    }

    private func dynamicPadding(for size: GlanceSystemSize) -> EdgeInsets {
        switch size {
        case .small:
            return EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
        case .medium:
            return EdgeInsets(top: 14, leading: 14, bottom: 14, trailing: 14)
        case .large:
            return EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
        }
    }
}

// MARK: - Array Extension

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

// MARK: - Widget Configuration

struct GaugeWidget: Widget {
    let kind: String = "GaugeWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: GaugeWidgetIntent.self,
            provider: GaugeWidgetProvider()
        ) { entry in
            GaugeWidgetEntryView(entry: entry)
                .glanceContainerBackground(
                    Color(argb: entry.data.theme?.backgroundColor
                          ?? WidgetThemeData.defaultDark.backgroundColor)
                )
        }
        .configurationDisplayName("Gauge Widget")
        .description("Display metrics as radial gauges or a dashboard grid. Perfect for system stats, health metrics, or KPIs.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

// MARK: - Preview

#if DEBUG
struct GaugeWidget_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Radial single gauge
            GaugeWidgetEntryView(
                entry: GaugeWidgetEntry(
                    date: Date(),
                    data: GaugeWidgetData(
                        widgetId: "preview",
                        title: "CPU Usage",
                        metrics: [
                            GaugeMetricData(label: "CPU", value: 72, maxValue: 100, color: 0xFF2196F3, unit: "%"),
                        ],
                        gaugeType: "radial",
                        deepLinkUri: nil,
                        timestamp: Date().timeIntervalSince1970,
                        theme: .defaultDark
                    )
                )
            )
            .previewContext(WidgetPreviewContext(family: .systemSmall))
            .previewDisplayName("Radial Single")

            // Radial multiple gauges
            GaugeWidgetEntryView(
                entry: GaugeWidgetEntry(
                    date: Date(),
                    data: GaugeWidgetData(
                        widgetId: "preview",
                        title: "System Monitor",
                        metrics: [
                            GaugeMetricData(label: "CPU", value: 65, maxValue: 100, color: 0xFF2196F3, unit: "%"),
                            GaugeMetricData(label: "RAM", value: 4.2, maxValue: 8.0, color: 0xFF4CAF50, unit: "GB"),
                            GaugeMetricData(label: "Disk", value: 128, maxValue: 256, color: 0xFFFFA726, unit: "GB"),
                        ],
                        gaugeType: "radial",
                        deepLinkUri: nil,
                        timestamp: Date().timeIntervalSince1970,
                        theme: .defaultDark
                    )
                )
            )
            .previewContext(WidgetPreviewContext(family: .systemMedium))
            .previewDisplayName("Radial Multiple")

            // Dashboard
            GaugeWidgetEntryView(
                entry: GaugeWidgetEntry(
                    date: Date(),
                    data: GaugeWidgetData(
                        widgetId: "preview",
                        title: "Server Health",
                        metrics: [
                            GaugeMetricData(label: "CPU", value: 65, maxValue: 100, color: 0xFF2196F3, unit: "%"),
                            GaugeMetricData(label: "Memory", value: 4.2, maxValue: 8.0, color: 0xFF4CAF50, unit: "GB"),
                            GaugeMetricData(label: "Storage", value: 128, maxValue: 256, color: 0xFFFFA726, unit: "GB"),
                            GaugeMetricData(label: "Network", value: 85, maxValue: 100, color: 0xFFE91E63, unit: "Mbps"),
                        ],
                        gaugeType: "dashboard",
                        deepLinkUri: nil,
                        timestamp: Date().timeIntervalSince1970,
                        theme: .defaultDark
                    )
                )
            )
            .previewContext(WidgetPreviewContext(family: .systemLarge))
            .previewDisplayName("Dashboard")
        }
    }
}
#endif
