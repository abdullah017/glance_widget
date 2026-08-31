## 2.0.0

**Breaking:** matches `glance_widget_platform_interface` 2.0.0. Update methods
return `Future<void>` and throw `GlanceWidgetException` on failure instead of
returning `Future<bool>`. See the main package's
[migration guide](https://pub.dev/packages/glance_widget) for details.

### Fixed

* Method channel handlers replied `success(true)` before knowing whether the
  update had been applied, so a rejected update was reported to Dart as a
  success. Handlers now await the real outcome and answer with an error when the
  platform refused.

# Changelog

## 1.0.0

* Complete all platform method overrides (was 7/18, now 18/18)
* Method channel namespace changed from `com.example.glance_widget` to `dev.glance.widget`
* Added `dispose()` override for resource cleanup
* Updated dependency: `glance_widget_platform_interface: ^1.0.0`

## 0.5.0

* **New Widget Templates** - Calendar, Image, Chart, Gauge
  * `CalendarGlanceWidget` - Date header with event list
  * `ImageGlanceWidget` - Base64 image display with content modes
  * `ChartGlanceWidget` - Canvas-rendered line/bar/sparkline charts
  * `GaugeGlanceWidget` - Radial gauge (Canvas) and dashboard metric cards
* **Deep Link Support** - All widgets support `deepLinkUri` via `actionStartActivity`
* **Lock Screen Widgets** - `widgetCategory="home_screen|keyguard"` for all templates
* **Interactive Actions** - Checkbox toggle support in List Widget
* **Widget Configuration** - `completeWidgetConfiguration` handler
* Updated Compose BOM to 2025.01.01, coroutines to 1.9.0, WorkManager to 2.10.0
* Updated SDK constraints to Dart >=3.6.0, Flutter >=3.27.0
* Updated dependency on glance_widget_platform_interface to ^0.6.0

## 0.3.0

* **Background Updates** - WorkManager integration for updates when app is closed
  * `GlanceWidgetWorker` - CoroutineWorker for API fetching and widget updates
  * `BackgroundUpdateManager` - WorkManager scheduling and cancellation
  * `BackgroundUpdateConfig` - Configuration storage with SharedPreferences
* New method handlers in `GlanceWidgetPlugin`:
  * `configureBackgroundUpdate`
  * `cancelBackgroundUpdate`
  * `getBackgroundUpdateStatus`
* Added WorkManager dependency (`androidx.work:work-runtime-ktx:2.9.0`)
* Updated dependency on glance_widget_platform_interface to ^0.4.0

## 0.2.1

* **JSON Serialization** - Fixed list widget item parsing using proper JSON instead of delimiter-based parsing
* **Error Handling** - Added `UpdateResult` sealed class for structured error reporting
* **Backward Compatibility** - Legacy delimiter parsing preserved for existing widget data
* **Glance 1.1.1 Compatibility** - Fixed ColorProvider API for Compose Color
* **Compose BOM** - Added Compose BOM 2024.12.01 dependency for runtime compatibility
* **CircularProgressIndicator** - Changed to percentage display (Glance only supports indeterminate mode)
* **isWidgetPushSupported** - Added method stub (returns false, iOS-only feature)
* **compileSdk** - Updated to API 36
* Updated dependency on glance_widget_platform_interface to ^0.3.0

## 0.1.1

* Updated dependency on glance_widget_platform_interface to ^0.2.0
* Compatible with iOS implementation release

## 0.1.0

* Initial release
* Android implementation using Jetpack Glance
* Three widget templates: Simple, Progress, List
* Instant widget updates (< 1 second)
* Theme support with dark/light modes
* Widget action callbacks to Flutter
* JSON serialization for list items
* Proper coroutine lifecycle management
* ProGuard/R8 rules included
