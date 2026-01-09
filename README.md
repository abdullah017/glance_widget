# glance_widget

[![pub package](https://img.shields.io/pub/v/glance_widget.svg)](https://pub.dev/packages/glance_widget)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Create instant-updating Android home screen widgets using Jetpack Glance. Unlike traditional XML-based widgets with 30-minute minimum update intervals, Glance widgets update in **< 1 second**.

## Features

- **Instant Updates** - Widget updates in less than 1 second (no 30-minute limit)
- **3 Widget Templates** - Simple, Progress, and List widgets ready to use
- **Theme Support** - Light/Dark themes with full customization
- **Tap Actions** - Handle widget taps and interactions
- **Type-Safe API** - Clean Dart API with strong typing

## Widget Templates

| Template | Description | Use Cases |
|----------|-------------|-----------|
| **SimpleWidget** | Title + Value + Subtitle | Crypto prices, weather, stats |
| **ProgressWidget** | Circular/Linear progress | Downloads, goals, battery |
| **ListWidget** | Scrollable item list | To-do, news, activities |

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  glance_widget: ^0.1.0
```

### Android Setup

1. Add widget receivers to your `AndroidManifest.xml`:

```xml
<application>
    <!-- ... your existing configuration ... -->

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

2. Create widget info XML files in `android/app/src/main/res/xml/`:

**simple_widget_info.xml:**
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

3. Ensure your `android/app/build.gradle.kts` has:

```kotlin
android {
    compileSdk = 35
    defaultConfig {
        minSdk = 26
    }
}
```

## Usage

### Simple Widget

Perfect for displaying single values like crypto prices:

```dart
import 'package:glance_widget/glance_widget.dart';

// Update widget instantly
await GlanceWidget.simple(
  id: 'crypto_btc',
  title: 'Bitcoin',
  value: '\$94,532.00',
  subtitle: '+2.34%',
  subtitleColor: Colors.green,
);
```

### Progress Widget

Great for downloads, goals, or any progress tracking:

```dart
await GlanceWidget.progress(
  id: 'download_1',
  title: 'Downloading...',
  progress: 0.75,  // 0.0 to 1.0
  subtitle: '75% complete',
  progressType: ProgressType.circular,  // or ProgressType.linear
  progressColor: Colors.blue,
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

Set a global theme for all widgets:

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

Listen to widget interaction events:

```dart
GlanceWidget.onAction.listen((action) {
  switch (action.type) {
    case GlanceActionType.tap:
      print('Widget ${action.widgetId} was tapped');
      Navigator.pushNamed(context, '/details');
      break;
    case GlanceActionType.itemTap:
      final index = action.payload?['index'];
      print('Item $index tapped');
      break;
    default:
      break;
  }
});
```

### Controller API (Advanced)

For more control, use the controller API:

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

// Listen to actions
controller.onAction.listen((action) {
  // Handle action for this specific widget
});

// Don't forget to dispose
controller.dispose();
```

## Requirements

- Flutter 3.10+
- Android SDK 26+ (Android 8.0)
- Kotlin 2.0+

## Why Jetpack Glance?

Traditional Android widgets use XML-based RemoteViews with a minimum update interval of 30 minutes. Jetpack Glance provides:

| Feature | XML Widgets | Jetpack Glance |
|---------|-------------|----------------|
| Update Speed | 30 min minimum | < 1 second |
| UI Framework | XML layouts | Compose |
| State Management | Manual | DataStore |
| Theming | Limited | Full support |

## Example

Check the [example](example/) directory for a complete demo app showing all widget types.

## Contributing

Contributions are welcome! Please read our contributing guidelines before submitting PRs.

## License

MIT License - see [LICENSE](LICENSE) for details.
