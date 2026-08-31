# iOS Widget Extension Setup Guide

This guide explains how to add the Glance Widgets extension to your Flutter iOS app.

## Prerequisites

- Xcode 15.0 or higher
- iOS 16.0+ deployment target
- Apple Developer account (for App Groups)

## Step 1: Create Widget Extension Target

1. Open your iOS project in Xcode:
   ```bash
   open ios/Runner.xcworkspace
   ```

2. In Xcode:
   - File → New → Target
   - Select "Widget Extension"
   - Product Name: `GlanceWidgets`
   - **Uncheck** "Include Configuration App Intent" (not needed)
   - **Uncheck** "Include Live Activity" (optional, for iOS 16.1+)
   - Click "Finish"
   - When asked to activate the scheme, click "Cancel" (we'll build with Flutter)

## Step 2: Configure App Groups

### Main App Target

1. Select the `Runner` target
2. Go to "Signing & Capabilities" tab
3. Click "+ Capability" → "App Groups"
4. Click "+" and add: `group.com.yourcompany.yourapp`

### Widget Extension Target

1. Select the `GlanceWidgets` target
2. Go to "Signing & Capabilities" tab
3. Click "+ Capability" → "App Groups"
4. Add the **same** App Group ID: `group.com.yourcompany.yourapp`

## Step 3: Copy Widget Files

Copy these files from the `glance_widget_ios/example/ios/GlanceWidgets/` directory to your widget extension:

```
GlanceWidgets/
├── GlanceWidgets.swift      # Widget bundle entry point
├── SharedModels.swift       # Data models (edit AppConfig.appGroupId!)
├── SimpleWidget.swift       # Simple widget template
├── ProgressWidget.swift     # Progress widget template
├── ListWidget.swift         # List widget template
├── Info.plist               # Extension info
└── GlanceWidgets.entitlements
```

## Step 4: Update App Group ID

**IMPORTANT**: Edit `SharedModels.swift` and update the App Group ID:

```swift
enum AppConfig {
    // Change this to match YOUR App Group ID
    static let appGroupId = "group.com.yourcompany.yourapp"
}
```

Also update the iOS plugin's `GlanceWidgetManager.swift`:

```swift
public static var appGroupId: String = "group.com.yourcompany.yourapp"
```

## Step 5: Configure URL Scheme

Add to your `ios/Runner/Info.plist`:

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

## Step 6: Build and Test

1. Build your Flutter app:
   ```bash
   flutter build ios --debug
   ```

2. Run on a simulator or device

3. Add widget to home screen:
   - Long press on home screen
   - Tap "+" in top left
   - Search for your app name
   - Select "Simple Widget", "Progress Widget", or "List Widget"

## Usage in Flutter

```dart
import 'package:glance_widget/glance_widget.dart';

// Update a simple widget
await GlanceWidget.simple(
  id: 'price',
  title: 'Bitcoin',
  value: '\$45,000',
  subtitle: '+2.5%',
);

// Update a progress widget
await GlanceWidget.progress(
  id: 'goal',
  title: 'Daily Steps',
  progress: 0.75,
  subtitle: '7,500 / 10,000',
);

// Update a list widget
await GlanceWidget.list(
  id: 'todos',
  title: 'Tasks',
  items: [
    GlanceListItem(text: 'Buy groceries', checked: false),
    GlanceListItem(text: 'Call mom', checked: true),
  ],
  showCheckboxes: true,
);

// Force refresh all widgets (instant when app is in foreground!)
await GlanceWidget.forceRefreshAll();

// Listen to widget tap events
GlanceWidgetController().onAction.listen((action) {
  print('Widget ${action.widgetId} tapped: ${action.type}');
  if (action.payload?['index'] != null) {
    print('Item index: ${action.payload['index']}');
  }
});
```

## Troubleshooting

### Widget shows placeholder data
- Ensure App Group ID matches in both targets
- Check that `SharedModels.swift` has the correct `appGroupId`
- Try calling `GlanceWidget.forceRefreshAll()` from your app

### Widget doesn't update
- When app is in foreground, updates should be instant
- Check Xcode console for error messages
- Verify UserDefaults data is being written correctly

### Tap events not received
- Ensure URL scheme is configured in `Info.plist`
- Check that `GlanceWidgetIosPlugin` is handling URL callbacks

### Build errors
- Clean build folder: Product → Clean Build Folder
- Delete derived data and rebuild
- Ensure all Swift files are added to the widget target

## iOS 26+ Widget Push Updates

For server-triggered updates on iOS 26+:

1. Get the push token in Flutter:
   ```dart
   final token = await GlanceWidget.getWidgetPushToken();
   if (token != null) {
     // Send to your server
     await api.registerWidgetPushToken(token);
   }
   ```

2. Send APNs push from server:
   ```http
   POST https://api.push.apple.com/3/device/{token}
   Headers:
     apns-push-type: widgets
     apns-topic: com.yourcompany.yourapp.push-type.widgets
   Body:
     {"aps": {"content-changed": true}}
   ```
