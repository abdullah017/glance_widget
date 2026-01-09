/// iOS implementation of the glance_widget plugin.
library;

import 'package:glance_widget_platform_interface/glance_widget_platform_interface.dart';

/// The iOS implementation of [GlanceWidgetPlatform].
///
/// This class implements the `package:glance_widget` functionality for iOS
/// using WidgetKit.
///
/// ## Update Strategy
///
/// This implementation uses a hybrid update strategy:
///
/// - **App in foreground**: Calls `WidgetCenter.shared.reloadAllTimelines()`
///   which provides instant updates with NO budget limit (iOS 14+)
/// - **App in background**: Uses Timeline-based updates with system budgeting
/// - **Server-triggered (iOS 26+)**: Widget Push Updates via APNs
///
/// ## Widget Communication
///
/// Data is shared between the Flutter app and widget extension via App Groups
/// using UserDefaults with a shared suite name.
class GlanceWidgetIos extends GlanceWidgetPlatform {
  /// Registers this class as the default instance of [GlanceWidgetPlatform].
  static void registerWith() {
    GlanceWidgetPlatform.instance = GlanceWidgetIos();
  }

  final MethodChannelGlanceWidget _methodChannel = MethodChannelGlanceWidget();

  @override
  Future<bool> updateSimpleWidget({
    required String widgetId,
    required SimpleWidgetData data,
    GlanceTheme? theme,
  }) {
    return _methodChannel.updateSimpleWidget(
      widgetId: widgetId,
      data: data,
      theme: theme,
    );
  }

  @override
  Future<bool> updateProgressWidget({
    required String widgetId,
    required ProgressWidgetData data,
    GlanceTheme? theme,
  }) {
    return _methodChannel.updateProgressWidget(
      widgetId: widgetId,
      data: data,
      theme: theme,
    );
  }

  @override
  Future<bool> updateListWidget({
    required String widgetId,
    required ListWidgetData data,
    GlanceTheme? theme,
  }) {
    return _methodChannel.updateListWidget(
      widgetId: widgetId,
      data: data,
      theme: theme,
    );
  }

  @override
  Future<bool> setGlobalTheme(GlanceTheme theme) {
    return _methodChannel.setGlobalTheme(theme);
  }

  /// Forces refresh of all widgets.
  ///
  /// On iOS, this calls `WidgetCenter.shared.reloadAllTimelines()`.
  ///
  /// **Important**: When the app is in the foreground, this provides
  /// instant updates with NO budget limit. This is the recommended
  /// approach for real-time updates while the user is actively using the app.
  @override
  Future<bool> forceRefreshAll() {
    return _methodChannel.forceRefreshAll();
  }

  @override
  Future<List<String>> getActiveWidgetIds() {
    return _methodChannel.getActiveWidgetIds();
  }

  @override
  Stream<GlanceWidgetAction> get onWidgetAction =>
      _methodChannel.onWidgetAction;

  /// Gets the Widget Push Token for server-triggered updates (iOS 26+).
  ///
  /// This token can be sent to your server to trigger widget updates via APNs.
  /// When your server sends a push notification with `apns-push-type: widgets`,
  /// iOS will wake the widget and call `getTimeline()`.
  ///
  /// Returns `null` on iOS versions below 26 or if the token is not available.
  ///
  /// ## Server-side APNs Request Example
  ///
  /// ```http
  /// POST https://api.push.apple.com/3/device/{widget_push_token}
  /// Headers:
  ///   apns-push-type: widgets
  ///   apns-topic: com.example.app.push-type.widgets
  /// Body:
  ///   {"aps": {"content-changed": true}}
  /// ```
  @override
  Future<String?> getWidgetPushToken() {
    return _methodChannel.getWidgetPushToken();
  }

  /// Checks if Widget Push Updates are supported on this device.
  ///
  /// Returns `true` on iOS 26+ where Widget Push Updates are available.
  /// Returns `false` on older iOS versions.
  ///
  /// Use this to conditionally enable server-triggered widget update features:
  ///
  /// ```dart
  /// final isSupported = await GlanceWidget.isWidgetPushSupported();
  /// if (isSupported) {
  ///   final token = await GlanceWidget.getWidgetPushToken();
  ///   if (token != null) {
  ///     await sendTokenToServer(token);
  ///   }
  /// }
  /// ```
  @override
  Future<bool> isWidgetPushSupported() {
    return _methodChannel.isWidgetPushSupported();
  }
}
