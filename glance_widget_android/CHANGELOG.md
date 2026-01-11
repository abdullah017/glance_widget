# Changelog

## 0.2.0

* **JSON Serialization** - Fixed list widget item parsing using proper JSON instead of delimiter-based parsing
* **Error Handling** - Added `UpdateResult` sealed class for structured error reporting
* **Backward Compatibility** - Legacy delimiter parsing preserved for existing widget data
* Updated dependency on glance_widget_platform_interface to ^0.3.0

## 0.1.1

* Updated dependency on glance_widget_platform_interface to ^0.2.0
* Compatible with iOS implementation release

## 0.1.0

* Initial release
* Android implementation using Jetpack Glance
* Three widget templates: Simple, Progress, List
* Instant widget updates (< 1 second)
* Theme support with dark/light modes
* Widget action callbacks to Flutter
* JSON serialization for list items
* Proper coroutine lifecycle management
* ProGuard/R8 rules included
