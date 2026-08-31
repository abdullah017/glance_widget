## 2.0.0

**Breaking:** matches `glance_widget_platform_interface` 2.0.0. Update methods
return `Future<void>` and throw `GlanceWidgetException` on failure instead of
returning `Future<bool>`. See the main package's
[migration guide](https://pub.dev/packages/glance_widget) for details.

**Breaking:** the minimum deployment target is now iOS 17, up from iOS 16.
`AppIntentConfiguration` is the only widget configuration that carries a
per-instance parameter, and so the only way a placed widget can know which
`widgetId` it renders -- see the fix below. It requires iOS 17.

**Breaking:** the widget templates use `AppIntentConfiguration` instead of
`StaticConfiguration`, and their timeline providers are
`AppIntentTimelineProvider`. If you copied the templates and edited them, take
the new versions: the change is mechanical, and a `StaticConfiguration` widget
cannot be pointed at a `widgetId`.

### Fixed

* Every placed instance of a template rendered the same data. `widgetId` was
  honoured when writing and ignored when reading: each widget called
  `load...Widget()` with no id and fell through to "whichever payload was
  written last", so two `SimpleWidget`s could not show `'btc'` and `'eth'`.
  This was the mirror image of the Android defect fixed in 2.0.0, where the
  write path clobbered instead. Widgets now take a `widgetId` from their
  configuration, and the person placing the widget picks it from the ids the app
  has actually sent data for. An unconfigured instance keeps the old
  most-recent behaviour so a freshly placed widget is never blank.
* `imageUrl` did nothing. It is documented, validated in Dart and sent over the
  channel, and no iOS code read it -- the widget drew a placeholder saying
  "Remote images limited in widgets". Image sources are now resolved when the
  update is applied: fetched, downsampled through `CGImageSourceCreateThumbnail`
  and written into the App Group container, so the extension only ever does a
  small file read. A widget extension runs under a far tighter memory budget
  than the app, and WidgetKit will not wait for a network round trip during a
  timeline reload.
* Images were carried through App Group `UserDefaults` as base64. The bytes now
  live in a file, so every widget reload no longer has to read them back.
* Documented the iOS floor as something to set in Xcode *or* the `Podfile`.
  Neither on its own is the whole story. The Xcode target
  (`IPHONEOS_DEPLOYMENT_TARGET`) is the value that counts, and it reaches
  `FlutterGeneratedPluginSwiftPackage` only when `flutter build ios` runs;
  `flutter pub get` rewrites that manifest at Flutter's own 15.0 default
  whatever both the Xcode target and the `Podfile` say. The example app hit
  exactly that.

### Changed

* `updateImageWidgetWithResult` is asynchronous and takes a completion handler.
  Resolving `imageUrl` needs the network, so the outcome cannot be known
  synchronously. The plugin hops the reply back to the main thread.

### Security

* Only `http` and `https` image URLs are fetched, and redirects are followed by
  hand, at most five deep, with every hop put back through the same check.
  `URLSession` would have applied it to the first hop only. Downloads are capped
  at 16 MB and time out.

### Changed

* Dropping the cached image file when a widget stops having a picture moved from
  the caller into `GlanceImageStore`, which owns those files. The behaviour is
  unchanged here; Android had the same code with the call missing, so the rule
  now lives where it cannot be forgotten on either platform.
* The seven App Group key prefixes were private string literals in
  `GlanceWidgetManager`, typed out again by hand in the widget templates. They
  now live in `GlanceStorageKeys`, which the plugin uses and the tests pin to
  their exact values -- a rename used to fail nothing at all, leaving the
  configuration picker empty and every configured widget blank.

### Added

* Swift unit tests, run in CI on a simulator through the example app's XCTest
  target, and a `swiftc -typecheck` gate for the widget extension templates --
  nothing in the repository compiled those before, which is how the image `fit`
  key silently drifted apart from what Dart sends.
* Method channel handlers replied `success(true)` before knowing whether the
  update had been applied, so a rejected update was reported to Dart as a
  success. Handlers now await the real outcome and answer with an error when the
  platform refused.

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
