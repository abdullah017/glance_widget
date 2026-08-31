#if canImport(UIKit)
import UIKit
#endif
import AppIntents
import WidgetKit
import SwiftUI

// MARK: - Configuration

/// The ids this template has data for, offered when the user edits the widget.
struct ImageWidgetIdOptions: DynamicOptionsProvider {
    func results() async throws -> [String] {
        WidgetStorage.shared.knownWidgetIds(prefix: "imageWidgetData_")
    }
}

/// Carries the `widgetId` a placed instance should render.
///
/// `widgetId` is documented as a "unique identifier for this widget instance",
/// and without a per-instance parameter there is nothing for the extension to
/// key on: every placed widget read the most recently written payload, so two
/// widgets built from this template always showed the same thing.
struct ImageWidgetIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Image Widget" }
    static var description: IntentDescription {
        IntentDescription("Choose which of your app's widgets this one shows.")
    }

    @Parameter(title: "Widget", optionsProvider: ImageWidgetIdOptions())
    var widgetId: String?

    init() {}

    init(widgetId: String?) {
        self.widgetId = widgetId
    }
}

// MARK: - Timeline Provider

struct ImageWidgetProvider: AppIntentTimelineProvider {
    typealias Entry = ImageWidgetEntry
    typealias Intent = ImageWidgetIntent

    func placeholder(in context: Context) -> ImageWidgetEntry {
        ImageWidgetEntry(date: Date(), data: .placeholder)
    }

    func snapshot(for configuration: ImageWidgetIntent, in context: Context) async -> ImageWidgetEntry {
        ImageWidgetEntry(date: Date(), data: load(for: configuration))
    }

    func timeline(
        for configuration: ImageWidgetIntent,
        in context: Context
    ) async -> Timeline<ImageWidgetEntry> {
        let entry = ImageWidgetEntry(date: Date(), data: load(for: configuration))

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
    private func load(for configuration: ImageWidgetIntent) -> ImageWidgetData {
        WidgetStorage.shared.loadImageWidget(widgetId: configuration.widgetId) ?? .placeholder
    }
}

// MARK: - Timeline Entry

struct ImageWidgetEntry: TimelineEntry {
    let date: Date
    let data: ImageWidgetData
}

// MARK: - Widget View

struct ImageWidgetEntryView: View {
    var entry: ImageWidgetProvider.Entry
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.widgetFamily) var family

    /// The layout shape this family wants. See `GlanceSystemSize`.
    private var size: GlanceSystemSize { GlanceSystemSize(family) }

    private var theme: WidgetThemeData {
        entry.data.theme
            ?? WidgetStorage.shared.loadGlobalTheme()
            ?? (colorScheme == .dark ? .defaultDark : .defaultLight)
    }

    private var decodedImage: UIImage? {
        // The plugin resolved and downsampled the picture at update time, so
        // this is a small file read rather than a full-size decode.
        if let path = entry.data.imagePath, let image = UIImage(contentsOfFile: path) {
            return image
        }
        // Kept for data written by an older version of the plugin, which stored
        // the bytes inline.
        guard let base64String = entry.data.imageBase64,
              let imageData = Data(base64Encoded: base64String) else {
            return nil
        }
        return UIImage(data: imageData)
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
                VStack(spacing: 0) {
                    // Image area
                    imageView(geometry: geometry)

                    // Text overlay area
                    textOverlayView(
                        textColor: textColor,
                        secondaryTextColor: secondaryTextColor
                    )
                }
                .clipShape(RoundedRectangle(cornerRadius: theme.borderRadius))
            }
        }
        .widgetURL(widgetURL)
    }

    // MARK: - Subviews

    @ViewBuilder
    private func imageView(geometry: GeometryProxy) -> some View {
        let imageHeight = imageAreaHeight(for: size, geometry: geometry)

        if let uiImage = decodedImage {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: contentMode)
                .frame(maxWidth: .infinity)
                .frame(height: imageHeight)
                .clipped()
        } else {
            // Placeholder when no image is available
            ZStack {
                Color(argb: theme.secondaryTextColor).opacity(0.1)

                VStack(spacing: 4) {
                    Image(systemName: "photo")
                        .font(placeholderIconFont(for: size))
                        .foregroundColor(Color(argb: theme.secondaryTextColor).opacity(0.4))

                    if let imageUrl = entry.data.imageUrl, !imageUrl.isEmpty {
                        // Reaching here means the fetch failed; the plugin
                        // resolves imageUrl before the widget is ever drawn.
                        Text("Image unavailable")
                            .font(.caption2)
                            .foregroundColor(Color(argb: theme.secondaryTextColor).opacity(0.4))
                            .lineLimit(1)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: imageHeight)
        }
    }

    @ViewBuilder
    private func textOverlayView(textColor: Color, secondaryTextColor: Color) -> some View {
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
                    .lineLimit(size == .large ? 2 : 1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(textPadding(for: size))
    }

    // MARK: - Computed Properties

    private var widgetURL: URL? {
        if let deepLink = entry.data.deepLinkUri, let url = URL(string: deepLink) {
            return url
        }
        return URL(string: "glancewidget://action?widgetId=\(entry.data.widgetId)&type=tap")
    }

    private var contentMode: ContentMode {
        switch entry.data.fit {
        case "contain":
            return .fit
        case "fill", "cover":
            return .fill
        default:
            return .fill
        }
    }

    // MARK: - Dynamic Sizing

    private func imageAreaHeight(for size: GlanceSystemSize, geometry: GeometryProxy) -> CGFloat {
        switch size {
        case .small:
            return geometry.size.height * 0.6
        case .medium:
            return geometry.size.height * 0.6
        case .large:
            return geometry.size.height * 0.7
        }
    }

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

    private func placeholderIconFont(for size: GlanceSystemSize) -> Font {
        switch size {
        case .small:
            return .title3
        case .medium:
            return .title2
        case .large:
            return .title
        }
    }

    private func textPadding(for size: GlanceSystemSize) -> EdgeInsets {
        switch size {
        case .small:
            return EdgeInsets(top: 6, leading: 10, bottom: 8, trailing: 10)
        case .medium:
            return EdgeInsets(top: 8, leading: 14, bottom: 10, trailing: 14)
        case .large:
            return EdgeInsets(top: 10, leading: 16, bottom: 12, trailing: 16)
        }
    }
}

// MARK: - Widget Configuration

struct ImageWidget: Widget {
    let kind: String = "ImageWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: ImageWidgetIntent.self,
            provider: ImageWidgetProvider()
        ) { entry in
            ImageWidgetEntryView(entry: entry)
                .containerBackground(for: .widget) {
                    Color(argb: entry.data.theme?.backgroundColor
                          ?? WidgetThemeData.defaultDark.backgroundColor)
                }
        }
        .configurationDisplayName("Image Widget")
        .description("Display an image with title and subtitle. Supports base64-encoded images for reliable offline display.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Preview

#if DEBUG
struct ImageWidget_Previews: PreviewProvider {
    static var previews: some View {
        ImageWidgetEntryView(
            entry: ImageWidgetEntry(
                date: Date(),
                data: ImageWidgetData(
                    widgetId: "preview",
                    title: "Vacation Photo",
                    imageUrl: nil,
                    imageBase64: nil,
                    subtitle: "Summer 2025",
                    fit: "cover",
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
