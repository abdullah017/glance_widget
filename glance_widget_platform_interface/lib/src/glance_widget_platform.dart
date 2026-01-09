import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'method_channel_glance_widget.dart';
import 'types/widget_data.dart';
import 'types/widget_theme.dart';
import 'types/widget_action.dart';

/// The interface that implementations of glance_widget must implement.
abstract class GlanceWidgetPlatform extends PlatformInterface {
  GlanceWidgetPlatform() : super(token: _token);

  static final Object _token = Object();

  static GlanceWidgetPlatform _instance = MethodChannelGlanceWidget();

  /// The default instance of [GlanceWidgetPlatform] to use.
  static GlanceWidgetPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [GlanceWidgetPlatform].
  static set instance(GlanceWidgetPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Updates a Simple Widget with the given data.
  Future<bool> updateSimpleWidget({
    required String widgetId,
    required SimpleWidgetData data,
    GlanceTheme? theme,
  }) {
    throw UnimplementedError('updateSimpleWidget() has not been implemented.');
  }

  /// Updates a Progress Widget with the given data.
  Future<bool> updateProgressWidget({
    required String widgetId,
    required ProgressWidgetData data,
    GlanceTheme? theme,
  }) {
    throw UnimplementedError(
      'updateProgressWidget() has not been implemented.',
    );
  }

  /// Updates a List Widget with the given data.
  Future<bool> updateListWidget({
    required String widgetId,
    required ListWidgetData data,
    GlanceTheme? theme,
  }) {
    throw UnimplementedError('updateListWidget() has not been implemented.');
  }

  /// Sets the global theme for all widgets.
  Future<bool> setGlobalTheme(GlanceTheme theme) {
    throw UnimplementedError('setGlobalTheme() has not been implemented.');
  }

  /// Forces refresh of all widgets.
  Future<bool> forceRefreshAll() {
    throw UnimplementedError('forceRefreshAll() has not been implemented.');
  }

  /// Gets the list of active widget IDs.
  Future<List<String>> getActiveWidgetIds() {
    throw UnimplementedError('getActiveWidgetIds() has not been implemented.');
  }

  /// Stream of widget action events (taps, etc.)
  Stream<GlanceWidgetAction> get onWidgetAction {
    throw UnimplementedError('onWidgetAction has not been implemented.');
  }

  /// Gets the Widget Push Token for server-triggered updates (iOS 26+).
  ///
  /// This token can be sent to your server to trigger widget updates via APNs.
  /// When your server sends a push notification with `apns-push-type: widgets`,
  /// iOS will wake the widget and call `getTimeline()`.
  ///
  /// Returns `null` on unsupported platforms (Android, iOS < 26) or if the
  /// token is not yet available.
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
  Future<String?> getWidgetPushToken() {
    throw UnimplementedError('getWidgetPushToken() has not been implemented.');
  }

  /// Checks if Widget Push Updates are supported on the current platform.
  ///
  /// Returns `true` on iOS 26+ where Widget Push Updates are available.
  /// Returns `false` on Android and older iOS versions.
  ///
  /// Use this to conditionally show UI or enable features that depend on
  /// server-triggered widget updates.
  ///
  /// ```dart
  /// final isSupported = await GlanceWidget.isWidgetPushSupported();
  /// if (isSupported) {
  ///   final token = await GlanceWidget.getWidgetPushToken();
  ///   // Send token to server
  /// }
  /// ```
  Future<bool> isWidgetPushSupported() {
    throw UnimplementedError(
      'isWidgetPushSupported() has not been implemented.',
    );
  }
}
