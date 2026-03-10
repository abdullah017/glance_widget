# glance_widget

[![pub package](https://img.shields.io/pub/v/glance_widget.svg)](https://pub.dev/packages/glance_widget)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Create instant-updating home screen widgets for **Android** and **iOS**. Built with Jetpack Glance (Android) and WidgetKit (iOS).

## Features

- **Instant Updates** - Widgets update in < 1 second on both platforms
- **Cross-Platform** - Same API for Android and iOS
- **7 Widget Templates** - Simple, Progress, List, Image, Chart, Calendar, and Gauge
- **Theme Support** - Light/Dark themes with full customization
- **Deep Links** - All widgets support custom deep link URIs
- **Interactive Actions** - Tap, checkbox toggle, item tap handling
- **Background Updates** - Android widgets update even when app is closed (WorkManager)
- **Timeline Refresh** - iOS widgets refresh periodically via WidgetKit timeline policy
- **iOS 26+ Push Updates** - Server-triggered widget updates via APNs
- **Lock Screen Widgets** - Android widgets on home screen and lock screen
- **Real-time Data** - Debounced controller for high-frequency updates (crypto, stocks)
- **Widget Configuration** - Handle widget setup flow when users add widgets

## Platform Comparison

| Feature | Android (Jetpack Glance) | iOS (WidgetKit) |
|---------|--------------------------|-----------------|
| Update Speed | < 1 second | < 1 second (app foreground) |
| Background Updates | WorkManager (15 min+) | Timeline-based (.after policy) |
| Server Push | N/A | iOS 26+ (APNs) |
| Lock Screen | Supported (keyguard) | N/A |
| Interactive Actions | ActionCallback | URL-based actions |
| Min Version | Android 8.0 (API 26) | iOS 16.0 |

## Widget Templates

| Template | Description | Use Cases |
|----------|-------------|-----------|
| **SimpleWidget** | Title + Value + Subtitle | Crypto prices, weather, stats |
| **ProgressWidget** | Circular/Linear progress | Downloads, goals, battery |
| **ListWidget** | Scrollable item list with checkboxes | To-do, shopping, activities |
| **ImageWidget** | Photo with title and subtitle | Photo of the day, album art |
| **ChartWidget** | Line, bar, or sparkline chart | Revenue trends, analytics |
| **CalendarWidget** | Date header with event list | Daily schedule, meetings |
| **GaugeWidget** | Radial or dashboard metrics | CPU usage, performance scores |

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  glance_widget: ^0.7.0
```

## Requirements

| Platform | Minimum Version |
|----------|-----------------|
| Flutter | 3.27+ |
| Dart | 3.6+ |
| Android | API 26 (Android 8.0) |
| iOS | 16.0 |

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

    <!-- Image Widget -->
    <receiver
        android:name="com.example.glance_widget_android.templates.ImageWidgetReceiver"
        android:exported="true">
        <intent-filter>
            <action android:name="android.appwidget.action.APPWIDGET_UPDATE" />
        </intent-filter>
        <meta-data
            android:name="android.appwidget.provider"
            android:resource="@xml/image_widget_info" />
    </receiver>

    <!-- Chart Widget -->
    <receiver
        android:name="com.example.glance_widget_android.templates.ChartWidgetReceiver"
        android:exported="true">
        <intent-filter>
            <action android:name="android.appwidget.action.APPWIDGET_UPDATE" />
        </intent-filter>
        <meta-data
            android:name="android.appwidget.provider"
            android:resource="@xml/chart_widget_info" />
    </receiver>

    <!-- Calendar Widget -->
    <receiver
        android:name="com.example.glance_widget_android.templates.CalendarWidgetReceiver"
        android:exported="true">
        <intent-filter>
            <action android:name="android.appwidget.action.APPWIDGET_UPDATE" />
        </intent-filter>
        <meta-data
            android:name="android.appwidget.provider"
            android:resource="@xml/calendar_widget_info" />
    </receiver>

    <!-- Gauge Widget -->
    <receiver
        android:name="com.example.glance_widget_android.templates.GaugeWidgetReceiver"
        android:exported="true">
        <intent-filter>
            <action android:name="android.appwidget.action.APPWIDGET_UPDATE" />
        </intent-filter>
        <meta-data
            android:name="android.appwidget.provider"
            android:resource="@xml/gauge_widget_info" />
    </receiver>
</application>
```

### 2. Create Widget Info XML

Create `android/app/src/main/res/xml/simple_widget_info.xml` (repeat for each template):

```xml
<?xml version="1.0" encoding="utf-8"?>
<appwidget-provider xmlns:android="http://schemas.android.com/apk/res/android"
    android:minWidth="180dp"
    android:minHeight="110dp"
    android:targetCellWidth="3"
    android:targetCellHeight="2"
    android:resizeMode="horizontal|vertical"
    android:widgetCategory="home_screen|keyguard"
    android:updatePeriodMillis="0" />
```

### 3. Set SDK Versions

In `android/app/build.gradle.kts`:

```kotlin
android {
    compileSdk = 36
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
- `ImageWidget.swift`
- `ChartWidget.swift`
- `CalendarWidget.swift`
- `GaugeWidget.swift`

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

```dart
import 'package:glance_widget/glance_widget.dart';

await GlanceWidget.simple(
  id: 'crypto_btc',
  title: 'Bitcoin',
  value: '\$94,532.00',
  subtitle: '+2.34%',
  subtitleColor: Colors.green,
  deepLinkUri: 'myapp://crypto/btc',
);
```

### Progress Widget

```dart
await GlanceWidget.progress(
  id: 'daily_goal',
  title: 'Steps Today',
  progress: 0.75,
  subtitle: '7,500 / 10,000',
  progressType: ProgressType.circular,
  progressColor: Colors.green,
);
```

### List Widget

```dart
await GlanceWidget.list(
  id: 'todo_list',
  title: 'Today\'s Tasks',
  items: [
    GlanceListItem(text: 'Buy groceries', checked: true),
    GlanceListItem(text: 'Call mom', checked: false),
  ],
  showCheckboxes: true,
);
```

### Image Widget

```dart
await GlanceWidget.image(
  id: 'photo',
  title: 'Photo of the Day',
  imageBase64: base64EncodedImage,
  subtitle: 'Beautiful sunset',
  fit: ImageFit.cover,
);
```

### Chart Widget

```dart
await GlanceWidget.chart(
  id: 'revenue',
  title: 'Revenue',
  dataPoints: [12, 19, 15, 25, 22, 30, 28],
  chartType: ChartType.line,
  color: Colors.blue,
  subtitle: 'Last 7 days',
);
```

### Calendar Widget

```dart
await GlanceWidget.calendar(
  id: 'events',
  title: 'Today\'s Events',
  date: DateTime.now(),
  events: [
    CalendarEvent(time: '09:00', title: 'Standup', color: Colors.green),
    CalendarEvent(time: '14:00', title: 'Review', color: Colors.blue),
  ],
);
```

### Gauge Widget

```dart
await GlanceWidget.gauge(
  id: 'monitor',
  title: 'System Monitor',
  metrics: [
    GaugeMetric(label: 'CPU', value: 45, maxValue: 100, color: Colors.green, unit: '%'),
    GaugeMetric(label: 'Memory', value: 72, maxValue: 100, color: Colors.orange, unit: '%'),
  ],
  gaugeType: GaugeType.radial,
);
```

### Theme Configuration

```dart
await GlanceWidget.setTheme(GlanceTheme.dark());

// Or custom theme
await GlanceWidget.setTheme(GlanceTheme(
  backgroundColor: Color(0xFF1A1A2E),
  textColor: Colors.white,
  secondaryTextColor: Color(0xFFB0B0B0),
  accentColor: Colors.orange,
  borderRadius: 16.0,
  isDark: true,
));
```

### Handle Widget Actions

```dart
GlanceWidget.onAction.listen((action) {
  switch (action.type) {
    case GlanceActionType.tap:
      print('Widget ${action.widgetId} tapped');
      break;
    case GlanceActionType.checkboxToggle:
      print('Item ${action.itemIndex} toggled to ${action.value}');
      break;
    case GlanceActionType.itemTap:
      print('Item ${action.itemIndex} tapped');
      break;
    case GlanceActionType.configure:
      // Show configuration UI, then:
      GlanceWidget.completeWidgetConfiguration(action.widgetId);
      break;
    default:
      break;
  }
});
```

### Deep Links

All widget types support `deepLinkUri` parameter:

```dart
await GlanceWidget.simple(
  id: 'btc',
  title: 'Bitcoin',
  value: '\$94,532',
  deepLinkUri: 'myapp://crypto/btc',  // Opens when widget is tapped
);
```

---

## Background Updates (Android)

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

// Cancel
await GlanceWidget.cancelBackgroundUpdate('crypto_btc');
```

## Timeline Refresh (iOS)

```dart
// Enable periodic refresh via WidgetKit
await GlanceWidget.configureTimelineRefresh(
  widgetId: 'weather',
  interval: Duration(minutes: 30),
);

// Disable
await GlanceWidget.cancelTimelineRefresh('weather');
```

## DebouncedWidgetController (Real-time Data)

For high-frequency updates like crypto prices or live scores:

```dart
final controller = DebouncedWidgetController(
  widgetId: 'crypto_btc',
  template: GlanceTemplate.simple,
  theme: GlanceTheme.dark(),
  debounceInterval: Duration(milliseconds: 100),
  maxWaitTime: Duration(milliseconds: 500),
);

priceStream.listen((price) {
  controller.scheduleUpdate(SimpleWidgetData(
    title: 'Bitcoin',
    value: '\$${price.toStringAsFixed(2)}',
  ));
});

controller.dispose();
```

## iOS 26+ Server Push Updates

```dart
if (await GlanceWidget.isWidgetPushSupported()) {
  final token = await GlanceWidget.getWidgetPushToken();
  if (token != null) {
    await api.registerWidgetPushToken(token);
  }
}
```

---

## Architecture

| Package | Description |
|---------|-------------|
| `glance_widget` | Main package with cross-platform API |
| `glance_widget_platform_interface` | Platform-independent interface |
| `glance_widget_android` | Android implementation (Jetpack Glance) |
| `glance_widget_ios` | iOS implementation (WidgetKit) |

## Example

Check the [example](example/) directory for a complete demo app showing all 7 widget types.

```bash
cd example
flutter run
```

## Images
<img width="400" height="2992" alt="Screenshot_1773150902" src="https://github.com/user-attachments/assets/3bbdd15f-feb8-411f-b611-058d7cd53855" />
<img width="400" height="2992" alt="Screenshot_1773150912" src="https://github.com/user-attachments/assets/6f991764-17cd-4ef8-a0fa-700cefd7d719" />
<img width="400" height="2992" alt="Screenshot_1773150915" src="https://github.com/user-attachments/assets/baa8eeb4-7ccc-43a1-895b-63d775c76ffd" />
<img width="400" height="2992" alt="Screenshot_1773150927" src="https://github.com/user-attachments/assets/c133f631-7a90-4b76-9a1f-4a9a8c3b54a3" />
<img width="400" height="2992" alt="Screenshot_1773150930" src="https://github.com/user-attachments/assets/6b3322fd-a051-45b1-9ac9-0184811ce1db" />
<img width="400" height="2992" alt="Screenshot_1773150936" src="https://github.com/user-attachments/assets/83f3be25-3e4f-425b-b8ca-96895f68008d" />
<img width="400" height="2992" alt="Screenshot_1773150941" src="https://github.com/user-attachments/assets/33fa451b-f6d0-4518-bfa7-348f04e02237" />
<img width="400" height="2992" alt="Screenshot_1773150950" src="https://github.com/user-attachments/assets/cc7e4a87-b00c-4bc3-8572-215be8397302" />
<img width="400" height="2992" alt="Screenshot_1773151220" src="https://github.com/user-attachments/assets/4a6e30a1-0e46-4776-a7c8-b0b91bbed0c6" />
<img width="400" height="2992" alt="Screenshot_1773151233" src="https://github.com/user-attachments/assets/a50e6bd1-a305-48be-bcc9-dcff7c04fe08" />



## Contributing

Contributions are welcome! Please read our contributing guidelines before submitting PRs.

## License

MIT License - see [LICENSE](LICENSE) for details.
