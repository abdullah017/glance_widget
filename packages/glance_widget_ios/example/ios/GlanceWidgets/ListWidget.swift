import AppIntents
import WidgetKit
import SwiftUI

// MARK: - Configuration

/// The ids this template has data for, offered when the user edits the widget.
struct ListWidgetIdOptions: DynamicOptionsProvider {
    func results() async throws -> [String] {
        WidgetStorage.shared.knownWidgetIds(prefix: "listWidgetData_")
    }
}

/// Carries the `widgetId` a placed instance should render.
///
/// `widgetId` is documented as a "unique identifier for this widget instance",
/// and without a per-instance parameter there is nothing for the extension to
/// key on: every placed widget read the most recently written payload, so two
/// widgets built from this template always showed the same thing.
struct ListWidgetIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "List Widget" }
    static var description: IntentDescription {
        IntentDescription("Choose which of your app's widgets this one shows.")
    }

    @Parameter(title: "Widget", optionsProvider: ListWidgetIdOptions())
    var widgetId: String?

    init() {}

    init(widgetId: String?) {
        self.widgetId = widgetId
    }
}

// MARK: - Timeline Provider

struct ListWidgetProvider: AppIntentTimelineProvider {
    typealias Entry = ListWidgetEntry
    typealias Intent = ListWidgetIntent

    func placeholder(in context: Context) -> ListWidgetEntry {
        ListWidgetEntry(date: Date(), data: .placeholder)
    }

    func snapshot(for configuration: ListWidgetIntent, in context: Context) async -> ListWidgetEntry {
        ListWidgetEntry(date: Date(), data: load(for: configuration))
    }

    func timeline(
        for configuration: ListWidgetIntent,
        in context: Context
    ) async -> Timeline<ListWidgetEntry> {
        let entry = ListWidgetEntry(date: Date(), data: load(for: configuration))

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
    private func load(for configuration: ListWidgetIntent) -> ListWidgetData {
        WidgetStorage.shared.loadListWidget(widgetId: configuration.widgetId) ?? .placeholder
    }
}

// MARK: - Timeline Entry

struct ListWidgetEntry: TimelineEntry {
    let date: Date
    let data: ListWidgetData
}

// MARK: - Widget View

struct ListWidgetEntryView: View {
    var entry: ListWidgetProvider.Entry
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.widgetFamily) var family

    private var theme: WidgetThemeData {
        entry.data.theme
            ?? WidgetStorage.shared.loadGlobalTheme()
            ?? (colorScheme == .dark ? .defaultDark : .defaultLight)
    }

    private var maxItemsToShow: Int {
        switch family {
        case .systemSmall:
            return min(3, entry.data.maxItems)
        case .systemMedium:
            return min(4, entry.data.maxItems)
        case .systemLarge:
            return min(8, entry.data.maxItems)
        @unknown default:
            return entry.data.maxItems
        }
    }

    var body: some View {
        let backgroundColor = Color(argb: theme.backgroundColor)
        let textColor = Color(argb: theme.textColor)
        let secondaryTextColor = Color(argb: theme.secondaryTextColor)
        let accentColor = Color(argb: theme.accentColor)

        GeometryReader { geometry in
            ZStack {
                // Background
                RoundedRectangle(cornerRadius: theme.borderRadius)
                    .fill(backgroundColor)

                // Content
                VStack(alignment: .leading, spacing: 8) {
                    // Header
                    headerView(
                        textColor: textColor,
                        secondaryTextColor: secondaryTextColor
                    )

                    // Divider
                    Rectangle()
                        .fill(secondaryTextColor.opacity(0.3))
                        .frame(height: 1)

                    if entry.data.items.isEmpty {
                        // Empty state
                        emptyStateView(secondaryTextColor: secondaryTextColor)
                    } else {
                        // Items list
                        itemsListView(
                            textColor: textColor,
                            secondaryTextColor: secondaryTextColor,
                            accentColor: accentColor
                        )
                    }
                }
                .padding(dynamicPadding(for: family))
            }
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private func headerView(textColor: Color, secondaryTextColor: Color) -> some View {
        HStack {
            Text(entry.data.title)
                .font(titleFont(for: family))
                .fontWeight(.bold)
                .foregroundColor(textColor)
                .lineLimit(1)

            Spacer()

            Text("\(entry.data.items.count)")
                .font(countFont(for: family))
                .foregroundColor(secondaryTextColor)
        }
    }

    @ViewBuilder
    private func emptyStateView(secondaryTextColor: Color) -> some View {
        Spacer()
        HStack {
            Spacer()
            Text("No items")
                .font(itemFont(for: family))
                .foregroundColor(secondaryTextColor)
            Spacer()
        }
        Spacer()
    }

    @ViewBuilder
    private func itemsListView(
        textColor: Color,
        secondaryTextColor: Color,
        accentColor: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: itemSpacing(for: family)) {
            ForEach(Array(entry.data.items.prefix(maxItemsToShow).enumerated()), id: \.offset) { index, item in
                itemRowView(
                    item: item,
                    index: index,
                    textColor: textColor,
                    secondaryTextColor: secondaryTextColor,
                    accentColor: accentColor
                )
            }

            // Show "more" indicator if there are more items
            if entry.data.items.count > maxItemsToShow {
                Text("+\(entry.data.items.count - maxItemsToShow) more")
                    .font(.caption2)
                    .foregroundColor(secondaryTextColor)
            }
        }
    }

    @ViewBuilder
    private func itemRowView(
        item: ListItemData,
        index: Int,
        textColor: Color,
        secondaryTextColor: Color,
        accentColor: Color
    ) -> some View {
        HStack(spacing: 8) {
            // Checkbox (if enabled) - tappable with checkboxToggle action
            if entry.data.showCheckboxes {
                Link(destination: checkboxToggleURL(index: index, currentValue: item.checked)) {
                    Image(systemName: item.checked ? "checkmark.circle.fill" : "circle")
                        .font(checkboxFont(for: family))
                        .foregroundColor(item.checked ? accentColor : secondaryTextColor)
                }
            }

            // Rest of the row is tappable with itemTap action
            Link(destination: itemURL(index: index)) {
                HStack(spacing: 8) {
                    // Icon (if provided)
                    if let iconName = item.iconName {
                        Image(systemName: iconName)
                            .font(iconFont(for: family))
                            .foregroundColor(accentColor)
                    }

                    // Text content
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.text)
                            .font(itemFont(for: family))
                            .foregroundColor(item.checked && entry.data.showCheckboxes ? secondaryTextColor : textColor)
                            .strikethrough(item.checked && entry.data.showCheckboxes)
                            .lineLimit(1)

                        if let secondary = item.secondaryText, !secondary.isEmpty {
                            Text(secondary)
                                .font(secondaryFont(for: family))
                                .foregroundColor(secondaryTextColor)
                                .lineLimit(1)
                        }
                    }

                    Spacer()
                }
            }
        }
    }

    // MARK: - URLs

    private func itemURL(index: Int) -> URL {
        if let deepLink = entry.data.deepLinkUri, let url = URL(string: deepLink) {
            return url
        }
        return URL(string: "glancewidget://action?widgetId=\(entry.data.widgetId)&type=itemTap&itemIndex=\(index)")!
    }

    private func checkboxToggleURL(index: Int, currentValue: Bool) -> URL {
        if let deepLink = entry.data.deepLinkUri, let url = URL(string: deepLink) {
            return url
        }
        let newValue = !currentValue
        return URL(string: "glancewidget://action?widgetId=\(entry.data.widgetId)&type=checkboxToggle&itemIndex=\(index)&value=\(newValue)")!
    }

    // MARK: - Dynamic Sizing

    private func titleFont(for family: WidgetFamily) -> Font {
        switch family {
        case .systemSmall:
            return .subheadline
        case .systemMedium:
            return .headline
        case .systemLarge:
            return .title3
        @unknown default:
            return .headline
        }
    }

    private func countFont(for family: WidgetFamily) -> Font {
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

    private func itemFont(for family: WidgetFamily) -> Font {
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

    private func secondaryFont(for family: WidgetFamily) -> Font {
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

    private func checkboxFont(for family: WidgetFamily) -> Font {
        switch family {
        case .systemSmall:
            return .caption
        case .systemMedium:
            return .body
        case .systemLarge:
            return .title3
        @unknown default:
            return .body
        }
    }

    private func iconFont(for family: WidgetFamily) -> Font {
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

    private func itemSpacing(for family: WidgetFamily) -> CGFloat {
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

// MARK: - Widget Configuration

struct ListWidget: Widget {
    let kind: String = "ListWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: ListWidgetIntent.self,
            provider: ListWidgetProvider()
        ) { entry in
            ListWidgetEntryView(entry: entry)
                .containerBackground(for: .widget) {
                    Color(argb: entry.data.theme?.backgroundColor
                          ?? WidgetThemeData.defaultDark.backgroundColor)
                }
        }
        .configurationDisplayName("List Widget")
        .description("Display a list of items with optional checkboxes. Perfect for todos, shopping lists, or quick notes.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Preview

#if DEBUG
struct ListWidget_Previews: PreviewProvider {
    static var previews: some View {
        ListWidgetEntryView(
            entry: ListWidgetEntry(
                date: Date(),
                data: ListWidgetData(
                    widgetId: "preview",
                    title: "Shopping List",
                    items: [
                        ListItemData(text: "Milk", checked: true, secondaryText: "2 liters", iconName: nil),
                        ListItemData(text: "Bread", checked: false, secondaryText: nil, iconName: nil),
                        ListItemData(text: "Eggs", checked: false, secondaryText: "12 pack", iconName: nil),
                        ListItemData(text: "Butter", checked: true, secondaryText: nil, iconName: nil),
                    ],
                    showCheckboxes: true,
                    maxItems: 5,
                    deepLinkUri: nil,
                    timestamp: Date().timeIntervalSince1970,
                    theme: .defaultDark
                )
            )
        )
        .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
#endif
