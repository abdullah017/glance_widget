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

    /// The layout shape this family wants. See `GlanceSystemSize`.
    private var size: GlanceSystemSize { GlanceSystemSize(family) }

    private var theme: WidgetThemeData {
        entry.data.theme
            ?? WidgetStorage.shared.loadGlobalTheme()
            ?? (colorScheme == .dark ? .defaultDark : .defaultLight)
    }

    private var maxItemsToShow: Int {
        switch size {
        case .small:
            return min(3, entry.data.maxItems)
        case .medium:
            return min(4, entry.data.maxItems)
        case .large:
            return min(8, entry.data.maxItems)
        }
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
                .padding(dynamicPadding(for: size))
            }
        }
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
            GlanceCircularText(
                value: "\(accessoryCount)",
                caption: entry.data.showCheckboxes ? "left" : "items"
            )
        case .rectangular:
            GlanceRectangularStack(title: entry.data.title) {
                if entry.data.items.isEmpty {
                    Text("No items")
                        .font(.system(size: 12))
                } else {
                    ForEach(Array(entry.data.items.prefix(2).enumerated()), id: \.offset) { _, item in
                        Text(accessoryLine(for: item))
                            .font(.system(size: 12))
                            .lineLimit(1)
                    }
                }
            }
        case .inline:
            Text(accessoryInlineText)
        }
    }

    /// How many items the circular slot counts: the ones still to do when the
    /// list is a checklist, and every item when it is not.
    private var accessoryCount: Int {
        entry.data.showCheckboxes
            ? entry.data.items.filter { !$0.checked }.count
            : entry.data.items.count
    }

    /// One item on one line, marked done or not when the list is a checklist.
    ///
    /// A drawn checkbox is what the home screen layout uses, but at this size
    /// the box is a smudge, so the state goes into the text where it survives
    /// being tinted flat.
    private func accessoryLine(for item: ListItemData) -> String {
        guard entry.data.showCheckboxes else { return item.text }
        return (item.checked ? "\u{2713} " : "\u{25CB} ") + item.text
    }

    /// The next thing to do, or the list's name when there is nothing left.
    private var accessoryInlineText: String {
        let next = entry.data.showCheckboxes
            ? entry.data.items.first(where: { !$0.checked })
            : entry.data.items.first
        guard let next else { return entry.data.title }
        return "\(entry.data.title): \(next.text)"
    }

    // MARK: - Subviews

    @ViewBuilder
    private func headerView(textColor: Color, secondaryTextColor: Color) -> some View {
        HStack {
            Text(entry.data.title)
                .font(titleFont(for: size))
                .fontWeight(.bold)
                .foregroundColor(textColor)
                .lineLimit(1)

            Spacer()

            Text("\(entry.data.items.count)")
                .font(countFont(for: size))
                .foregroundColor(secondaryTextColor)
        }
    }

    @ViewBuilder
    private func emptyStateView(secondaryTextColor: Color) -> some View {
        Spacer()
        HStack {
            Spacer()
            Text("No items")
                .font(itemFont(for: size))
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
        VStack(alignment: .leading, spacing: itemSpacing(for: size)) {
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
                        .font(checkboxFont(for: size))
                        .foregroundColor(item.checked ? accentColor : secondaryTextColor)
                }
            }

            // Rest of the row is tappable with itemTap action
            Link(destination: itemURL(index: index)) {
                HStack(spacing: 8) {
                    // Icon (if provided)
                    if let iconName = item.iconName {
                        Image(systemName: iconName)
                            .font(iconFont(for: size))
                            .foregroundColor(accentColor)
                    }

                    // Text content
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.text)
                            .font(itemFont(for: size))
                            .foregroundColor(item.checked && entry.data.showCheckboxes ? secondaryTextColor : textColor)
                            .strikethrough(item.checked && entry.data.showCheckboxes)
                            .lineLimit(1)

                        if let secondary = item.secondaryText, !secondary.isEmpty {
                            Text(secondary)
                                .font(secondaryFont(for: size))
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

    private func titleFont(for size: GlanceSystemSize) -> Font {
        switch size {
        case .small:
            return .subheadline
        case .medium:
            return .headline
        case .large:
            return .title3
        }
    }

    private func countFont(for size: GlanceSystemSize) -> Font {
        switch size {
        case .small:
            return .caption2
        case .medium:
            return .subheadline
        case .large:
            return .headline
        }
    }

    private func itemFont(for size: GlanceSystemSize) -> Font {
        switch size {
        case .small:
            return .caption
        case .medium:
            return .subheadline
        case .large:
            return .body
        }
    }

    private func secondaryFont(for size: GlanceSystemSize) -> Font {
        switch size {
        case .small:
            return .caption2
        case .medium:
            return .caption
        case .large:
            return .subheadline
        }
    }

    private func checkboxFont(for size: GlanceSystemSize) -> Font {
        switch size {
        case .small:
            return .caption
        case .medium:
            return .body
        case .large:
            return .title3
        }
    }

    private func iconFont(for size: GlanceSystemSize) -> Font {
        switch size {
        case .small:
            return .caption
        case .medium:
            return .subheadline
        case .large:
            return .body
        }
    }

    private func itemSpacing(for size: GlanceSystemSize) -> CGFloat {
        switch size {
        case .small:
            return 4
        case .medium:
            return 6
        case .large:
            return 8
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

struct ListWidget: Widget {
    let kind: String = "ListWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: ListWidgetIntent.self,
            provider: ListWidgetProvider()
        ) { entry in
            ListWidgetEntryView(entry: entry)
                .glanceContainerBackground(
                    Color(argb: entry.data.theme?.backgroundColor
                          ?? WidgetThemeData.defaultDark.backgroundColor)
                )
        }
        .configurationDisplayName("List Widget")
        .description("Display a list of items with optional checkboxes. Perfect for todos, shopping lists, or quick notes.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .accessoryCircular, .accessoryRectangular, .accessoryInline])
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
