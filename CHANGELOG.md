## 0.2.0

* **iOS Support** - Added WidgetKit implementation for iOS 16+
* Instant updates when app is in foreground (no budget limit!)
* Widget Push Updates support for iOS 26+ (server-triggered updates via APNs)
* Added `getWidgetPushToken()` for server-side widget updates
* Added `isWidgetPushSupported()` for runtime platform check
* Privacy manifest included for App Store compliance
* Updated description to reflect cross-platform support

## 0.1.0

* Initial release
* **SimpleWidget** - Title + Value + Subtitle template for prices, stats, metrics
* **ProgressWidget** - Circular and linear progress indicators
* **ListWidget** - Scrollable list with optional checkboxes
* Theme support (light/dark) with full customization
* Widget tap action handling via streams
* Instant updates (< 1 second) using Jetpack Glance
* Controller API for advanced widget management
