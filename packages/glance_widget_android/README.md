# glance_widget_android

The Android implementation of [`glance_widget`](https://github.com/abdullahtas0/glance_widget).

## Usage

This package is [endorsed](https://flutter.dev/docs/development/packages-and-plugins/developing-packages#endorsed-federated-plugin), which means you can simply use `glance_widget` normally. This package will be automatically included in your app when you do, so you do not need to add it to your `pubspec.yaml`.

However, if you `import` this package to use any of its APIs directly, you should add it to your `pubspec.yaml` as usual.

## Requirements

- Android SDK 26+ (Android 8.0 Oreo) — set `minSdk = 26` in your app's `build.gradle.kts`
- Kotlin 2.0+

You do **not** need to enable Jetpack Compose in your app. This package renders
its widgets with Compose, so it supplies its own Compose compiler and applies it
only to itself.

The Compose compiler has to match the Kotlin version your app resolved, so the
package reads that version from the build and follows it. If your setup needs a
different one, override it in `android/gradle.properties`:

```properties
glance.kotlinVersion=2.2.20
```

## Implementation Details

This package uses:
- **Jetpack Glance** for widget rendering with Compose-based UI
- **DataStore Preferences** for widget state management
- **Gson** for JSON serialization
- **Kotlin Coroutines** for asynchronous operations
- **WorkManager** for background widget updates

## Widget Templates

Seven widget templates are provided:
- `SimpleGlanceWidget` — title, value and subtitle
- `ProgressGlanceWidget` — circular or linear progress indicators
- `ListGlanceWidget` — scrollable list with optional checkboxes
- `CalendarGlanceWidget` — upcoming events
- `ImageGlanceWidget` — image with optional caption
- `ChartGlanceWidget` — bar and line charts
- `GaugeGlanceWidget` — gauge with thresholds
