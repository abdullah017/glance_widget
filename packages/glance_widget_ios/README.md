# glance_widget_ios

iOS implementation of the [`glance_widget`](https://pub.dev/packages/glance_widget) plugin using WidgetKit.

## Features

- Three widget templates: Simple, Progress, and List
- **Instant updates** when app is in foreground (no budget limit!)
- Theme support with dark/light modes
- Widget tap actions sent back to Flutter
- Widget Push Updates support (iOS 26+)

## Requirements

- iOS 16.0 or higher
- Xcode 15.0 or higher
- Swift 5.0 or higher

## Installation

This package is automatically included when you add `glance_widget` to your Flutter project and run on iOS.

```yaml
dependencies:
  glance_widget: ^0.1.0
```

## Setup

### 1. Create Widget Extension

In Xcode:
1. Open your iOS project (`ios/Runner.xcworkspace`)
2. File → New → Target → Widget Extension
3. Name it `GlanceWidgets`
4. Uncheck "Include Configuration App Intent" (optional)

### 2. Configure App Groups

Both the main app and widget extension need the same App Group:

1. Select your main app target → Signing & Capabilities → + Capability → App Groups
2. Add: `group.com.yourcompany.yourapp`
3. Select widget extension target → repeat steps 1-2 with the same group ID

### 3. Configure URL Scheme

In `ios/Runner/Info.plist`, add:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>glancewidget</string>
        </array>
        <key>CFBundleURLName</key>
        <string>com.yourcompany.yourapp.widget.action</string>
    </dict>
</array>
```

### 4. Implement Widget Extension

Create your widget views in the extension. Example `SimpleWidget.swift`:

```swift
import WidgetKit
import SwiftUI

struct SimpleWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleWidgetEntry {
        SimpleWidgetEntry(date: Date(), title: "Title", value: "--")
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleWidgetEntry) -> Void) {
        let entry = loadFromStorage()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleWidgetEntry>) -> Void) {
        let entry = loadFromStorage()
        // Use .never policy - updates only when app calls reloadTimelines
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }

    private func loadFromStorage() -> SimpleWidgetEntry {
        let defaults = UserDefaults(suiteName: "group.com.yourcompany.yourapp")
        // Load data from shared storage...
    }
}
```

## Update Strategy

### App in Foreground (Instant, No Budget!)

When your Flutter app is in the foreground, widget updates are **instant** and have **no budget limit**:

```dart
// This triggers instant update when app is visible
await GlanceWidget.simple(
  id: 'price',
  title: 'Bitcoin',
  value: '\$45,000',
);
```

### App in Background (Timeline)

When the app is in background, iOS uses timeline-based updates with a daily budget.

### Server-Triggered (iOS 26+)

For server-triggered updates without opening the app:

```dart
// Get the push token
final token = await GlanceWidget.getWidgetPushToken();
if (token != null) {
  // Send to your server for APNs push
}
```

Server sends APNs request:
```http
POST https://api.push.apple.com/3/device/{token}
Headers:
  apns-push-type: widgets
  apns-topic: com.yourcompany.yourapp.push-type.widgets
Body:
  {"aps": {"content-changed": true}}
```

## Troubleshooting

### Widget not updating?

1. Ensure App Groups are configured correctly in both targets
2. Check that the App Group ID matches in your code
3. Verify the widget extension is properly linked

### Widget shows placeholder?

1. The widget extension can't find data in shared storage
2. Verify UserDefaults suite name matches App Group ID
3. Try force refreshing: `GlanceWidget.forceRefreshAll()`

## More Information

- [Main package documentation](https://pub.dev/packages/glance_widget)
- [WidgetKit documentation](https://developer.apple.com/documentation/widgetkit)
- [App Groups documentation](https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_security_application-groups)
