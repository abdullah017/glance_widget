# Changelog

## 1.0.0

* Complete all platform method overrides (was 9/18, now 18/18)
* Method channel namespace changed from `com.example.glance_widget` to `dev.glance.widget`
* Added `dispose()` override for resource cleanup
* Updated dependency: `glance_widget_platform_interface: ^1.0.0`

## 0.5.0

* **New Widget Templates** - Calendar, Image, Chart, Gauge
  * `CalendarWidget` - Date header with event list and colored dot indicators
  * `ImageWidget` - Base64 image decoding with UIImage, content mode support
  * `ChartWidget` - SwiftUI Path + GeometryReader for line/bar/sparkline charts
  * `GaugeWidget` - Path.addArc() for radial, LazyVGrid for dashboard metrics
* **Deep Link Support** - All widgets support `deepLinkUri` via `.widgetURL()`
* **Timeline Refresh** - Configurable `.after(date)` policy for periodic widget refresh
  * `configureTimelineRefresh()` / `cancelTimelineRefresh()` methods
* **Interactive Actions** - Item tap and checkbox toggle URLs in List Widget
* **Widget Configuration** - `completeWidgetConfiguration` handler
* Updated SDK constraints to Dart >=3.6.0, Flutter >=3.27.0
* Updated dependency on glance_widget_platform_interface to ^0.6.0

## 0.3.0

* Updated dependency on glance_widget_platform_interface to ^0.4.0
* Background update methods return stub responses (iOS uses Push Updates instead)

## 0.2.1

* Updated dependency on glance_widget_platform_interface to ^0.3.1

## 0.2.0

* **Error Handling** - Added `GlanceResult` enum for structured error reporting
* **App Group Validation** - Added `isAvailable` check and improved error messages
* **Save Feedback** - `save()` methods now return Bool indicating success/failure
* Updated dependency on glance_widget_platform_interface to ^0.3.0

## 0.1.0

* Initial release
* iOS implementation using WidgetKit
* Three widget templates: Simple, Progress, List
* Instant widget updates when app is in foreground (no budget limit)
* Theme support with dark/light modes
* Widget tap actions sent back to Flutter via URL schemes
* App Group storage for Flutter-Widget data sharing
* Widget Push Updates support (iOS 26+)
* Privacy manifest included (UserDefaults usage)
* Minimum iOS version: 16.0
