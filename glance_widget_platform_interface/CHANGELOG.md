# Changelog

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
