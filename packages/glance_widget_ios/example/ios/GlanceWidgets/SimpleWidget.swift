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
                VStack(spacing: dynamicSpacing(for: geometry.size)) {
                    // Icon (if available)
                    if let iconName = entry.data.iconName {
                        Image(systemName: iconName)
                            .font(.system(size: iconSize(for: family)))
                            .foregroundColor(Color(argb: theme.accentColor))
                    }

                    // Title
                    Text(entry.data.title)
                        .font(titleFont(for: family))
                        .fontWeight(.medium)
                        .foregroundColor(secondaryTextColor)
                        .lineLimit(1)

                    // Value (large)
                    Text(entry.data.value)
                        .font(valueFont(for: family))
                        .fontWeight(.bold)
                        .foregroundColor(textColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)

                    // Subtitle (optional)
                    if let subtitle = entry.data.subtitle {
                        Text(subtitle)
                            .font(subtitleFont(for: family))
                            .fontWeight(.medium)
                            .foregroundColor(subtitleColor)
                            .lineLimit(1)
                    }
                }
                .padding(dynamicPadding(for: family))
            }
        }
        .widgetURL(widgetURL)
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

    private func valueFont(for family: WidgetFamily) -> Font {
        switch family {
        case .systemSmall:
            return .title2
        case .systemMedium:
            return .largeTitle
        case .systemLarge:
            return .system(size: 48, weight: .bold)
        @unknown default:
            return .title
        }
    }

    private func subtitleFont(for family: WidgetFamily) -> Font {
        switch family {
        case .systemSmall:
            return .caption2
        case .systemMedium:
            return .subheadline
        case .systemLarge:
            return .headline
        @unknown default:
            return .subheadline
        }
    }

    private func iconSize(for family: WidgetFamily) -> CGFloat {
        switch family {
        case .systemSmall:
            return 20
        case .systemMedium:
            return 28
        case .systemLarge:
            return 36
        @unknown default:
            return 24
        }
    }

    private func dynamicSpacing(for size: CGSize) -> CGFloat {
        return min(size.width, size.height) * 0.04
    }

    private func dynamicPadding(for family: WidgetFamily) -> EdgeInsets {
        switch family {
        case .systemSmall:
            return EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12)
        case .systemMedium:
            return EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
        case .systemLarge:
            return EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20)
        @unknown default:
            return EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
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
                .containerBackground(for: .widget) {
                    Color(argb: entry.data.theme?.backgroundColor
                          ?? WidgetThemeData.defaultDark.backgroundColor)
                }
        }
        .configurationDisplayName("Simple Widget")
        .description("Display a value with title and optional subtitle. Perfect for prices, stats, or metrics.")
        .supportedFamilies([.systemSmall, .systemMedium])
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
