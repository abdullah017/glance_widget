import AppIntents
import WidgetKit
import SwiftUI

// MARK: - Configuration

/// The ids this template has data for, offered when the user edits the widget.
struct CalendarWidgetIdOptions: DynamicOptionsProvider {
    func results() async throws -> [String] {
        WidgetStorage.shared.knownWidgetIds(prefix: "calendarWidgetData_")
    }
}

/// Carries the `widgetId` a placed instance should render.
///
/// `widgetId` is documented as a "unique identifier for this widget instance",
/// and without a per-instance parameter there is nothing for the extension to
/// key on: every placed widget read the most recently written payload, so two
/// widgets built from this template always showed the same thing.
struct CalendarWidgetIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Calendar Widget" }
    static var description: IntentDescription {
        IntentDescription("Choose which of your app's widgets this one shows.")
    }

    @Parameter(title: "Widget", optionsProvider: CalendarWidgetIdOptions())
    var widgetId: String?

    init() {}

    init(widgetId: String?) {
        self.widgetId = widgetId
    }
}

// MARK: - Timeline Provider

struct CalendarWidgetProvider: AppIntentTimelineProvider {
    typealias Entry = CalendarWidgetEntry
    typealias Intent = CalendarWidgetIntent

    func placeholder(in context: Context) -> CalendarWidgetEntry {
        CalendarWidgetEntry(date: Date(), data: .placeholder)
    }

    func snapshot(for configuration: CalendarWidgetIntent, in context: Context) async -> CalendarWidgetEntry {
        CalendarWidgetEntry(date: Date(), data: load(for: configuration))
    }

    func timeline(
        for configuration: CalendarWidgetIntent,
        in context: Context
    ) async -> Timeline<CalendarWidgetEntry> {
        let entry = CalendarWidgetEntry(date: Date(), data: load(for: configuration))

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
    private func load(for configuration: CalendarWidgetIntent) -> CalendarWidgetData {
        WidgetStorage.shared.loadCalendarWidget(widgetId: configuration.widgetId) ?? .placeholder
    }
}

// MARK: - Timeline Entry

struct CalendarWidgetEntry: TimelineEntry {
    let date: Date
    let data: CalendarWidgetData
}

// MARK: - Widget View

struct CalendarWidgetEntryView: View {
    var entry: CalendarWidgetProvider.Entry
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.widgetFamily) var family

    /// The layout shape this family wants. See `GlanceSystemSize`.
    private var size: GlanceSystemSize { GlanceSystemSize(family) }

    private var theme: WidgetThemeData {
        entry.data.theme
            ?? WidgetStorage.shared.loadGlobalTheme()
            ?? (colorScheme == .dark ? .defaultDark : .defaultLight)
    }

    private var maxEventsToShow: Int {
        switch size {
        case .small:
            return min(2, entry.data.maxEvents)
        case .medium:
            return min(3, entry.data.maxEvents)
        case .large:
            return min(8, entry.data.maxEvents)
        }
    }

    private var parsedDate: Date {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: entry.data.date) {
            return date
        }
        // Try without fractional seconds
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: entry.data.date) ?? Date()
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
                VStack(alignment: .leading, spacing: contentSpacing(for: size)) {
                    // Date header
                    dateHeaderView(
                        textColor: textColor,
                        secondaryTextColor: secondaryTextColor,
                        accentColor: accentColor
                    )

                    // Divider
                    Rectangle()
                        .fill(secondaryTextColor.opacity(0.3))
                        .frame(height: 1)

                    if entry.data.events.isEmpty {
                        // Empty state
                        emptyStateView(secondaryTextColor: secondaryTextColor)
                    } else {
                        // Events list
                        eventsListView(
                            textColor: textColor,
                            secondaryTextColor: secondaryTextColor,
                            accentColor: accentColor
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
            GlanceCircularText(value: dayNumber, caption: dayOfWeek)
        case .rectangular:
            GlanceRectangularStack(title: entry.data.title) {
                if entry.data.events.isEmpty {
                    Text("No events")
                        .font(.system(size: 12))
                } else {
                    ForEach(Array(entry.data.events.prefix(2).enumerated()), id: \.offset) { _, event in
                        Text(accessoryLine(for: event))
                            .font(.system(size: 12))
                            .lineLimit(1)
                    }
                }
            }
        case .inline:
            Text(accessoryInlineText)
        }
    }

    /// One event on one line, the way the home screen layout splits it.
    private func accessoryLine(for event: CalendarEventData) -> String {
        let when = event.isAllDay ? "All day" : event.time
        return "\(when)  \(event.title)"
    }

    /// The next event, or the date itself when the day is empty.
    private var accessoryInlineText: String {
        guard let next = entry.data.events.first else {
            return "\(dayOfWeek) \(dayNumber)"
        }
        return accessoryLine(for: next)
    }

    // MARK: - Subviews

    @ViewBuilder
    private func dateHeaderView(textColor: Color, secondaryTextColor: Color, accentColor: Color) -> some View {
        HStack(spacing: 10) {
            // Day number
            VStack(spacing: 2) {
                Text(dayOfWeek)
                    .font(dayOfWeekFont(for: size))
                    .fontWeight(.medium)
                    .foregroundColor(accentColor)
                    .textCase(.uppercase)

                Text(dayNumber)
                    .font(dayNumberFont(for: size))
                    .fontWeight(.bold)
                    .foregroundColor(textColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.data.title)
                    .font(titleFont(for: size))
                    .fontWeight(.bold)
                    .foregroundColor(textColor)
                    .lineLimit(1)

                Text(monthYear)
                    .font(subtitleFont(for: size))
                    .foregroundColor(secondaryTextColor)
                    .lineLimit(1)
            }

            Spacer()
        }
    }

    @ViewBuilder
    private func emptyStateView(secondaryTextColor: Color) -> some View {
        Spacer()
        HStack {
            Spacer()
            VStack(spacing: 4) {
                Image(systemName: "calendar")
                    .font(emptyIconFont(for: size))
                    .foregroundColor(secondaryTextColor.opacity(0.5))
                Text("No events")
                    .font(eventTitleFont(for: size))
                    .foregroundColor(secondaryTextColor)
            }
            Spacer()
        }
        Spacer()
    }

    @ViewBuilder
    private func eventsListView(textColor: Color, secondaryTextColor: Color, accentColor: Color) -> some View {
        VStack(alignment: .leading, spacing: eventSpacing(for: size)) {
            ForEach(Array(entry.data.events.prefix(maxEventsToShow).enumerated()), id: \.offset) { index, event in
                eventRowView(
                    event: event,
                    index: index,
                    textColor: textColor,
                    secondaryTextColor: secondaryTextColor,
                    accentColor: accentColor
                )
            }

            // Show "more" indicator if there are more events
            if entry.data.events.count > maxEventsToShow {
                Text("+\(entry.data.events.count - maxEventsToShow) more")
                    .font(.caption2)
                    .foregroundColor(secondaryTextColor)
            }
        }
    }

    @ViewBuilder
    private func eventRowView(
        event: CalendarEventData,
        index: Int,
        textColor: Color,
        secondaryTextColor: Color,
        accentColor: Color
    ) -> some View {
        HStack(spacing: 8) {
            // Color dot
            Circle()
                .fill(event.color.map { Color(argb: $0) } ?? accentColor)
                .frame(width: dotSize(for: size), height: dotSize(for: size))

            // Event details
            VStack(alignment: .leading, spacing: 1) {
                Text(event.title)
                    .font(eventTitleFont(for: size))
                    .foregroundColor(textColor)
                    .lineLimit(1)

                Text(event.isAllDay ? "All day" : event.time)
                    .font(eventTimeFont(for: size))
                    .foregroundColor(secondaryTextColor)
                    .lineLimit(1)
            }

            Spacer()
        }
    }

    // MARK: - Computed Properties

    private var widgetURL: URL? {
        if let deepLink = entry.data.deepLinkUri, let url = URL(string: deepLink) {
            return url
        }
        return URL(string: "glancewidget://action?widgetId=\(entry.data.widgetId)&type=tap")
    }

    private var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: parsedDate)
    }

    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: parsedDate)
    }

    private var monthYear: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: parsedDate)
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

    private func dayOfWeekFont(for size: GlanceSystemSize) -> Font {
        switch size {
        case .small:
            return .caption2
        case .medium:
            return .caption
        case .large:
            return .subheadline
        }
    }

    private func dayNumberFont(for size: GlanceSystemSize) -> Font {
        switch size {
        case .small:
            return .title3
        case .medium:
            return .title2
        case .large:
            return .title
        }
    }

    private func eventTitleFont(for size: GlanceSystemSize) -> Font {
        switch size {
        case .small:
            return .caption
        case .medium:
            return .subheadline
        case .large:
            return .body
        }
    }

    private func eventTimeFont(for size: GlanceSystemSize) -> Font {
        switch size {
        case .small:
            return .caption2
        case .medium:
            return .caption
        case .large:
            return .subheadline
        }
    }

    private func emptyIconFont(for size: GlanceSystemSize) -> Font {
        switch size {
        case .small:
            return .title3
        case .medium:
            return .title2
        case .large:
            return .title
        }
    }

    private func dotSize(for size: GlanceSystemSize) -> CGFloat {
        switch size {
        case .small:
            return 6
        case .medium:
            return 8
        case .large:
            return 10
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

    private func eventSpacing(for size: GlanceSystemSize) -> CGFloat {
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

struct CalendarWidget: Widget {
    let kind: String = "CalendarWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: CalendarWidgetIntent.self,
            provider: CalendarWidgetProvider()
        ) { entry in
            CalendarWidgetEntryView(entry: entry)
                .glanceContainerBackground(
                    Color(argb: entry.data.theme?.backgroundColor
                          ?? WidgetThemeData.defaultDark.backgroundColor)
                )
        }
        .configurationDisplayName("Calendar Widget")
        .description("Display upcoming events with date header and colored indicators. Perfect for schedules and agendas.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

// MARK: - Preview

#if DEBUG
struct CalendarWidget_Previews: PreviewProvider {
    static var previews: some View {
        CalendarWidgetEntryView(
            entry: CalendarWidgetEntry(
                date: Date(),
                data: CalendarWidgetData(
                    widgetId: "preview",
                    title: "Today",
                    date: ISO8601DateFormatter().string(from: Date()),
                    events: [
                        CalendarEventData(time: "09:00", title: "Team Standup", color: 0xFF2196F3, isAllDay: false),
                        CalendarEventData(time: "12:00", title: "Lunch with Alex", color: 0xFF4CAF50, isAllDay: false),
                        CalendarEventData(time: "14:30", title: "Design Review", color: 0xFFFFA726, isAllDay: false),
                    ],
                    maxEvents: 5,
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
