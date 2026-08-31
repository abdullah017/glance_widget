## 2.0.0

**Breaking:** widget updates now report failures instead of hiding them. See
[doc/migration_v2.md](doc/migration_v2.md) for the full migration.

**Breaking:** iOS now requires a deployment target of 17.0, up from 16.0. The
iOS widget templates need `AppIntentConfiguration`, which is the only widget
configuration carrying a per-instance parameter and therefore the only way a
placed widget can know which `widgetId` it shows.

### Added

* `GlanceWidget.batch` updates many widgets, of any mix of templates, in a
  single platform call. The per-template helpers each cross the method channel
  once, so refreshing a dashboard of twenty widgets cost twenty round trips and
  serialised the shared theme twenty times over. Measured on the same twenty
  updates: `roundTrips=20 payloadBytes=5700` became
  `roundTrips=1 payloadBytes=2974`.

  Every update is attempted rather than stopping at the first failure -- one
  widget missing from the home screen is no reason to leave the other nineteen
  showing stale data. The ones that succeeded stay applied and a
  `GlanceWidgetBatchException` names the rest, one `GlanceWidgetBatchFailure`
  per widget. A malformed update is refused before anything is sent, so a
  mistake in the calling code cannot half-apply.

### Fixed

* `widgetId` did not actually identify an instance on either platform. On
  Android every update was written into every placed widget of that template,
  so updating `'btc'` overwrote a widget showing `'eth'`. On iOS the mirror
  image: writes were per id, reads were not, so every placed widget rendered
  whichever id was updated last. Android now routes each update to the instance
  holding the id; on iOS the person placing the widget picks the id from the
  ones the app has sent data for (long-press → Edit Widget).
* `imageUrl` was documented, validated and sent over the channel, and no native
  code on either platform read it. Images are now fetched and downsampled when
  the update is applied rather than when the widget is drawn — a widget host
  composes on its own schedule and under a much tighter memory budget, and a
  full-resolution photo was enough to kill the process on Android.
* A failed widget update was reported as a success. The native plugins answer a
  failed update with a platform error, never with `false`, so the `Future<bool>`
  every method returned was `true` on success and `true` again for any caller
  who did not inspect it after the Dart layer had swallowed the error.
  `DebouncedWidgetController` counted those failures as completed updates, so
  `updateCount`, `timeSinceLastUpdate` and `isStale` all lied.
* `DebouncedWidgetController` failures triggered by the debounce timer, the max
  wait timer, or the app going to the background reached nobody at all.
* Concurrent debounced dispatches could land out of order; they are now
  serialised.
* `GlanceWidgetController` bypassed the platform guard, so `update`, `setTheme`
  and `onAction` threw `MissingPluginException` on Web and desktop instead of
  no-opping like the rest of the API.
* `GlanceConfig.strictMode = true` rejected valid JSONPath expressions such as
  `$..author` and `$.book[?(@.price < 10)]`, which the native parser accepts.
* `ChartWidgetData` and `GaugeWidgetData` could not be `const`: a `List.length`
  assert in a `const` constructor is not const-evaluable, and the resulting
  error pointed at the call site rather than the constructor. Both are const
  again, and the emptiness check moved to `WidgetData.validate()` at the channel
  boundary, where it also runs in release builds.

### Changed

* All update, theme, configuration and background methods return `Future<void>`
  and throw `GlanceWidgetException` — carrying the platform's `code`, `message`
  and the original `PlatformException` — instead of returning `Future<bool>`.
* `getWidgetPushToken`, `getActiveWidgetIds` and `getBackgroundUpdateStatus`
  throw on a platform failure rather than answering `null`, `[]` or
  `{isConfigured: false}`. `isWidgetPushSupported` still returns `bool`: it asks
  a real question about the platform.
* Unsupported platforms are always a silent no-op, never an exception.
  `GlanceWidget.onAction` yields an empty stream there.
* JSONPath validation rejects only what no parser accepts (empty, or not
  starting with `$`); unrecognised expressions are logged and passed through.

### Added

* `GlanceWidget.isSupported` — ask whether the platform has home screen widgets
  instead of configuring what failure should look like.
* `DebouncedWidgetController.errors`, `.failedCount` and `.lastError`.

### Removed

* `MethodChannelGlanceWidget.throwOnError` — failures always throw.
* `GlanceConfig.strictMode` — it conflated platform support with JSONPath
  strictness; both are now explicit.

## 1.0.1

* Updated sub-package dependencies to v1.0.0 (platform_interface, android, ios)

## 1.0.0

### Breaking Changes
- `WidgetData` is now a `sealed class` — all 7 data types extend it with `template` getter
- `GlanceWidgetController` is now generic: `GlanceWidgetController<T extends WidgetData>`
- Old controller methods (`updateSimple()`, `updateProgress()`, etc.) replaced by single type-safe `update(T data)`
- `DebouncedWidgetController` is now generic: `DebouncedWidgetController<T extends WidgetData>`
- Background update methods moved from `GlanceWidget` to `GlanceBackground` class
- Method channel namespace changed from `com.example.glance_widget` to `dev.glance.widget`

### New Features
- Compile-time type safety via generic controllers — wrong data type is a compilation error
- 7 convenience controllers: `SimpleWidgetController`, `ProgressWidgetController`, `ListWidgetController`, `ImageWidgetController`, `ChartWidgetController`, `CalendarWidgetController`, `GaugeWidgetController`
- `GlanceConfig.strictMode` for configurable platform safety
- `PlatformGuard` for graceful behavior on unsupported platforms (Web, macOS, Windows, Linux)
- `JsonPathValidator` for background update JSONPath validation
- `AppLifecycleListener` integration in `DebouncedWidgetController` — flushes pending data on app background
- Configurable `stalenessThreshold` in `DebouncedWidgetController`
- Platform interface `dispose()` for resource cleanup on platform swap
- Exhaustive `switch` on `WidgetData` — compiler warns when new widget type added

### Fixes
- Constructor side-effects removed from controllers (lazy initialization)
- Stream multiplexing: single native EventChannel subscription regardless of controller count
- Resource cleanup on platform swap (no more stream leaks)
- Complete Android/iOS platform method overrides (was 7/18 and 9/18, now 18/18)
- `skippedCount` in `DebouncedWidgetController` now correctly only counts replaced pending updates

### Migration Guide
```dart
// BEFORE (v0.7.0)
final ctrl = GlanceWidgetController(widgetId: 'btc', template: GlanceTemplate.simple);
await ctrl.updateSimple(SimpleWidgetData(title: 'BTC', value: '\$94k'));

// AFTER (v1.0.0)
final ctrl = SimpleWidgetController(widgetId: 'btc');
await ctrl.update(SimpleWidgetData(title: 'BTC', value: '\$94k'));

// BEFORE
await GlanceWidget.configureBackgroundUpdate(widgetId: 'crypto', ...);

// AFTER
await GlanceBackground.configureUpdate(widgetId: 'crypto', ...);
```

## 0.7.0

### New Widget Templates
* **Image Widget** - Display photos with title and subtitle (base64 + URL support)
* **Chart Widget** - Line, bar, and sparkline chart visualization
* **Calendar Widget** - Date header with event list and colored indicators
* **Gauge Widget** - Radial and dashboard metric displays

### Platform Features
* **Deep Link Support** - All 7 widget templates support custom deep link URIs
* **Android Lock Screen Widgets** - All widgets now support `keyguard` category for lock screen placement
* **iOS Timeline Refresh** - Configurable `.after(date)` timeline policy for periodic widget refresh
  * `configureTimelineRefresh()` / `cancelTimelineRefresh()` API
* **Interactive Widget Actions** - Checkbox toggle and item tap actions for List Widget
  * New action types: `toggle`, `checkboxToggle`, `itemTap`, `configure`
  * New action fields: `itemId`, `value`, `itemIndex`
* **Widget Configuration** - `completeWidgetConfiguration()` for handling widget setup flow

### SDK Updates
* Flutter 3.27+ / Dart 3.6+ minimum SDK requirement
* Compose BOM 2025.01.01, kotlinx-coroutines 1.9.0, WorkManager 2.10.0
* Updated `GlanceTemplate` enum with 4 new values: `image`, `chart`, `calendar`, `gauge`

### Testing
* 167 unit tests (from 131) covering all new templates and features
* 40 platform interface tests

## 0.4.0

### Background Updates (Android)
* **WorkManager Integration** - Widget updates even when app is closed
  * Periodic background updates with configurable interval (minimum 15 minutes)
  * API fetching with custom headers support
  * JSONPath-like expressions for value extraction
  * Network-aware scheduling (only updates when connected)
* New API methods:
  * `configureBackgroundUpdate()` - Set up automatic updates from an API
  * `cancelBackgroundUpdate()` - Stop background updates for a widget
  * `getBackgroundUpdateStatus()` - Check update configuration and state

### New Types
* **GlanceTemplate** enum - Widget template types (simple, progress, list)

### Usage Example
```dart
await GlanceWidget.configureBackgroundUpdate(
  widgetId: 'crypto_btc',
  template: GlanceTemplate.simple,
  apiUrl: 'https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=usd',
  interval: Duration(minutes: 15),
  title: 'Bitcoin',
  valuePath: r'$.bitcoin.usd',
  valuePrefix: r'$',
);
```

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
