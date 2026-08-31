import AppIntents
import WidgetKit
import SwiftUI

// MARK: - Configuration

/// The ids this template has data for, offered when the user edits the widget.
struct SimpleWidgetIdOptions: DynamicOptionsProvider {
    func results() async throws -> [String] {
        WidgetStorage.shared.knownWidgetIds(prefix: "simpleWidgetData_")
    }
}

/// Carries the `widgetId` a placed instance should render.
///
/// `widgetId` is documented as a "unique identifier for this widget instance",
/// and without a per-instance parameter there is nothing for the extension to
/// key on: every placed widget read the most recently written payload, so two
/// widgets built from this template always showed the same thing.
struct SimpleWidgetIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Simple Widget" }
    static var description: IntentDescription {
        IntentDescription("Choose which of your app's widgets this one shows.")
    }

    @Parameter(title: "Widget", optionsProvider: SimpleWidgetIdOptions())
    var widgetId: String?

    init() {}

    init(widgetId: String?) {
        self.widgetId = widgetId
    }
}

// MARK: - Timeline Provider

struct SimpleWidgetProvider: AppIntentTimelineProvider {
    typealias Entry = SimpleWidgetEntry
    typealias Intent = SimpleWidgetIntent

    func placeholder(in context: Context) -> SimpleWidgetEntry {
        SimpleWidgetEntry(date: Date(), data: .placeholder)
    }

    func snapshot(for configuration: SimpleWidgetIntent, in context: Context) async -> SimpleWidgetEntry {
        SimpleWidgetEntry(date: Date(), data: load(for: configuration))
    }

    func timeline(
        for configuration: SimpleWidgetIntent,
        in context: Context
    ) async -> Timeline<SimpleWidgetEntry> {
        let entry = SimpleWidgetEntry(date: Date(), data: load(for: configuration))

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
    private func load(for configuration: SimpleWidgetIntent) -> SimpleWidgetData {
        WidgetStorage.shared.loadSimpleWidget(widgetId: configuration.widgetId) ?? .placeholder
    }
}

// MARK: - Timeline Entry

struct SimpleWidgetEntry: TimelineEntry {
    let date: Date
    let data: SimpleWidgetData
}

// MARK: - Widget View

struct SimpleWidgetEntryView: View {
    var entry: SimpleWidgetProvider.Entry
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
                VStack(spacing: dynamicSpacing(for: geometry.size)) {
                    // Icon (if available)
                    if let iconName = entry.data.iconName {
                        Image(systemName: iconName)
                            .font(.system(size: iconSize(for: size)))
                            .foregroundColor(Color(argb: theme.accentColor))
                    }

                    // Title
                    Text(entry.data.title)
                        .font(titleFont(for: size))
                        .fontWeight(.medium)
                        .foregroundColor(secondaryTextColor)
                        .lineLimit(1)

                    // Value (large)
                    Text(entry.data.value)
                        .font(valueFont(for: size))
                        .fontWeight(.bold)
                        .foregroundColor(textColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)

                    // Subtitle (optional)
                    if let subtitle = entry.data.subtitle {
                        Text(subtitle)
                            .font(subtitleFont(for: size))
                            .fontWeight(.medium)
                            .foregroundColor(subtitleColor)
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
            GlanceCircularText(value: entry.data.value)
        case .rectangular:
            GlanceRectangularStack(title: entry.data.title) {
                Text(entry.data.value)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                if let subtitle = entry.data.subtitle {
                    Text(subtitle)
                        .font(.system(size: 12))
                        .lineLimit(1)
                }
            }
        case .inline:
            Text("\(entry.data.title) \(entry.data.value)")
        }
    }

    // MARK: - Computed Properties

    private var subtitleColor: Color {
        if let colorInt = entry.data.subtitleColor {
            return Color(argb: colorInt)
        }
        return Color(argb: theme.secondaryTextColor)
    }

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

    private func valueFont(for size: GlanceSystemSize) -> Font {
        switch size {
        case .small:
            return .title2
        case .medium:
            return .largeTitle
        case .large:
            return .system(size: 48, weight: .bold)
        }
    }

    private func subtitleFont(for size: GlanceSystemSize) -> Font {
        switch size {
        case .small:
            return .caption2
        case .medium:
            return .subheadline
        case .large:
            return .headline
        }
    }

    private func iconSize(for size: GlanceSystemSize) -> CGFloat {
        switch size {
        case .small:
            return 20
        case .medium:
            return 28
        case .large:
            return 36
        }
    }

    private func dynamicSpacing(for size: CGSize) -> CGFloat {
        return min(size.width, size.height) * 0.04
    }

    private func dynamicPadding(for size: GlanceSystemSize) -> EdgeInsets {
        switch size {
        case .small:
            return EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12)
        case .medium:
            return EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
        case .large:
            return EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20)
        }
    }
}

// MARK: - Widget Configuration

struct SimpleWidget: Widget {
    let kind: String = "SimpleWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: SimpleWidgetIntent.self,
            provider: SimpleWidgetProvider()
        ) { entry in
            SimpleWidgetEntryView(entry: entry)
                .glanceContainerBackground(
                    Color(argb: entry.data.theme?.backgroundColor
                          ?? WidgetThemeData.defaultDark.backgroundColor)
                )
        }
        .configurationDisplayName("Simple Widget")
        .description("Display a value with title and optional subtitle. Perfect for prices, stats, or metrics.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

// MARK: - Preview

#if DEBUG
struct SimpleWidget_Previews: PreviewProvider {
    static var previews: some View {
        SimpleWidgetEntryView(
            entry: SimpleWidgetEntry(
                date: Date(),
                data: SimpleWidgetData(
                    widgetId: "preview",
                    title: "Bitcoin",
                    value: "$45,230",
                    subtitle: "+2.5%",
                    subtitleColor: 0xFF4CAF50,
                    iconName: "bitcoinsign.circle.fill",
                    iconBase64: nil,
                    deepLinkUri: nil,
                    timestamp: Date().timeIntervalSince1970,
                    theme: .defaultDark
                )
            )
        )
        .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
#endif
