## 2.0.0

**Breaking:** the platform interface now models failure as an exception rather
than a boolean.

### Added

* `updateBatch` sends many widget updates in one call, with `GlanceWidgetUpdate`
  carrying each widget's id, data and optional theme override. The batch theme
  travels once rather than once per widget.
* `GlanceWidgetBatchException` and `GlanceWidgetBatchFailure` report the widgets
  a batch could not update, leaving the ones that succeeded applied.

### Changed

* The 15 mutating members return `Future<void>` and throw
  `GlanceWidgetException` on a platform failure. `isWidgetPushSupported` keeps
  `Future<bool>` because it asks a real question.
* `getWidgetPushToken`, `getActiveWidgetIds` and `getBackgroundUpdateStatus`
  throw on a platform failure instead of answering a default that was
  indistinguishable from a real result.

### Fixed

* `ImageWidgetData` accepted a widget with neither `imageUrl` nor `imageBase64`,
  despite documenting that at least one is required, and drew a blank box.
  `validate()` now refuses it.
* `ChartWidgetData` and `GaugeWidgetData` were silently not `const`: a
  `List.length` assert in a `const` constructor is not const-evaluable, so every
  `const ChartWidgetData(...)` was a `const_eval_property_access` error at the
  call site rather than at the constructor. Both are const again.
* A rejected payload was thrown synchronously from an `async` method, so
  `update(...).catchError(...)` never saw it. Rejections now arrive as a failed
  future.

### Added

* `WidgetData.validate()` — checks the invariants that must hold before data
  crosses to the native side, throwing `GlanceWidgetValidationException` naming
  the offending field. Called at the channel boundary, so it runs in release
  builds too; the constructor asserts it complements are stripped there and
  cannot examine a list's length at all.

### Removed

* `MethodChannelGlanceWidget.throwOnError`. Failures always throw; the original
  `PlatformException` is kept on `GlanceWidgetException.originalException`.

# Changelog

## 1.0.0

* **Breaking:** `WidgetData` is now a `sealed class` — all 7 data types extend it
* Added `WidgetData.template` getter for compile-time template identification
* Added `dispose()` to `GlanceWidgetPlatform` and `MethodChannelGlanceWidget`
* Platform instance setter now auto-disposes old instance on swap
* Method channel namespace changed from `com.example.glance_widget` to `dev.glance.widget`

## 0.6.0

* Added 4 new widget data models: `ImageWidgetData`, `ChartWidgetData`, `CalendarWidgetData`, `GaugeWidgetData`
* Added new enums: `ImageFit`, `ChartType`, `GaugeType`
* Added `CalendarEvent` and `GaugeMetric` data classes
* Added `deepLinkUri` field to all widget data classes
* Added `updateImageWidget()`, `updateChartWidget()`, `updateCalendarWidget()`, `updateGaugeWidget()` to platform interface
* Added `configureTimelineRefresh()` and `cancelTimelineRefresh()` for iOS timeline refresh
* Added `completeWidgetConfiguration()` for widget configuration flow
* Added `configure` and `toggle` action types to `GlanceActionType`
* Added `itemId`, `value`, `itemIndex` fields to `GlanceWidgetAction`
* Updated SDK constraints to Dart >=3.6.0, Flutter >=3.27.0

## 0.4.0

* Added `GlanceTemplate` enum for widget template types
* Added `configureBackgroundUpdate()` method for background updates
* Added `cancelBackgroundUpdate()` method
* Added `getBackgroundUpdateStatus()` method

## 0.3.1

* Dependency update for release

## 0.3.0

* Added input validation for widget data (empty titles, progress bounds, maxItems range)
* Improved documentation for all data types

## 0.2.0

* Added `getWidgetPushToken()` method for iOS 26+ Widget Push Updates
* Added `isWidgetPushSupported()` method for runtime platform check
* Prepared platform interface for iOS implementation

## 0.1.0

* Initial release
* Platform interface for Glance widget plugin
* Support for Simple, Progress, and List widget templates
* Theme configuration support
* Widget action event stream
* Custom exception classes for error handling
