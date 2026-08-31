# Glance Widget Example

A complete demo app showing all widget types on Android and iOS.

## Running the Example

```bash
cd example
flutter run
```

## Features Demonstrated

- **Simple Widget** - Bitcoin price tracker with dynamic updates
- **Progress Widget** - Download progress with circular indicator
- **List Widget** - Todo list with checkboxes
- **Theme Support** - Dark theme configuration
- **Widget Actions** - Tap handling from widgets

## Platform Setup

### Android

Android widgets work out of the box. The example app includes:
- Widget receiver configurations in `AndroidManifest.xml`
- Widget info XML files in `res/xml/`
- Preview layouts in `res/layout/`

### iOS

For iOS, you need to add a Widget Extension to your Xcode project:

1. Open `ios/Runner.xcworkspace` in Xcode
2. File → New → Target → Widget Extension
3. Name it `GlanceWidgets`
4. Configure App Groups for both targets
5. Copy widget files from `glance_widget_ios/example/ios/GlanceWidgets/`

See [iOS Widget Setup Guide](../glance_widget_ios/example/ios/WIDGET_SETUP.md) for detailed instructions.

## Adding Widgets to Home Screen

### Android
1. Long press on home screen
2. Select "Widgets"
3. Find your app and drag a widget type to home

### iOS
1. Long press on home screen
2. Tap "+" in top left corner
3. Search for your app name
4. Select widget size and tap "Add Widget"
