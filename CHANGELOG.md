## 0.3.1

### Stability & Quality
* **JSON Serialization** - Fixed list widget item parsing using proper JSON instead of delimiter-based parsing (`|||`, `::`)
* **Error Handling** - Added structured error types for both Android (`UpdateResult`) and iOS (`GlanceResult`)
* **Input Validation** - Added assert-based validation for widget data (empty titles, progress bounds, maxItems range)
* **Backward Compatibility** - Legacy delimiter parsing preserved for existing widget data

### Android Compatibility (Glance 1.1.1)
* **Compose BOM** - Added Compose BOM 2024.12.01 for runtime compatibility
* **ColorProvider API** - Fixed for Compose Color type
* **CircularProgressIndicator** - Changed to percentage display (Glance only supports indeterminate mode)
* **compileSdk** - Updated to API 36

### Real-time Data Optimization
* **DebouncedWidgetController** - New controller for high-frequency updates (crypto, stocks, live scores)
  * Configurable `debounceInterval` and `maxWaitTime`
  * Automatic coalescing of rapid updates
  * Update statistics tracking (`updateCount`, `skippedCount`)
  * Staleness detection (`isStale`, `timeSinceLastUpdate`)

### Developer Experience
* Improved error messages for App Group configuration issues on iOS
* Better logging for widget update failures
* Documentation improvements

## 0.2.0

* **iOS Support** - Added WidgetKit implementation for iOS 16+
* Instant updates when app is in foreground (no budget limit!)
* Widget Push Updates support for iOS 26+ (server-triggered updates via APNs)
* Added `getWidgetPushToken()` for server-side widget updates
* Added `isWidgetPushSupported()` for runtime platform check
* Privacy manifest included for App Store compliance
* Updated description to reflect cross-platform support

## 0.1.0

* Initial release
* **SimpleWidget** - Title + Value + Subtitle template for prices, stats, metrics
* **ProgressWidget** - Circular and linear progress indicators
* **ListWidget** - Scrollable list with optional checkboxes
* Theme support (light/dark) with full customization
* Widget tap action handling via streams
* Instant updates (< 1 second) using Jetpack Glance
* Controller API for advanced widget management
