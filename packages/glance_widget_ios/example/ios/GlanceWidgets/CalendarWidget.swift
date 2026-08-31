import WidgetKit
import SwiftUI

// MARK: - Timeline Provider

struct CalendarWidgetProvider: TimelineProvider {
    typealias Entry = CalendarWidgetEntry

    func placeholder(in context: Context) -> CalendarWidgetEntry {
        CalendarWidgetEntry(date: Date(), data: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (CalendarWidgetEntry) -> Void) {
        let data = WidgetStorage.shared.loadCalendarWidget() ?? .placeholder
        completion(CalendarWidgetEntry(date: Date(), data: data))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CalendarWidgetEntry>) -> Void) {
        let data = WidgetStorage.shared.loadCalendarWidget() ?? .placeholder
        let entry = CalendarWidgetEntry(date: Date(), data: data)

        // Check for configured timeline refresh interval
        let refreshInterval = WidgetStorage.shared.getTimelineRefreshInterval()
        let policy: TimelineReloadPolicy
        if let interval = refreshInterval {
            policy = .after(Date().addingTimeInterval(TimeInterval(interval * 60)))
        } else {
            policy = .never
        }
        let timeline = Timeline(entries: [entry], policy: policy)
        completion(timeline)
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

    private var theme: WidgetThemeData {
        entry.data.theme
            ?? WidgetStorage.shared.loadGlobalTheme()
            ?? (colorScheme == .dark ? .defaultDark : .defaultLight)
    }

    private var maxEventsToShow: Int {
        switch family {
        case .systemSmall:
            return min(2, entry.data.maxEvents)
        case .systemMedium:
            return min(3, entry.data.maxEvents)
        case .systemLarge:
            return min(8, entry.data.maxEvents)
        @unknown default:
            return entry.data.maxEvents
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
                VStack(alignment: .leading, spacing: contentSpacing(for: family)) {
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
                .padding(dynamicPadding(for: family))
            }
        }
        .widgetURL(widgetURL)
    }

    // MARK: - Subviews

    @ViewBuilder
    private func dateHeaderView(textColor: Color, secondaryTextColor: Color, accentColor: Color) -> some View {
        HStack(spacing: 10) {
            // Day number
            VStack(spacing: 2) {
                Text(dayOfWeek)
                    .font(dayOfWeekFont(for: family))
                    .fontWeight(.medium)
                    .foregroundColor(accentColor)
                    .textCase(.uppercase)

                Text(dayNumber)
                    .font(dayNumberFont(for: family))
                    .fontWeight(.bold)
                    .foregroundColor(textColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.data.title)
                    .font(titleFont(for: family))
                    .fontWeight(.bold)
                    .foregroundColor(textColor)
                    .lineLimit(1)

                Text(monthYear)
                    .font(subtitleFont(for: family))
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
                    .font(emptyIconFont(for: family))
                    .foregroundColor(secondaryTextColor.opacity(0.5))
                Text("No events")
                    .font(eventTitleFont(for: family))
                    .foregroundColor(secondaryTextColor)
            }
            Spacer()
        }
        Spacer()
    }

    @ViewBuilder
    private func eventsListView(textColor: Color, secondaryTextColor: Color, accentColor: Color) -> some View {
        VStack(alignment: .leading, spacing: eventSpacing(for: family)) {
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
                .frame(width: dotSize(for: family), height: dotSize(for: family))

            // Event details
            VStack(alignment: .leading, spacing: 1) {
                Text(event.title)
                    .font(eventTitleFont(for: family))
                    .foregroundColor(textColor)
                    .lineLimit(1)

                Text(event.isAllDay ? "All day" : event.time)
                    .font(eventTimeFont(for: family))
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

    private func subtitleFont(for family: WidgetFamily) -> Font {
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

    private func dayOfWeekFont(for family: WidgetFamily) -> Font {
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

    private func dayNumberFont(for family: WidgetFamily) -> Font {
        switch family {
        case .systemSmall:
            return .title3
        case .systemMedium:
            return .title2
        case .systemLarge:
            return .title
        @unknown default:
            return .title2
        }
    }

    private func eventTitleFont(for family: WidgetFamily) -> Font {
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

    private func eventTimeFont(for family: WidgetFamily) -> Font {
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

    private func emptyIconFont(for family: WidgetFamily) -> Font {
        switch family {
        case .systemSmall:
            return .title3
        case .systemMedium:
            return .title2
        case .systemLarge:
            return .title
        @unknown default:
            return .title2
        }
    }

    private func dotSize(for family: WidgetFamily) -> CGFloat {
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

    private func eventSpacing(for family: WidgetFamily) -> CGFloat {
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

struct CalendarWidget: Widget {
    let kind: String = "CalendarWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CalendarWidgetProvider()) { entry in
            if #available(iOS 17.0, *) {
                CalendarWidgetEntryView(entry: entry)
                    .containerBackground(for: .widget) {
                        Color(argb: entry.data.theme?.backgroundColor
                              ?? WidgetThemeData.defaultDark.backgroundColor)
                    }
            } else {
                CalendarWidgetEntryView(entry: entry)
            }
        }
        .configurationDisplayName("Calendar Widget")
        .description("Display upcoming events with date header and colored indicators. Perfect for schedules and agendas.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
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
