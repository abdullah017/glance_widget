## 2.0.0

**Added:** `GlanceTheme.useDynamicColor` paints the widget from the wallpaper
palette on Android 12 and above. Off by default.

Below API 31 the request is ignored and the theme's own colours are used. That
is deliberate: Glance's `DynamicThemeColorProviders` resolves through resources
whose `values-v31` variant points at `@android:color/system_accent1_*` and
whose plain `values` variant is the static Material baseline, so passing them
straight through would not degrade to the app's colours on Android 8-11 -- it
would silently repaint the widget purple.

**Changed:** the four theme colours are now resolved once, in `widgetColors`,
instead of once per template. The same block appeared in all seven, and the
built-in defaults had drifted between them.

**Fixed:** widget taps could be lost. Every template handled its taps with a
Glance lambda action, which runs in the app's own process -- and the system is
free to start that process from cold just to deliver the tap, with no Flutter
engine in it. The event went to a null listener and vanished, with nothing in
the logs. Taps are now handled by `ActionCallback`s that write to a queue on
disk first, so the Dart handler no longer has to be alive at the moment of the
tap; the backlog is capped at 100 and replays with the time the tap actually
happened.

**Added:** checkboxes in `ListWidget` toggle in place, via
`actionRunCallback<ToggleListItemAction>`. Ticking one no longer launches the
app. The stored state is flipped before the event is queued, so the box does
not spring back when the widget next redraws.

**Fixed:** `BackgroundUpdateConfig` was saved to `SharedPreferences` as Gson
JSON with no ProGuard rule protecting its field names. In a minified build R8
renamed them to `a`, `b`, `c` -- and the letters are not stable across builds,
so an app update made every previously saved config unreadable. `load()`
swallows the parse failure and returns `null`, so the symptom was background
updates silently stopping after an update, release builds only.
`consumer-rules.pro` now keeps the field names of both serialized models, and
CI builds a minified APK and asserts against the R8 mapping file that they
survived.

**Fixed:** `GlanceTheme.borderRadius` had no effect. Three of the seven
templates read the value into a local and never used it; the other four did not
read it at all, so every Android widget had square corners whatever the theme
said, while iOS rounded exactly as asked (#20). All seven now round by it.

Two notes on the fix. The radius is no longer put through `Int` on the way --
`?.toInt() ?: 16` floored a 12.5dp radius to 12dp before discarding it. And
Glance's `cornerRadius(Dp)` is honoured on **Android 12 (API 31) and above**;
below that the platform offers no way to round a widget by a value chosen at
runtime, so those devices keep square corners. That is a platform limit, not a
default -- it is stated here rather than left to be discovered.

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

* Gauge widgets ignored the metrics they were given. The radial gauge read
  `progress`, `value`, `gaugeColor`, `minLabel` and `maxLabel` off the payload,
  none of which `GaugeWidgetData` has ever sent, so every gauge drew an empty
  arc reading `0%`; the dashboard gauge forwarded metrics untouched, but the
  template reads `value` as text and needs a `progress` fraction, so every card
  showed a blank value and no bar. Both shapes are now derived from the metrics,
  matching what the iOS templates draw.

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
