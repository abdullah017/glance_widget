# glance_widget_android

The Android implementation of [`glance_widget`](https://github.com/abdullah017/glance_widget).

## Usage

This package is [endorsed](https://flutter.dev/docs/development/packages-and-plugins/developing-packages#endorsed-federated-plugin), which means you can simply use `glance_widget` normally. This package will be automatically included in your app when you do, so you do not need to add it to your `pubspec.yaml`.

However, if you `import` this package to use any of its APIs directly, you should add it to your `pubspec.yaml` as usual.

## Requirements

- Android SDK 26+ (Android 8.0 Oreo)
- Kotlin 2.0+
- Jetpack Compose enabled

## Implementation Details

This package uses:
- **Jetpack Glance** for widget rendering with Compose-based UI
- **DataStore Preferences** for widget state management
- **Gson** for JSON serialization
- **Kotlin Coroutines** for asynchronous operations

## Widget Templates

Three widget templates are provided:
- `SimpleGlanceWidget` - Title + Value + Subtitle display
- `ProgressGlanceWidget` - Circular or linear progress indicators
- `ListGlanceWidget` - Scrollable list with optional checkboxes
