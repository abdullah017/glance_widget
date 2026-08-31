import AppIntents
import WidgetKit
import SwiftUI

// MARK: - Configuration

/// The ids this template has data for, offered when the user edits the widget.
struct ProgressWidgetIdOptions: DynamicOptionsProvider {
    func results() async throws -> [String] {
        WidgetStorage.shared.knownWidgetIds(prefix: "progressWidgetData_")
    }
}

/// Carries the `widgetId` a placed instance should render.
///
/// `widgetId` is documented as a "unique identifier for this widget instance",
/// and without a per-instance parameter there is nothing for the extension to
/// key on: every placed widget read the most recently written payload, so two
/// widgets built from this template always showed the same thing.
struct ProgressWidgetIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Progress Widget" }
    static var description: IntentDescription {
        IntentDescription("Choose which of your app's widgets this one shows.")
    }

    @Parameter(title: "Widget", optionsProvider: ProgressWidgetIdOptions())
    var widgetId: String?

    init() {}

    init(widgetId: String?) {
        self.widgetId = widgetId
    }
}

// MARK: - Timeline Provider

struct ProgressWidgetProvider: AppIntentTimelineProvider {
    typealias Entry = ProgressWidgetEntry
    typealias Intent = ProgressWidgetIntent

    func placeholder(in context: Context) -> ProgressWidgetEntry {
        ProgressWidgetEntry(date: Date(), data: .placeholder)
    }

    func snapshot(for configuration: ProgressWidgetIntent, in context: Context) async -> ProgressWidgetEntry {
        ProgressWidgetEntry(date: Date(), data: load(for: configuration))
    }

    func timeline(
        for configuration: ProgressWidgetIntent,
        in context: Context
    ) async -> Timeline<ProgressWidgetEntry> {
        let entry = ProgressWidgetEntry(date: Date(), data: load(for: configuration))

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
    private func load(for configuration: ProgressWidgetIntent) -> ProgressWidgetData {
        WidgetStorage.shared.loadProgressWidget(widgetId: configuration.widgetId) ?? .placeholder
    }
}

// MARK: - Timeline Entry

struct ProgressWidgetEntry: TimelineEntry {
    let date: Date
    let data: ProgressWidgetData
}

// MARK: - Widget View

struct ProgressWidgetEntryView: View {
    var entry: ProgressWidgetProvider.Entry
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
        let accentColor = Color(argb: theme.accentColor)

        let progressColor = entry.data.progressColor.map { Color(argb: $0) } ?? accentColor
        let trackColor = entry.data.trackColor.map { Color(argb: $0) } ?? secondaryTextColor.opacity(0.3)

        GeometryReader { geometry in
            ZStack {
                // Background
                RoundedRectangle(cornerRadius: theme.borderRadius)
                    .fill(backgroundColor)

                // Content
                VStack(spacing: 12) {
                    // Title
                    Text(entry.data.title)
                        .font(titleFont(for: size))
                        .fontWeight(.medium)
                        .foregroundColor(secondaryTextColor)
                        .lineLimit(1)

                    if entry.data.progressType == "linear" {
                        // Linear Progress
                        linearProgressView(
                            progress: entry.data.progress,
                            progressColor: progressColor,
                            trackColor: trackColor,
                            textColor: textColor,
                            geometry: geometry
                        )
                    } else {
                        // Circular Progress (default)
                        circularProgressView(
                            progress: entry.data.progress,
                            progressColor: progressColor,
                            trackColor: trackColor,
                            textColor: textColor,
                            geometry: geometry
                        )
                    }

                    // Subtitle (optional)
                    if let subtitle = entry.data.subtitle {
                        Text(subtitle)
                            .font(subtitleFont(for: size))
                            .foregroundColor(secondaryTextColor)
                            .lineLimit(1)
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
            GlanceCircularGauge(
                progress: entry.data.progress,
                label: GlanceAccessoryFormat.percent(entry.data.progress)
            )
        case .rectangular:
            GlanceRectangularStack(title: entry.data.title) {
                GlanceRectangularGauge(
                    progress: entry.data.progress,
                    label: entry.data.subtitle ?? "",
                    value: GlanceAccessoryFormat.percent(entry.data.progress)
                )
            }
        case .inline:
            Text("\(entry.data.title) \(GlanceAccessoryFormat.percent(entry.data.progress))")
        }
    }

    // MARK: - Progress Views

    @ViewBuilder
    private func circularProgressView(
        progress: Double,
        progressColor: Color,
        trackColor: Color,
        textColor: Color,
        geometry: GeometryProxy
    ) -> some View {
        let diameter = circularSize(for: size, geometry: geometry)
        let lineWidth = circularLineWidth(for: size)

        ZStack {
            // Track
            Circle()
                .stroke(trackColor, lineWidth: lineWidth)

            // Progress
            Circle()
                .trim(from: 0, to: CGFloat(min(progress, 1.0)))
                .stroke(
                    progressColor,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.3), value: progress)

            // Percentage text
            Text("\(Int(progress * 100))%")
                .font(percentageFont(for: size))
                .fontWeight(.bold)
                .foregroundColor(textColor)
        }
        .frame(width: diameter, height: diameter)
    }

    @ViewBuilder
    private func linearProgressView(
        progress: Double,
        progressColor: Color,
        trackColor: Color,
        textColor: Color,
        geometry: GeometryProxy
    ) -> some View {
        VStack(spacing: 8) {
            // Percentage
            Text("\(Int(progress * 100))%")
                .font(percentageFont(for: size))
                .fontWeight(.bold)
                .foregroundColor(textColor)

            // Progress bar
            GeometryReader { barGeometry in
                ZStack(alignment: .leading) {
                    // Track
                    RoundedRectangle(cornerRadius: 4)
                        .fill(trackColor)

                    // Progress
                    RoundedRectangle(cornerRadius: 4)
                        .fill(progressColor)
                        .frame(width: barGeometry.size.width * CGFloat(min(progress, 1.0)))
                        .animation(.easeInOut(duration: 0.3), value: progress)
                }
            }
            .frame(height: linearBarHeight(for: size))
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

    private func percentageFont(for size: GlanceSystemSize) -> Font {
        switch size {
        case .small:
            return .caption
        case .medium:
            return .title3
        case .large:
            return .title
        }
    }

    private func circularSize(for size: GlanceSystemSize, geometry: GeometryProxy) -> CGFloat {
        let minDimension = min(geometry.size.width, geometry.size.height)
        switch size {
        case .small:
            return minDimension * 0.45
        case .medium:
            return minDimension * 0.5
        case .large:
            return minDimension * 0.35
        }
    }

    private func circularLineWidth(for size: GlanceSystemSize) -> CGFloat {
        switch size {
        case .small:
            return 6
        case .medium:
            return 8
        case .large:
            return 10
        }
    }

    private func linearBarHeight(for size: GlanceSystemSize) -> CGFloat {
        switch size {
        case .small:
            return 8
        case .medium:
            return 12
        case .large:
            return 16
        }
    }

    private func dynamicPadding(for size: GlanceSystemSize) -> EdgeInsets {
        switch size {
        case .small:
            return EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12)
        case .medium:
            return EdgeInsets(top: 16, leading: 20, bottom: 16, trailing: 20)
        case .large:
            return EdgeInsets(top: 20, leading: 24, bottom: 20, trailing: 24)
        }
    }
}

// MARK: - Widget Configuration

struct ProgressWidget: Widget {
    let kind: String = "ProgressWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: ProgressWidgetIntent.self,
            provider: ProgressWidgetProvider()
        ) { entry in
            ProgressWidgetEntryView(entry: entry)
                .glanceContainerBackground(
                    Color(argb: entry.data.theme?.backgroundColor
                          ?? WidgetThemeData.defaultDark.backgroundColor)
                )
        }
        .configurationDisplayName("Progress Widget")
        .description("Display progress with circular or linear indicator. Great for goals, downloads, or completion status.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

// MARK: - Preview

#if DEBUG
struct ProgressWidget_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Circular progress
            ProgressWidgetEntryView(
                entry: ProgressWidgetEntry(
                    date: Date(),
                    data: ProgressWidgetData(
                        widgetId: "preview",
                        title: "Daily Goal",
                        progress: 0.75,
                        subtitle: "7,500 / 10,000 steps",
                        progressType: "circular",
                        progressColor: 0xFF4CAF50,
                        trackColor: nil,
                        deepLinkUri: nil,
                        timestamp: Date().timeIntervalSince1970,
                        theme: .defaultDark
                    )
                )
            )
            .previewContext(WidgetPreviewContext(family: .systemSmall))
            .previewDisplayName("Circular")

            // Linear progress
            ProgressWidgetEntryView(
                entry: ProgressWidgetEntry(
                    date: Date(),
                    data: ProgressWidgetData(
                        widgetId: "preview",
                        title: "Download",
                        progress: 0.45,
                        subtitle: "45 MB / 100 MB",
                        progressType: "linear",
                        progressColor: 0xFF2196F3,
                        trackColor: nil,
                        deepLinkUri: nil,
                        timestamp: Date().timeIntervalSince1970,
                        theme: .defaultDark
                    )
                )
            )
            .previewContext(WidgetPreviewContext(family: .systemMedium))
            .previewDisplayName("Linear")
        }
    }
}
#endif
