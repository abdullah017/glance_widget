import WidgetKit
import SwiftUI

// MARK: - Timeline Provider

struct ProgressWidgetProvider: TimelineProvider {
    typealias Entry = ProgressWidgetEntry

    func placeholder(in context: Context) -> ProgressWidgetEntry {
        ProgressWidgetEntry(date: Date(), data: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (ProgressWidgetEntry) -> Void) {
        let data = WidgetStorage.shared.loadProgressWidget() ?? .placeholder
        completion(ProgressWidgetEntry(date: Date(), data: data))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ProgressWidgetEntry>) -> Void) {
        let data = WidgetStorage.shared.loadProgressWidget() ?? .placeholder
        let entry = ProgressWidgetEntry(date: Date(), data: data)

        // Use .never policy for instant updates when app triggers reload
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
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

    private var theme: WidgetThemeData {
        entry.data.theme
            ?? WidgetStorage.shared.loadGlobalTheme()
            ?? (colorScheme == .dark ? .defaultDark : .defaultLight)
    }

    var body: some View {
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
                        .font(titleFont(for: family))
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
                            .font(subtitleFont(for: family))
                            .foregroundColor(secondaryTextColor)
                            .lineLimit(1)
                    }
                }
                .padding(dynamicPadding(for: family))
            }
        }
        .widgetURL(widgetURL)
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
        let size = circularSize(for: family, geometry: geometry)
        let lineWidth = circularLineWidth(for: family)

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
                .font(percentageFont(for: family))
                .fontWeight(.bold)
                .foregroundColor(textColor)
        }
        .frame(width: size, height: size)
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
                .font(percentageFont(for: family))
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
            .frame(height: linearBarHeight(for: family))
        }
    }

    // MARK: - Computed Properties

    private var widgetURL: URL? {
        URL(string: "glancewidget://action?widgetId=\(entry.data.widgetId)&type=tap")
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

    private func percentageFont(for family: WidgetFamily) -> Font {
        switch family {
        case .systemSmall:
            return .caption
        case .systemMedium:
            return .title3
        case .systemLarge:
            return .title
        @unknown default:
            return .title3
        }
    }

    private func circularSize(for family: WidgetFamily, geometry: GeometryProxy) -> CGFloat {
        let minDimension = min(geometry.size.width, geometry.size.height)
        switch family {
        case .systemSmall:
            return minDimension * 0.45
        case .systemMedium:
            return minDimension * 0.5
        case .systemLarge:
            return minDimension * 0.35
        @unknown default:
            return 80
        }
    }

    private func circularLineWidth(for family: WidgetFamily) -> CGFloat {
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

    private func linearBarHeight(for family: WidgetFamily) -> CGFloat {
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

    private func dynamicPadding(for family: WidgetFamily) -> EdgeInsets {
        switch family {
        case .systemSmall:
            return EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12)
        case .systemMedium:
            return EdgeInsets(top: 16, leading: 20, bottom: 16, trailing: 20)
        case .systemLarge:
            return EdgeInsets(top: 20, leading: 24, bottom: 20, trailing: 24)
        @unknown default:
            return EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
        }
    }
}

// MARK: - Widget Configuration

struct ProgressWidget: Widget {
    let kind: String = "ProgressWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ProgressWidgetProvider()) { entry in
            if #available(iOS 17.0, *) {
                ProgressWidgetEntryView(entry: entry)
                    .containerBackground(for: .widget) {
                        Color(argb: entry.data.theme?.backgroundColor
                              ?? WidgetThemeData.defaultDark.backgroundColor)
                    }
            } else {
                ProgressWidgetEntryView(entry: entry)
            }
        }
        .configurationDisplayName("Progress Widget")
        .description("Display progress with circular or linear indicator. Great for goals, downloads, or completion status.")
        .supportedFamilies([.systemSmall, .systemMedium])
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
