## 2.0.0

**Breaking:** matches `glance_widget_platform_interface` 2.0.0. Update methods
return `Future<void>` and throw `GlanceWidgetException` on failure instead of
returning `Future<bool>`. See the main package's
[migration guide](https://pub.dev/packages/glance_widget) for details.

### Added

* `updateBatch` applies many widget updates, of any mix of templates, from one
  method call. Entries are applied in order and every one is attempted; the
  reply carries a `failures` list naming the widgets that could not be updated,
  which Dart turns into a `GlanceWidgetBatchException`. A template this build
  does not know is that one widget's failure rather than the batch's, so a
  newer Dart side talking to an older plugin still gets its other widgets
  updated.

### Fixed

* Method channel handlers replied `success(true)` before knowing whether the
  update had been applied, so a rejected update was reported to Dart as a
  success. Handlers now await the real outcome and answer with an error when the
  platform refused.
* Two widgets built from the same template could not hold different data. Every
  update was written into every placed instance of that template, so updating
  `'btc'` also overwrote a widget showing `'eth'`. Updates are now routed to the
  instance carrying the target `widgetId`, which is what the documented "unique
  identifier for this widget instance" always implied. A freshly placed instance
  is claimed by the first update that finds no other home, a lone instance is
  re-keyed rather than left unreachable, and an id that matches nothing among
  several placed widgets is refused with `NO_WIDGET_INSTANCE` instead of
  overwriting one at random.

* `imageUrl` did nothing. It is documented, validated and sent over the channel,
  and no native code read it -- the widget drew a blank box with no error and no
  log. Image sources are now resolved when the update is applied, not when the
  widget is drawn: a Glance composition runs in the host's process on the host's
  schedule and is no place for network I/O.
* The image fit setting never applied. Dart sends `fit`; this read
  `data["imageFit"]`, which was always null.
* Images were decoded inside the `@Composable` body, so the same picture was
  decoded again on every recomposition. Decoding now happens once at update
  time, and the result is held in a bounded cache.
* Images were decoded at full resolution. A 4000x3000 photo is roughly 48 MB of
  ARGB_8888, over the limit for handing to a widget host, and the resulting
  `OutOfMemoryError` is an `Error` rather than an `Exception` -- so the
  `catch (e: Exception)` around the decode never caught it and the host process
  died. Images are now downsampled to fit a 512 px budget before decoding, with
  the error caught as a backstop.

* A widget that stopped having an image kept its downsampled file on disk
  forever. The `imagePath` preference was removed, which is what makes the
  widget stop drawing the old picture, but nothing deleted the file it pointed
  at and nothing could reach it afterwards. `ImageStore.evict` existed for this
  and was never called from anywhere. Dropping the file is now the store's own
  job rather than the caller's, so it cannot be forgotten again.

* Every `catch (e: Exception)` in the widget manager swallowed
  `CancellationException`, which is an `Exception` in Kotlin. A cancelled
  coroutine was reported to Dart as a rejected update, and structured
  concurrency broke for callers upstream. Cancellation is now rethrown at all
  15 sites.

### Security

* Only `http` and `https` image URLs are fetched. A widget update carries an
  app-supplied string into a network stack, and `file://` or `content://` would
  have made that a way to read arbitrary local data. Downloads are also capped
  at 16 MB and time out.
* Redirects are followed by hand, at most five deep, with every hop put back
  through the same scheme check. `HttpURLConnection.instanceFollowRedirects`
  would have applied that check to the first hop only, so a permitted `https://`
  address could have handed the fetch on to something else.

Private and loopback addresses are deliberately not blocked: the app already
holds the `INTERNET` permission and could make the same request itself, so
refusing them would buy little and would break serving widget images from a LAN
host or a local dev server. Apps that put third-party URLs into `imageUrl`
should validate them as they would any other URL they fetch.

### Added

* JVM unit tests for the plugin's Android sources, run in CI. The instance
  routing rules live in `WidgetInstanceResolver`, deliberately free of Android
  types so they can be tested without an emulator.

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
