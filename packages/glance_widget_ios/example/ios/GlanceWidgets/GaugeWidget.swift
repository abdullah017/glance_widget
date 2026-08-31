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

    private var theme: WidgetThemeData {
        entry.data.theme
            ?? WidgetStorage.shared.loadGlobalTheme()
            ?? (colorScheme == .dark ? .defaultDark : .defaultLight)
    }

    var body: some View {
        let backgroundColor = Color(argb: theme.backgroundColor)
        let textColor = Color(argb: theme.textColor)
        let secondaryTextColor = Color(argb: theme.secondaryTextColor)

        GeometryReader { geometry in
            ZStack {
                // Background
                RoundedRectangle(cornerRadius: theme.borderRadius)
                    .fill(backgroundColor)

                // Content
                VStack(spacing: contentSpacing(for: family)) {
                    // Title
                    Text(entry.data.title)
                        .font(titleFont(for: family))
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
                .padding(dynamicPadding(for: family))
            }
        }
        .widgetURL(widgetURL)
    }

    // MARK: - Empty State

    @ViewBuilder
    private func emptyStateView(secondaryTextColor: Color) -> some View {
        Spacer()
        HStack {
            Spacer()
            Text("No metrics")
                .font(metricLabelFont(for: family))
                .foregroundColor(secondaryTextColor)
            Spacer()
        }
        Spacer()
    }

    // MARK: - Radial View

    @ViewBuilder
    private func radialView(textColor: Color, secondaryTextColor: Color, geometry: GeometryProxy) -> some View {
        let metricsToShow = metricsForRadial
        let gaugeSize = radialGaugeSize(for: family, geometry: geometry, count: metricsToShow.count)

        if metricsToShow.count == 1 {
            // Single large gauge
            singleRadialGauge(
                metric: metricsToShow[0],
                size: gaugeSize,
                textColor: textColor,
                secondaryTextColor: secondaryTextColor
            )
        } else {
            // Multiple gauges in a row
            HStack(spacing: gaugeSpacing(for: family)) {
                ForEach(Array(metricsToShow.enumerated()), id: \.offset) { _, metric in
                    singleRadialGauge(
                        metric: metric,
                        size: gaugeSize,
                        textColor: textColor,
                        secondaryTextColor: secondaryTextColor
                    )
                }
            }
        }
    }

    @ViewBuilder
    private func singleRadialGauge(metric: GaugeMetricData, size: CGFloat, textColor: Color, secondaryTextColor: Color) -> some View {
        let progress = metric.maxValue > 0 ? min(metric.value / metric.maxValue, 1.0) : 0
        let gaugeColor = metric.color.map { Color(argb: $0) } ?? Color(argb: theme.accentColor)
        let trackColor = secondaryTextColor.opacity(0.3)
        let arcLineWidth = arcWidth(for: family)

        VStack(spacing: 4) {
            ZStack {
                // Track arc (270 degrees, starting from bottom-left)
                Path { path in
                    path.addArc(
                        center: CGPoint(x: size / 2, y: size / 2),
                        radius: (size - arcLineWidth) / 2,
                        startAngle: .degrees(135),
                        endAngle: .degrees(405),
                        clockwise: false
                    )
                }
                .stroke(trackColor, style: StrokeStyle(lineWidth: arcLineWidth, lineCap: .round))

                // Progress arc
                Path { path in
                    path.addArc(
                        center: CGPoint(x: size / 2, y: size / 2),
                        radius: (size - arcLineWidth) / 2,
                        startAngle: .degrees(135),
                        endAngle: .degrees(135 + 270 * progress),
                        clockwise: false
                    )
                }
                .stroke(gaugeColor, style: StrokeStyle(lineWidth: arcLineWidth, lineCap: .round))

                // Value text
                VStack(spacing: 0) {
                    Text(formattedValue(metric.value))
                        .font(gaugeValueFont(for: family))
                        .fontWeight(.bold)
                        .foregroundColor(textColor)

                    if let unit = metric.unit, !unit.isEmpty {
                        Text(unit)
                            .font(gaugeUnitFont(for: family))
                            .foregroundColor(secondaryTextColor)
                    }
                }
            }
            .frame(width: size, height: size)

            // Label
            Text(metric.label)
                .font(metricLabelFont(for: family))
                .foregroundColor(secondaryTextColor)
                .lineLimit(1)
        }
    }

    // MARK: - Dashboard View

    @ViewBuilder
    private func dashboardView(textColor: Color, secondaryTextColor: Color, geometry: GeometryProxy) -> some View {
        let metricsToShow = metricsForDashboard

        if family == .systemSmall {
            VStack(spacing: dashboardSpacing(for: family)) {
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
            let columns = family == .systemLarge ? 2 : 2
            let rows = metricsToShow.chunked(into: columns)

            VStack(spacing: dashboardSpacing(for: family)) {
                ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                    HStack(spacing: dashboardSpacing(for: family)) {
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
                    .font(metricLabelFont(for: family))
                    .foregroundColor(secondaryTextColor)
                    .lineLimit(1)

                Spacer()

                HStack(spacing: 2) {
                    Text(formattedValue(metric.value))
                        .font(metricValueFont(for: family))
                        .fontWeight(.semibold)
                        .foregroundColor(textColor)

                    if let unit = metric.unit, !unit.isEmpty {
                        Text(unit)
                            .font(metricUnitFont(for: family))
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
            .frame(height: dashboardBarHeight(for: family))
        }
    }

    // MARK: - Helpers

    private var metricsForRadial: [GaugeMetricData] {
        let maxCount: Int
        switch family {
        case .systemSmall:
            maxCount = 1
        case .systemMedium:
            maxCount = 3
        case .systemLarge:
            maxCount = 4
        @unknown default:
            maxCount = 3
        }
        return Array(entry.data.metrics.prefix(maxCount))
    }

    private var metricsForDashboard: [GaugeMetricData] {
        let maxCount: Int
        switch family {
        case .systemSmall:
            maxCount = 3
        case .systemMedium:
            maxCount = 4
        case .systemLarge:
            maxCount = 8
        @unknown default:
            maxCount = 4
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

    private func titleFont(for family: WidgetFamily) -> Font {
        switch family {
        case .systemSmall:
            return .caption
        case .systemMedium:
            return .subheadline
        case .systemLarge:
            return .headline
        @unknown default:
            return .subheadline
        }
    }

    private func gaugeValueFont(for family: WidgetFamily) -> Font {
        switch family {
        case .systemSmall:
            return .title3
        case .systemMedium:
            return .title3
        case .systemLarge:
            return .title2
        @unknown default:
            return .title3
        }
    }

    private func gaugeUnitFont(for family: WidgetFamily) -> Font {
        switch family {
        case .systemSmall:
            return .caption2
        case .systemMedium:
            return .caption
        case .systemLarge:
            return .subheadline
        @unknown default:
            return .caption
        }
    }

    private func metricLabelFont(for family: WidgetFamily) -> Font {
        switch family {
        case .systemSmall:
            return .caption2
        case .systemMedium:
            return .caption
        case .systemLarge:
            return .subheadline
        @unknown default:
            return .caption
        }
    }

    private func metricValueFont(for family: WidgetFamily) -> Font {
        switch family {
        case .systemSmall:
            return .caption
        case .systemMedium:
            return .subheadline
        case .systemLarge:
            return .body
        @unknown default:
            return .subheadline
        }
    }

    private func metricUnitFont(for family: WidgetFamily) -> Font {
        switch family {
        case .systemSmall:
            return .caption2
        case .systemMedium:
            return .caption
        case .systemLarge:
            return .subheadline
        @unknown default:
            return .caption
        }
    }

    private func radialGaugeSize(for family: WidgetFamily, geometry: GeometryProxy, count: Int) -> CGFloat {
        let available = min(geometry.size.width, geometry.size.height)
        switch family {
        case .systemSmall:
            return available * 0.55
        case .systemMedium:
            let maxPerGauge = (geometry.size.width - CGFloat(count - 1) * gaugeSpacing(for: family)) / CGFloat(count)
            return min(available * 0.55, maxPerGauge * 0.85)
        case .systemLarge:
            let maxPerGauge = (geometry.size.width - CGFloat(count - 1) * gaugeSpacing(for: family)) / CGFloat(count)
            return min(available * 0.35, maxPerGauge * 0.85)
        @unknown default:
            return 70
        }
    }

    private func arcWidth(for family: WidgetFamily) -> CGFloat {
        switch family {
        case .systemSmall:
            return 6
        case .systemMedium:
            return 7
        case .systemLarge:
            return 8
        @unknown default:
            return 7
        }
    }

    private func gaugeSpacing(for family: WidgetFamily) -> CGFloat {
        switch family {
        case .systemSmall:
            return 8
        case .systemMedium:
            return 12
        case .systemLarge:
            return 16
        @unknown default:
            return 12
        }
    }

    private func dashboardSpacing(for family: WidgetFamily) -> CGFloat {
        switch family {
        case .systemSmall:
            return 6
        case .systemMedium:
            return 8
        case .systemLarge:
            return 10
        @unknown default:
            return 8
        }
    }

    private func dashboardBarHeight(for family: WidgetFamily) -> CGFloat {
        switch family {
        case .systemSmall:
            return 4
        case .systemMedium:
            return 6
        case .systemLarge:
            return 8
        @unknown default:
            return 6
        }
    }

    private func contentSpacing(for family: WidgetFamily) -> CGFloat {
        switch family {
        case .systemSmall:
            return 6
        case .systemMedium:
            return 8
        case .systemLarge:
            return 10
        @unknown default:
            return 8
        }
    }

    private func dynamicPadding(for family: WidgetFamily) -> EdgeInsets {
        switch family {
        case .systemSmall:
            return EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
        case .systemMedium:
            return EdgeInsets(top: 14, leading: 14, bottom: 14, trailing: 14)
        case .systemLarge:
            return EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
        @unknown default:
            return EdgeInsets(top: 14, leading: 14, bottom: 14, trailing: 14)
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
                .containerBackground(for: .widget) {
                    Color(argb: entry.data.theme?.backgroundColor
                          ?? WidgetThemeData.defaultDark.backgroundColor)
                }
        }
        .configurationDisplayName("Gauge Widget")
        .description("Display metrics as radial gauges or a dashboard grid. Perfect for system stats, health metrics, or KPIs.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
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
