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

    // MARK: - Global Theme

    func loadGlobalTheme() -> WidgetThemeData? {
        return loadData(forKey: "globalTheme")
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
