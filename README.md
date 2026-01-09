# glance_widget

[![pub package](https://img.shields.io/pub/v/glance_widget.svg)](https://pub.dev/packages/glance_widget)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Create instant-updating home screen widgets for **Android** and **iOS**. Built with Jetpack Glance (Android) and WidgetKit (iOS).

## Features

- **Instant Updates** - Widgets update in < 1 second on both platforms
- **Cross-Platform** - Same API for Android and iOS
- **3 Widget Templates** - Simple, Progress, and List widgets ready to use
- **Theme Support** - Light/Dark themes with full customization
- **Tap Actions** - Handle widget taps and interactions
- **iOS 26+ Push Updates** - Server-triggered widget updates via APNs

## Platform Comparison

| Feature | Android (Jetpack Glance) | iOS (WidgetKit) |
|---------|--------------------------|-----------------|
| Update Speed | < 1 second | < 1 second (app foreground) |
| Background Updates | Instant | Timeline-based |
| Server Push | N/A | iOS 26+ (APNs) |
| Min Version | Android 8.0 (API 26) | iOS 16.0 |

## Widget Templates

| Template | Description | Use Cases |
|----------|-------------|-----------|
| **SimpleWidget** | Title + Value + Subtitle | Crypto prices, weather, stats |
| **ProgressWidget** | Circular/Linear progress | Downloads, goals, battery |
| **ListWidget** | Scrollable item list | To-do, shopping, activities |

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  glance_widget: ^0.2.0
```

---

## Android Setup

### 1. Configure Manifest

Add widget receivers to `android/app/src/main/AndroidManifest.xml`:

```xml
<application>
    <!-- Simple Widget -->
    <receiver
        android:name="com.example.glance_widget_android.templates.SimpleWidgetReceiver"
        android:exported="true">
        <intent-filter>
            <action android:name="android.appwidget.action.APPWIDGET_UPDATE" />
        </intent-filter>
        <meta-data
            android:name="android.appwidget.provider"
            android:resource="@xml/simple_widget_info" />
    </receiver>

    <!-- Progress Widget -->
    <receiver
        android:name="com.example.glance_widget_android.templates.ProgressWidgetReceiver"
        android:exported="true">
        <intent-filter>
            <action android:name="android.appwidget.action.APPWIDGET_UPDATE" />
        </intent-filter>
        <meta-data
            android:name="android.appwidget.provider"
            android:resource="@xml/progress_widget_info" />
    </receiver>

    <!-- List Widget -->
    <receiver
        android:name="com.example.glance_widget_android.templates.ListWidgetReceiver"
        android:exported="true">
        <intent-filter>
            <action android:name="android.appwidget.action.APPWIDGET_UPDATE" />
        </intent-filter>
        <meta-data
            android:name="android.appwidget.provider"
            android:resource="@xml/list_widget_info" />
    </receiver>
</application>
```

### 2. Create Widget Info XML

Create `android/app/src/main/res/xml/simple_widget_info.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<appwidget-provider xmlns:android="http://schemas.android.com/apk/res/android"
    android:minWidth="180dp"
    android:minHeight="110dp"
    android:targetCellWidth="3"
    android:targetCellHeight="2"
    android:resizeMode="horizontal|vertical"
    android:widgetCategory="home_screen"
    android:updatePeriodMillis="0" />
```

### 3. Set SDK Versions

In `android/app/build.gradle.kts`:

```kotlin
android {
    compileSdk = 35
    defaultConfig {
        minSdk = 26
    }
}
```

---

## iOS Setup

### 1. Create Widget Extension

In Xcode:
1. Open `ios/Runner.xcworkspace`
2. File → New → Target → Widget Extension
3. Name: `GlanceWidgets`
4. Click Finish

### 2. Configure App Groups

Both targets need the same App Group:

1. Select `Runner` target → Signing & Capabilities → + App Groups
2. Add: `group.com.yourcompany.yourapp`
3. Select `GlanceWidgets` target → repeat with same App Group ID

### 3. Add Widget Files

Copy files from `glance_widget_ios/example/ios/GlanceWidgets/` to your extension:
- `GlanceWidgets.swift`
- `SharedModels.swift` (update `appGroupId`!)
- `SimpleWidget.swift`
- `ProgressWidget.swift`
- `ListWidget.swift`

### 4. Configure URL Scheme

Add to `ios/Runner/Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>glancewidget</string>
        </array>
    </dict>
</array>
```

See [iOS Widget Setup Guide](glance_widget_ios/example/ios/WIDGET_SETUP.md) for detailed instructions.

---

## Usage

### Simple Widget

Display single values like crypto prices:

```dart
import 'package:glance_widget/glance_widget.dart';

await GlanceWidget.simple(
  id: 'crypto_btc',
  title: 'Bitcoin',
  value: '\$94,532.00',
  subtitle: '+2.34%',
  subtitleColor: Colors.green,
);
```

### Progress Widget

Show downloads, goals, or completion status:

```dart
await GlanceWidget.progress(
  id: 'daily_goal',
  title: 'Steps Today',
  progress: 0.75,  // 0.0 to 1.0
  subtitle: '7,500 / 10,000',
  progressType: ProgressType.circular,
  progressColor: Colors.green,
);
```

### List Widget

Display lists with optional checkboxes:

```dart
await GlanceWidget.list(
  id: 'todo_list',
  title: 'Today\'s Tasks',
  items: [
    GlanceListItem(text: 'Buy groceries', checked: true),
    GlanceListItem(text: 'Call mom', checked: false),
    GlanceListItem(text: 'Finish report', checked: false),
  ],
  showCheckboxes: true,
);
```

### Theme Configuration

```dart
// Dark theme
await GlanceWidget.setTheme(GlanceTheme.dark());

// Light theme
await GlanceWidget.setTheme(GlanceTheme.light());

// Custom theme
await GlanceWidget.setTheme(GlanceTheme(
  backgroundColor: Color(0xFF1A1A2E),
  textColor: Colors.white,
  secondaryTextColor: Color(0xFFB0B0B0),
  accentColor: Colors.orange,
  borderRadius: 16.0,
  isDark: true,
));
```

### Handle Widget Taps

```dart
GlanceWidget.onAction.listen((action) {
  switch (action.type) {
    case GlanceActionType.tap:
      print('Widget ${action.widgetId} tapped');
      break;
    case GlanceActionType.itemTap:
      final index = action.payload?['index'];
      print('Item $index tapped');
      break;
  }
});
```

### Force Refresh All Widgets

```dart
// Instant update on both platforms
// On iOS: No budget limit when app is in foreground!
await GlanceWidget.forceRefreshAll();
```

### iOS 26+ Server Push Updates

For server-triggered widget updates on iOS 26+:

```dart
// Check if supported
if (await GlanceWidget.isWidgetPushSupported()) {
  // Get push token
  final token = await GlanceWidget.getWidgetPushToken();
  if (token != null) {
    // Send to your server
    await api.registerWidgetPushToken(token);
  }
}
```

Server-side APNs request:
```http
POST https://api.push.apple.com/3/device/{token}
Headers:
  apns-push-type: widgets
  apns-topic: com.yourcompany.yourapp.push-type.widgets
Body:
  {"aps": {"content-changed": true}}
```

---

## Controller API (Advanced)

For more control over individual widgets:

```dart
final controller = GlanceWidgetController(
  widgetId: 'my_widget',
  template: GlanceTemplate.simple,
  theme: GlanceTheme.dark(),
);

// Update
await controller.updateSimple(SimpleWidgetData(
  title: 'Bitcoin',
  value: '\$94,532',
  subtitle: '+2.34%',
));

// Listen to actions for this widget
controller.onAction.listen((action) {
  // Handle action
});

// Dispose when done
controller.dispose();
```

---

## Requirements

| Platform | Minimum Version |
|----------|-----------------|
| Flutter | 3.10+ |
| Android | API 26 (Android 8.0) |
| iOS | 16.0 |

---

## Example

Check the [example](example/) directory for a complete demo app showing all widget types on both platforms.

```bash
cd example
flutter run
```

---

## Architecture

This package uses a federated plugin architecture:

| Package | Description |
|---------|-------------|
| `glance_widget` | Main package with cross-platform API |
| `glance_widget_platform_interface` | Platform-independent interface |
| `glance_widget_android` | Android implementation (Jetpack Glance) |
| `glance_widget_ios` | iOS implementation (WidgetKit) |

---

## Contributing

Contributions are welcome! Please read our contributing guidelines before submitting PRs.

## License

MIT License - see [LICENSE](LICENSE) for details.
