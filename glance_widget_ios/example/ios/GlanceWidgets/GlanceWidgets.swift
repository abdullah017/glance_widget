import WidgetKit
import SwiftUI

/// Main entry point for the Glance Widgets extension.
///
/// This bundle provides three widget types:
/// - **SimpleWidget**: Display a value with title and subtitle
/// - **ProgressWidget**: Show circular or linear progress
/// - **ListWidget**: Display a list of items with optional checkboxes
///
/// ## Setup Instructions
///
/// 1. Add this widget extension target to your iOS app in Xcode
/// 2. Configure App Groups entitlement with the same ID as your main app
/// 3. Ensure the App Group ID in `AppConfig.appGroupId` matches your configuration
///
/// ## Update Behavior
///
/// Widgets use `.never` timeline policy, meaning they only update when:
/// - The Flutter app calls `GlanceWidget.forceRefreshAll()`
/// - The Flutter app updates a specific widget
///
/// When the app is in foreground, updates are **instant** with no budget limit.
@main
struct GlanceWidgetsBundle: WidgetBundle {
    var body: some Widget {
        SimpleWidget()
        ProgressWidget()
        ListWidget()
    }
}

// MARK: - iOS 26+ Widget Push Updates Support

/// Widget Push Handler for server-triggered updates (iOS 26+)
///
/// This handler receives push tokens that can be sent to your server
/// for triggering widget updates via APNs.
///
/// ## Server-side Implementation
///
/// Send an APNs request with:
/// ```http
/// POST https://api.push.apple.com/3/device/{widget_push_token}
/// Headers:
///   apns-push-type: widgets
///   apns-topic: com.yourcompany.yourapp.push-type.widgets
/// Body:
///   {"aps": {"content-changed": true}}
/// ```
#if swift(>=6.0)
@available(iOS 26.0, *)
struct GlanceWidgetPushHandler: WidgetPushHandler {
    func pushTokenDidChange(_ pushToken: Data?) {
        guard let token = pushToken else {
            // Token was invalidated
            clearPushToken()
            return
        }

        // Convert token to hex string
        let tokenString = token.map { String(format: "%02.2hhx", $0) }.joined()

        // Save to App Group for Flutter to read
        savePushToken(tokenString)

        print("GlanceWidget: Push token updated: \(tokenString.prefix(16))...")
    }

    private func savePushToken(_ token: String) {
        let defaults = UserDefaults(suiteName: AppConfig.appGroupId)
        defaults?.set(token, forKey: "widgetPushToken")
        defaults?.synchronize()
    }

    private func clearPushToken() {
        let defaults = UserDefaults(suiteName: AppConfig.appGroupId)
        defaults?.removeObject(forKey: "widgetPushToken")
        defaults?.synchronize()
    }
}
#endif
