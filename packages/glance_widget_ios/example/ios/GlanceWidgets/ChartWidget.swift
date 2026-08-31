import AppIntents
import WidgetKit
import SwiftUI

// MARK: - Configuration

/// The ids this template has data for, offered when the user edits the widget.
struct ChartWidgetIdOptions: DynamicOptionsProvider {
    func results() async throws -> [String] {
        WidgetStorage.shared.knownWidgetIds(prefix: "chartWidgetData_")
    }
}

/// Carries the `widgetId` a placed instance should render.
///
/// `widgetId` is documented as a "unique identifier for this widget instance",
/// and without a per-instance parameter there is nothing for the extension to
/// key on: every placed widget read the most recently written payload, so two
/// widgets built from this template always showed the same thing.
struct ChartWidgetIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Chart Widget" }
    static var description: IntentDescription {
        IntentDescription("Choose which of your app's widgets this one shows.")
    }

    @Parameter(title: "Widget", optionsProvider: ChartWidgetIdOptions())
    var widgetId: String?

    init() {}

    init(widgetId: String?) {
        self.widgetId = widgetId
    }
}

// MARK: - Timeline Provider

struct ChartWidgetProvider: AppIntentTimelineProvider {
    typealias Entry = ChartWidgetEntry
    typealias Intent = ChartWidgetIntent

    func placeholder(in context: Context) -> ChartWidgetEntry {
        ChartWidgetEntry(date: Date(), data: .placeholder)
    }

    func snapshot(for configuration: ChartWidgetIntent, in context: Context) async -> ChartWidgetEntry {
        ChartWidgetEntry(date: Date(), data: load(for: configuration))
    }

    func timeline(
        for configuration: ChartWidgetIntent,
        in context: Context
    ) async -> Timeline<ChartWidgetEntry> {
        let entry = ChartWidgetEntry(date: Date(), data: load(for: configuration))

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
    private func load(for configuration: ChartWidgetIntent) -> ChartWidgetData {
        WidgetStorage.shared.loadChartWidget(widgetId: configuration.widgetId) ?? .placeholder
    }
}

// MARK: - Timeline Entry

struct ChartWidgetEntry: TimelineEntry {
    let date: Date
    let data: ChartWidgetData
}

// MARK: - Widget View

struct ChartWidgetEntryView: View {
    var entry: ChartWidgetProvider.Entry
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.widgetFamily) var family

    /// The layout shape this family wants. See `GlanceSystemSize`.
    private var size: GlanceSystemSize { GlanceSystemSize(family) }

    private var theme: WidgetThemeData {
        entry.data.theme
            ?? WidgetStorage.shared.loadGlobalTheme()
            ?? (colorScheme == .dark ? .defaultDark : .defaultLight)
    }

    private var chartColor: Color {
        entry.data.color.map { Color(argb: $0) } ?? Color(argb: theme.accentColor)
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
                VStack(alignment: .leading, spacing: contentSpacing(for: size)) {
                    // Header
                    if entry.data.chartType != "sparkline" {
                        headerView(textColor: textColor, secondaryTextColor: secondaryTextColor)
                    }

                    // Chart
                    chartView(geometry: geometry)

                    // Subtitle for sparkline (shown below)
                    if entry.data.chartType == "sparkline" {
                        sparklineFooter(textColor: textColor, secondaryTextColor: secondaryTextColor)
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
            GlanceCircularText(value: accessoryLastValue)
        case .rectangular:
            GlanceRectangularStack(title: entry.data.title) {
                if entry.data.dataPoints.count > 1 {
                    HStack(spacing: 6) {
                        GlanceSparkline(dataPoints: entry.data.dataPoints)
                            .stroke(
                                style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
                            )
                        Text(accessoryLastValue)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    Text("No chart data")
                        .font(.system(size: 12))
                }
            }
        case .inline:
            Text("\(entry.data.title) \(accessoryLastValue)")
        }
    }

    /// The most recent reading, which is the one number the small slots have
    /// room for. The shape goes in the rectangular slot; a circle gets this.
    private var accessoryLastValue: String {
        guard let last = entry.data.dataPoints.last else { return "--" }
        return GlanceAccessoryFormat.value(last)
    }

    // MARK: - Subviews

    @ViewBuilder
    private func headerView(textColor: Color, secondaryTextColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(entry.data.title)
                .font(titleFont(for: size))
                .fontWeight(.bold)
                .foregroundColor(textColor)
                .lineLimit(1)

            if let subtitle = entry.data.subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .font(subtitleFont(for: size))
                    .foregroundColor(secondaryTextColor)
                    .lineLimit(1)
            }
        }
    }

    @ViewBuilder
    private func sparklineFooter(textColor: Color, secondaryTextColor: Color) -> some View {
        HStack {
            Text(entry.data.title)
                .font(titleFont(for: size))
                .fontWeight(.bold)
                .foregroundColor(textColor)
                .lineLimit(1)

            Spacer()

            if let subtitle = entry.data.subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .font(subtitleFont(for: size))
                    .foregroundColor(secondaryTextColor)
                    .lineLimit(1)
            }
        }
    }

    @ViewBuilder
    private func chartView(geometry: GeometryProxy) -> some View {
        if entry.data.dataPoints.isEmpty {
            emptyChartView
        } else {
            switch entry.data.chartType {
            case "bar":
                barChartView
            case "sparkline":
                sparklineChartView
            default:
                lineChartView
            }
        }
    }

    private var emptyChartView: some View {
        GeometryReader { geo in
            HStack {
                Spacer()
                VStack {
                    Spacer()
                    Text("No data")
                        .font(subtitleFont(for: size))
                        .foregroundColor(Color(argb: theme.secondaryTextColor))
                    Spacer()
                }
                Spacer()
            }
        }
    }

    // MARK: - Line Chart

    private var lineChartView: some View {
        GeometryReader { geo in
            let points = entry.data.dataPoints
            let minVal = points.min() ?? 0
            let maxVal = points.max() ?? 1
            let range = maxVal - minVal == 0 ? 1 : maxVal - minVal
            let width = geo.size.width
            let height = geo.size.height
            let stepX = points.count > 1 ? width / CGFloat(points.count - 1) : width

            ZStack {
                // Fill area
                Path { path in
                    guard points.count > 1 else { return }
                    path.move(to: CGPoint(x: 0, y: height))

                    for (index, value) in points.enumerated() {
                        let x = CGFloat(index) * stepX
                        let y = height - CGFloat((value - minVal) / range) * height
                        path.addLine(to: CGPoint(x: x, y: y))
                    }

                    path.addLine(to: CGPoint(x: CGFloat(points.count - 1) * stepX, y: height))
                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [chartColor.opacity(0.3), chartColor.opacity(0.05)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                // Line
                Path { path in
                    guard points.count > 1 else { return }
                    let firstY = height - CGFloat((points[0] - minVal) / range) * height
                    path.move(to: CGPoint(x: 0, y: firstY))

                    for (index, value) in points.enumerated().dropFirst() {
                        let x = CGFloat(index) * stepX
                        let y = height - CGFloat((value - minVal) / range) * height
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
                .stroke(chartColor, style: StrokeStyle(lineWidth: lineWidth(for: size), lineCap: .round, lineJoin: .round))

                // Data point dots
                if points.count <= 12 {
                    ForEach(Array(points.enumerated()), id: \.offset) { index, value in
                        let x = CGFloat(index) * stepX
                        let y = height - CGFloat((value - minVal) / range) * height
                        Circle()
                            .fill(chartColor)
                            .frame(width: dotRadius(for: size), height: dotRadius(for: size))
                            .position(x: x, y: y)
                    }
                }
            }
        }
    }

    // MARK: - Bar Chart

    private var barChartView: some View {
        GeometryReader { geo in
            let points = entry.data.dataPoints
            let maxVal = points.max() ?? 1
            let barCount = CGFloat(points.count)
            let totalSpacing = barSpacing(for: size) * (barCount - 1)
            let barWidth = max(2, (geo.size.width - totalSpacing) / barCount)

            HStack(alignment: .bottom, spacing: barSpacing(for: size)) {
                ForEach(Array(points.enumerated()), id: \.offset) { index, value in
                    let barHeight = maxVal > 0 ? CGFloat(value / maxVal) * geo.size.height : 0

                    RoundedRectangle(cornerRadius: barCornerRadius(for: size))
                        .fill(chartColor)
                        .frame(width: barWidth, height: max(2, barHeight))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
    }

    // MARK: - Sparkline Chart

    private var sparklineChartView: some View {
        GeometryReader { geo in
            let points = entry.data.dataPoints
            let minVal = points.min() ?? 0
            let maxVal = points.max() ?? 1
            let range = maxVal - minVal == 0 ? 1 : maxVal - minVal
            let width = geo.size.width
            let height = geo.size.height
            let stepX = points.count > 1 ? width / CGFloat(points.count - 1) : width

            Path { path in
                guard points.count > 1 else { return }
                let firstY = height - CGFloat((points[0] - minVal) / range) * height
                path.move(to: CGPoint(x: 0, y: firstY))

                for (index, value) in points.enumerated().dropFirst() {
                    let x = CGFloat(index) * stepX
                    let y = height - CGFloat((value - minVal) / range) * height
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
            .stroke(chartColor, style: StrokeStyle(lineWidth: sparklineWidth(for: size), lineCap: .round, lineJoin: .round))
        }
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

    private func subtitleFont(for size: GlanceSystemSize) -> Font {
        switch size {
        case .small:
            return .caption2
        case .medium:
            return .caption
        case .large:
            return .subheadline
        }
    }

    private func lineWidth(for size: GlanceSystemSize) -> CGFloat {
        switch size {
        case .small:
            return 1.5
        case .medium:
            return 2
        case .large:
            return 2.5
        }
    }

    private func sparklineWidth(for size: GlanceSystemSize) -> CGFloat {
        switch size {
        case .small:
            return 1.5
        case .medium:
            return 2
        case .large:
            return 2.5
        }
    }

    private func dotRadius(for size: GlanceSystemSize) -> CGFloat {
        switch size {
        case .small:
            return 4
        case .medium:
            return 5
        case .large:
            return 6
        }
    }

    private func barSpacing(for size: GlanceSystemSize) -> CGFloat {
        switch size {
        case .small:
            return 2
        case .medium:
            return 3
        case .large:
            return 4
        }
    }

    private func barCornerRadius(for size: GlanceSystemSize) -> CGFloat {
        switch size {
        case .small:
            return 2
        case .medium:
            return 3
        case .large:
            return 4
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

// MARK: - Widget Configuration

struct ChartWidget: Widget {
    let kind: String = "ChartWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: ChartWidgetIntent.self,
            provider: ChartWidgetProvider()
        ) { entry in
            ChartWidgetEntryView(entry: entry)
                .glanceContainerBackground(
                    Color(argb: entry.data.theme?.backgroundColor
                          ?? WidgetThemeData.defaultDark.backgroundColor)
                )
        }
        .configurationDisplayName("Chart Widget")
        .description("Display data as line, bar, or sparkline charts. Perfect for trends, analytics, and metrics visualization.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

// MARK: - Preview

#if DEBUG
struct ChartWidget_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Line chart
            ChartWidgetEntryView(
                entry: ChartWidgetEntry(
                    date: Date(),
                    data: ChartWidgetData(
                        widgetId: "preview",
                        title: "Revenue",
                        dataPoints: [12, 19, 15, 25, 22, 30, 28],
                        chartType: "line",
                        color: 0xFF2196F3,
                        subtitle: "Last 7 days",
                        deepLinkUri: nil,
                        timestamp: Date().timeIntervalSince1970,
                        theme: .defaultDark
                    )
                )
            )
            .previewContext(WidgetPreviewContext(family: .systemMedium))
            .previewDisplayName("Line Chart")

            // Bar chart
            ChartWidgetEntryView(
                entry: ChartWidgetEntry(
                    date: Date(),
                    data: ChartWidgetData(
                        widgetId: "preview",
                        title: "Weekly Steps",
                        dataPoints: [8000, 6500, 9200, 7800, 5400, 10000, 8500],
                        chartType: "bar",
                        color: 0xFF4CAF50,
                        subtitle: "Avg: 7,914",
                        deepLinkUri: nil,
                        timestamp: Date().timeIntervalSince1970,
                        theme: .defaultDark
                    )
                )
            )
            .previewContext(WidgetPreviewContext(family: .systemSmall))
            .previewDisplayName("Bar Chart")

            // Sparkline
            ChartWidgetEntryView(
                entry: ChartWidgetEntry(
                    date: Date(),
                    data: ChartWidgetData(
                        widgetId: "preview",
                        title: "BTC",
                        dataPoints: [45000, 46200, 44800, 47500, 46900, 48100, 47300],
                        chartType: "sparkline",
                        color: 0xFFFFA726,
                        subtitle: "$47,300",
                        deepLinkUri: nil,
                        timestamp: Date().timeIntervalSince1970,
                        theme: .defaultDark
                    )
                )
            )
            .previewContext(WidgetPreviewContext(family: .systemSmall))
            .previewDisplayName("Sparkline")
        }
    }
}
#endif
