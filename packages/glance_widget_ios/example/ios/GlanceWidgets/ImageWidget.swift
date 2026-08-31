#if canImport(UIKit)
import UIKit
#endif
import WidgetKit
import SwiftUI

// MARK: - Timeline Provider

struct ImageWidgetProvider: TimelineProvider {
    typealias Entry = ImageWidgetEntry

    func placeholder(in context: Context) -> ImageWidgetEntry {
        ImageWidgetEntry(date: Date(), data: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (ImageWidgetEntry) -> Void) {
        let data = WidgetStorage.shared.loadImageWidget() ?? .placeholder
        completion(ImageWidgetEntry(date: Date(), data: data))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ImageWidgetEntry>) -> Void) {
        let data = WidgetStorage.shared.loadImageWidget() ?? .placeholder
        let entry = ImageWidgetEntry(date: Date(), data: data)

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

struct ImageWidgetEntry: TimelineEntry {
    let date: Date
    let data: ImageWidgetData
}

// MARK: - Widget View

struct ImageWidgetEntryView: View {
    var entry: ImageWidgetProvider.Entry
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.widgetFamily) var family

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
        let imageHeight = imageAreaHeight(for: family, geometry: geometry)

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
                        .font(placeholderIconFont(for: family))
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
                .font(titleFont(for: family))
                .fontWeight(.bold)
                .foregroundColor(textColor)
                .lineLimit(1)

            if let subtitle = entry.data.subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .font(subtitleFont(for: family))
                    .foregroundColor(secondaryTextColor)
                    .lineLimit(family == .systemLarge ? 2 : 1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(textPadding(for: family))
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

    private func imageAreaHeight(for family: WidgetFamily, geometry: GeometryProxy) -> CGFloat {
        switch family {
        case .systemSmall:
            return geometry.size.height * 0.6
        case .systemMedium:
            return geometry.size.height * 0.6
        case .systemLarge:
            return geometry.size.height * 0.7
        @unknown default:
            return geometry.size.height * 0.6
        }
    }

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

    private func placeholderIconFont(for family: WidgetFamily) -> Font {
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

    private func textPadding(for family: WidgetFamily) -> EdgeInsets {
        switch family {
        case .systemSmall:
            return EdgeInsets(top: 6, leading: 10, bottom: 8, trailing: 10)
        case .systemMedium:
            return EdgeInsets(top: 8, leading: 14, bottom: 10, trailing: 14)
        case .systemLarge:
            return EdgeInsets(top: 10, leading: 16, bottom: 12, trailing: 16)
        @unknown default:
            return EdgeInsets(top: 8, leading: 14, bottom: 10, trailing: 14)
        }
    }
}

// MARK: - Widget Configuration

struct ImageWidget: Widget {
    let kind: String = "ImageWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ImageWidgetProvider()) { entry in
            if #available(iOS 17.0, *) {
                ImageWidgetEntryView(entry: entry)
                    .containerBackground(for: .widget) {
                        Color(argb: entry.data.theme?.backgroundColor
                              ?? WidgetThemeData.defaultDark.backgroundColor)
                    }
            } else {
                ImageWidgetEntryView(entry: entry)
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
