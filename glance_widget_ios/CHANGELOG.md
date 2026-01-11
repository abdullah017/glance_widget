# Changelog

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
