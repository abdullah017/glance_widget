import SwiftUI
import WidgetKit

// MARK: - App Group Configuration

/// App Group ID for sharing data between Flutter app and widget extension.
/// **Important**: This must match the App Group ID configured in both targets' entitlements.
enum AppConfig {
    static let appGroupId = "group.com.example.glancewidget"
}

// MARK: - Simple Widget Data

struct SimpleWidgetData: Codable {
    let widgetId: String
    let title: String
    let value: String
    let subtitle: String?
    let subtitleColor: Int?
    let iconName: String?
    let iconBase64: String?
    let deepLinkUri: String?
    let timestamp: Double
    let theme: WidgetThemeData?

    static var placeholder: SimpleWidgetData {
        SimpleWidgetData(
            widgetId: "simple",
            title: "Widget",
            value: "--",
            subtitle: nil,
            subtitleColor: nil,
            iconName: nil,
            iconBase64: nil,
            deepLinkUri: nil,
            timestamp: Date().timeIntervalSince1970,
            theme: nil
        )
    }
}

// MARK: - Progress Widget Data

struct ProgressWidgetData: Codable {
    let widgetId: String
    let title: String
    let progress: Double
    let subtitle: String?
    let progressType: String  // "circular" or "linear"
    let progressColor: Int?
    let trackColor: Int?
    let deepLinkUri: String?
    let timestamp: Double
    let theme: WidgetThemeData?

    static var placeholder: ProgressWidgetData {
        ProgressWidgetData(
            widgetId: "progress",
            title: "Progress",
            progress: 0.0,
            subtitle: nil,
            progressType: "circular",
            progressColor: nil,
            trackColor: nil,
            deepLinkUri: nil,
            timestamp: Date().timeIntervalSince1970,
            theme: nil
        )
    }
}

// MARK: - List Widget Data

struct ListWidgetData: Codable {
    let widgetId: String
    let title: String
    let items: [ListItemData]
    let showCheckboxes: Bool
    let maxItems: Int
    let deepLinkUri: String?
    let timestamp: Double
    let theme: WidgetThemeData?

    static var placeholder: ListWidgetData {
        ListWidgetData(
            widgetId: "list",
            title: "List",
            items: [
                ListItemData(text: "Item 1", checked: false, secondaryText: nil, iconName: nil),
                ListItemData(text: "Item 2", checked: true, secondaryText: nil, iconName: nil),
            ],
            showCheckboxes: true,
            maxItems: 5,
            deepLinkUri: nil,
            timestamp: Date().timeIntervalSince1970,
            theme: nil
        )
    }
}

struct ListItemData: Codable {
    let text: String
    let checked: Bool
    let secondaryText: String?
    let iconName: String?
}

// MARK: - Calendar Widget Data

struct CalendarWidgetData: Codable {
    let widgetId: String
    let title: String
    let date: String  // ISO 8601 format
    let events: [CalendarEventData]
    let maxEvents: Int
    let deepLinkUri: String?
    let timestamp: Double
    let theme: WidgetThemeData?

    static var placeholder: CalendarWidgetData {
        CalendarWidgetData(
            widgetId: "calendar",
            title: "Today",
            date: ISO8601DateFormatter().string(from: Date()),
            events: [
                CalendarEventData(time: "09:00", title: "Meeting", color: 0xFF2196F3, isAllDay: false),
                CalendarEventData(time: "12:00", title: "Lunch", color: 0xFF4CAF50, isAllDay: false),
            ],
            maxEvents: 5,
            deepLinkUri: nil,
            timestamp: Date().timeIntervalSince1970,
            theme: nil
        )
    }
}

struct CalendarEventData: Codable {
    let time: String
    let title: String
    let color: Int?
    let isAllDay: Bool
}

// MARK: - Image Widget Data

struct ImageWidgetData: Codable {
    let widgetId: String
    let title: String
    let imageUrl: String?
    let imageBase64: String?
    /// Where the plugin put the fetched, downsampled picture. `imageUrl` is
    /// resolved when the update is applied, not here: an extension cannot
    /// afford the memory of a full-size decode and WidgetKit will not wait for
    /// a network round trip during a reload.
    let imagePath: String?
    let subtitle: String?
    let fit: String  // "cover", "contain", "fill"
    let deepLinkUri: String?
    let timestamp: Double
    let theme: WidgetThemeData?

    static var placeholder: ImageWidgetData {
        ImageWidgetData(
            widgetId: "image",
            title: "Photo",
            imageUrl: nil,
            imageBase64: nil,
            imagePath: nil,
            subtitle: nil,
            fit: "cover",
            deepLinkUri: nil,
            timestamp: Date().timeIntervalSince1970,
            theme: nil
        )
    }
}

// MARK: - Chart Widget Data

struct ChartWidgetData: Codable {
    let widgetId: String
    let title: String
    let dataPoints: [Double]
    let chartType: String  // "line", "bar", "sparkline"
    let color: Int?
    let subtitle: String?
    let deepLinkUri: String?
    let timestamp: Double
    let theme: WidgetThemeData?

    static var placeholder: ChartWidgetData {
        ChartWidgetData(
            widgetId: "chart",
            title: "Chart",
            dataPoints: [10, 25, 15, 30, 20, 35, 28],
            chartType: "line",
            color: nil,
            subtitle: nil,
            deepLinkUri: nil,
            timestamp: Date().timeIntervalSince1970,
            theme: nil
        )
    }
}

// MARK: - Gauge Widget Data

struct GaugeWidgetData: Codable {
    let widgetId: String
    let title: String
    let metrics: [GaugeMetricData]
    let gaugeType: String  // "radial", "dashboard"
    let deepLinkUri: String?
    let timestamp: Double
    let theme: WidgetThemeData?

    static var placeholder: GaugeWidgetData {
        GaugeWidgetData(
            widgetId: "gauge",
            title: "Metrics",
            metrics: [
                GaugeMetricData(label: "CPU", value: 65, maxValue: 100, color: 0xFF2196F3, unit: "%"),
                GaugeMetricData(label: "RAM", value: 4.2, maxValue: 8.0, color: 0xFF4CAF50, unit: "GB"),
            ],
            gaugeType: "radial",
            deepLinkUri: nil,
            timestamp: Date().timeIntervalSince1970,
            theme: nil
        )
    }
}

struct GaugeMetricData: Codable {
    let label: String
    let value: Double
    let maxValue: Double
    let color: Int?
    let unit: String?
}

// MARK: - Theme Data

struct WidgetThemeData: Codable {
    let backgroundColor: Int
    let textColor: Int
    let secondaryTextColor: Int
    let accentColor: Int
    let borderRadius: Double
    let isDark: Bool

    static var defaultDark: WidgetThemeData {
        WidgetThemeData(
            backgroundColor: 0xFF1A1A2E,
            textColor: 0xFFFFFFFF,
            secondaryTextColor: 0xFFB0B0B0,
            accentColor: 0xFFFFA726,
            borderRadius: 16.0,
            isDark: true
        )
    }

    static var defaultLight: WidgetThemeData {
        WidgetThemeData(
            backgroundColor: 0xFFFFFFFF,
            textColor: 0xFF212121,
            secondaryTextColor: 0xFF757575,
            accentColor: 0xFF2196F3,
            borderRadius: 16.0,
            isDark: false
        )
    }
}

// MARK: - Color Extension

extension Color {
    /// Creates a Color from an ARGB integer value (0xAARRGGBB format)
    init(argb: Int) {
        let alpha = Double((argb >> 24) & 0xFF) / 255.0
        let red = Double((argb >> 16) & 0xFF) / 255.0
        let green = Double((argb >> 8) & 0xFF) / 255.0
        let blue = Double(argb & 0xFF) / 255.0
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }
}

// MARK: - Widget Storage

/// Reads widget data from App Group shared storage.
///
/// This class is used by the widget extension to load data that was
/// saved by the Flutter app via the GlanceWidgetManager.
class WidgetStorage {
    static let shared = WidgetStorage()

    private let userDefaults: UserDefaults?
    private let decoder = JSONDecoder()

    private init() {
        userDefaults = UserDefaults(suiteName: AppConfig.appGroupId)
        if userDefaults == nil {
            print("GlanceWidget: Failed to initialize UserDefaults with App Group: \(AppConfig.appGroupId)")
        }
    }

    // MARK: - Simple Widget

    func loadSimpleWidget(widgetId: String? = nil) -> SimpleWidgetData? {
        if let widgetId = widgetId {
            return loadData(forKey: "simpleWidgetData_\(widgetId)")
        }
        return loadMostRecent(prefix: "simpleWidgetData_")
    }

    // MARK: - Progress Widget

    func loadProgressWidget(widgetId: String? = nil) -> ProgressWidgetData? {
        if let widgetId = widgetId {
            return loadData(forKey: "progressWidgetData_\(widgetId)")
        }
        return loadMostRecent(prefix: "progressWidgetData_")
    }

    // MARK: - List Widget

    func loadListWidget(widgetId: String? = nil) -> ListWidgetData? {
        if let widgetId = widgetId {
            return loadData(forKey: "listWidgetData_\(widgetId)")
        }
        return loadMostRecent(prefix: "listWidgetData_")
    }

    // MARK: - Calendar Widget

    func loadCalendarWidget(widgetId: String? = nil) -> CalendarWidgetData? {
        if let widgetId = widgetId {
            return loadData(forKey: "calendarWidgetData_\(widgetId)")
        }
        return loadMostRecent(prefix: "calendarWidgetData_")
    }

    // MARK: - Image Widget

    func loadImageWidget(widgetId: String? = nil) -> ImageWidgetData? {
        if let widgetId = widgetId {
            return loadData(forKey: "imageWidgetData_\(widgetId)")
        }
        return loadMostRecent(prefix: "imageWidgetData_")
    }

    // MARK: - Chart Widget

    func loadChartWidget(widgetId: String? = nil) -> ChartWidgetData? {
        if let widgetId = widgetId {
            return loadData(forKey: "chartWidgetData_\(widgetId)")
        }
        return loadMostRecent(prefix: "chartWidgetData_")
    }

    // MARK: - Gauge Widget

    func loadGaugeWidget(widgetId: String? = nil) -> GaugeWidgetData? {
        if let widgetId = widgetId {
            return loadData(forKey: "gaugeWidgetData_\(widgetId)")
        }
        return loadMostRecent(prefix: "gaugeWidgetData_")
    }

    // MARK: - Global Theme

    func loadGlobalTheme() -> WidgetThemeData? {
        return loadData(forKey: "globalTheme")
    }

    // MARK: - Timeline Refresh

    /// Returns the configured timeline refresh interval in minutes, if any.
    ///
    /// When a refresh interval is configured, widget timeline providers should use
    /// `.after(date)` policy instead of `.never` to enable periodic background updates.
    func getTimelineRefreshInterval() -> Int? {
        let interval = userDefaults?.integer(forKey: "timeline_refresh_interval") ?? 0
        return interval > 0 ? interval : nil
    }

    // MARK: - Widget Ids

    /// The ids the app has written data for under one template's prefix.
    ///
    /// This is what the configuration picker offers, so a placed widget can be
    /// pointed at a specific id instead of rendering whatever was updated last.
    /// It is derived from the stored payloads rather than a separate registry,
    /// so an id that has no data to show is never offered.
    ///
    /// A widget extension cannot import the plugin, so the prefixes below are
    /// typed out again here. `GlanceStorageKeys` in `glance_widget_ios` is the
    /// side that owns them and `GlanceStorageKeysTests` pins their exact
    /// values, so a rename there fails a test naming these templates rather
    /// than silently emptying this list.
    func knownWidgetIds(prefix: String) -> [String] {
        guard let defaults = userDefaults else { return [] }
        return defaults.dictionaryRepresentation().keys
            .filter { $0.hasPrefix(prefix) }
            .map { String($0.dropFirst(prefix.count)) }
            .filter { !$0.isEmpty }
            .sorted()
    }

    // MARK: - Private Helpers

    private func loadData<T: Decodable>(forKey key: String) -> T? {
        guard let data = userDefaults?.data(forKey: key) else { return nil }
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            print("GlanceWidget: Failed to decode data for key '\(key)': \(error)")
            return nil
        }
    }

    /// Fallback for an instance that has not been configured with an id yet --
    /// a freshly placed widget should show something rather than a placeholder.
    /// Every configured instance goes through `loadData(forKey:)` instead; when
    /// this was the only path, two widgets of the same template could not show
    /// different data.
    private func loadMostRecent<T: Decodable & Timestamped>(prefix: String) -> T? {
        guard let defaults = userDefaults else { return nil }

        let keys = defaults.dictionaryRepresentation().keys.filter { $0.hasPrefix(prefix) }
        var latestData: T?
        var latestTimestamp: Double = 0

        for key in keys {
            if let data = defaults.data(forKey: key),
               let decoded = try? decoder.decode(T.self, from: data),
               decoded.timestamp > latestTimestamp {
                latestData = decoded
                latestTimestamp = decoded.timestamp
            }
        }

        return latestData
    }
}

// MARK: - Timestamped Protocol

protocol Timestamped {
    var timestamp: Double { get }
}

extension SimpleWidgetData: Timestamped {}
extension ProgressWidgetData: Timestamped {}
extension ListWidgetData: Timestamped {}
extension CalendarWidgetData: Timestamped {}
extension ImageWidgetData: Timestamped {}
extension ChartWidgetData: Timestamped {}
extension GaugeWidgetData: Timestamped {}
