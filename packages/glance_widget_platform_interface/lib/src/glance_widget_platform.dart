import 'package:glance_widget_platform_interface/src/method_channel_glance_widget.dart';
import 'package:glance_widget_platform_interface/src/types/widget_action.dart';
import 'package:glance_widget_platform_interface/src/types/widget_data.dart';
import 'package:glance_widget_platform_interface/src/types/widget_theme.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// The interface that implementations of glance_widget must implement.
abstract class GlanceWidgetPlatform extends PlatformInterface {
  /// Constructs a platform implementation.
  ///
  /// Subclasses pass the shared verification token up, so that a class that
  /// merely `implements` this interface cannot be installed as the instance.
  GlanceWidgetPlatform() : super(token: _token);

  static final Object _token = Object();

  static GlanceWidgetPlatform _instance = MethodChannelGlanceWidget();

  /// The default instance of [GlanceWidgetPlatform] to use.
  static GlanceWidgetPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [GlanceWidgetPlatform].
  static set instance(GlanceWidgetPlatform value) {
    PlatformInterface.verifyToken(value, _token);
    if (!identical(_instance, value)) {
      _instance.dispose();
    }
    _instance = value;
  }

  /// Releases resources held by this platform implementation.
  /// Subclasses should override to clean up streams and subscriptions.
  void dispose() {}

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

  /// Updates an Image Widget with the given data.
  Future<bool> updateImageWidget({
    required String widgetId,
    required ImageWidgetData data,
    GlanceTheme? theme,
  }) {
    throw UnimplementedError('updateImageWidget() has not been implemented.');
  }

  /// Updates a Chart Widget with the given data.
  Future<bool> updateChartWidget({
    required String widgetId,
    required ChartWidgetData data,
    GlanceTheme? theme,
  }) {
    throw UnimplementedError('updateChartWidget() has not been implemented.');
  }

  /// Updates a Calendar Widget with the given data.
  Future<bool> updateCalendarWidget({
    required String widgetId,
    required CalendarWidgetData data,
    GlanceTheme? theme,
  }) {
    throw UnimplementedError(
      'updateCalendarWidget() has not been implemented.',
    );
  }

  /// Updates a Gauge Widget with the given data.
  Future<bool> updateGaugeWidget({
    required String widgetId,
    required GaugeWidgetData data,
    GlanceTheme? theme,
  }) {
    throw UnimplementedError('updateGaugeWidget() has not been implemented.');
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

  /// Configures background updates for a widget.
  ///
  /// This allows widgets to update even when the app is closed by periodically
  /// fetching data from an API and updating the widget.
  ///
  /// **Note:** On Android, the minimum update interval is 15 minutes due to
  /// WorkManager constraints. More frequent updates are not possible while
  /// respecting Android's battery optimization guidelines.
  ///
  /// ## Parameters
  ///
  /// * [widgetId] - Unique identifier for the widget
  /// * [template] - Widget template type: "simple", "progress", or "list"
  /// * [apiUrl] - API endpoint URL to fetch data from
  /// * [headers] - Optional HTTP headers for API requests
  /// * [intervalMinutes] - Update interval in minutes (minimum 15)
  /// * [title] - Widget title to display
  /// * [valuePath] - JSONPath expression to extract main value (e.g., "$.data.price")
  /// * [subtitlePath] - Optional JSONPath for subtitle
  /// * [valuePrefix] - Optional prefix for value (e.g., "$")
  /// * [valueSuffix] - Optional suffix for value (e.g., "%")
  ///
  /// ## Example
  ///
  /// ```dart
  /// await GlanceWidget.configureBackgroundUpdate(
  ///   widgetId: 'crypto_btc',
  ///   template: GlanceTemplate.simple,
  ///   apiUrl: 'https://api.example.com/price',
  ///   intervalMinutes: 15,
  ///   title: 'Bitcoin',
  ///   valuePath: r'$.bitcoin.usd',
  ///   valuePrefix: r'$',
  /// );
  /// ```
  Future<bool> configureBackgroundUpdate({
    required String widgetId,
    required String template,
    required String apiUrl,
    Map<String, String> headers = const {},
    int intervalMinutes = 15,
    required String title,
    required String valuePath,
    String? subtitlePath,
    String? valuePrefix,
    String? valueSuffix,
  }) {
    throw UnimplementedError(
      'configureBackgroundUpdate() has not been implemented.',
    );
  }

  /// Cancels background updates for a widget.
  ///
  /// Stops the periodic background update task for the specified widget.
  /// The widget will retain its last data but will no longer update automatically.
  ///
  /// ```dart
  /// await GlanceWidget.cancelBackgroundUpdate('crypto_btc');
  /// ```
  Future<bool> cancelBackgroundUpdate(String widgetId) {
    throw UnimplementedError(
      'cancelBackgroundUpdate() has not been implemented.',
    );
  }

  /// Gets the status of background updates for a widget.
  ///
  /// Returns a map containing:
  /// * `widgetId` - The widget identifier
  /// * `isConfigured` - Whether background updates are configured
  /// * `isEnabled` - Whether background updates are enabled
  /// * `intervalMinutes` - Update interval in minutes
  /// * `workState` - Current work state (ENQUEUED, RUNNING, etc.)
  /// * `apiUrl` - The configured API URL
  ///
  /// ```dart
  /// final status = await GlanceWidget.getBackgroundUpdateStatus('crypto_btc');
  /// print('Configured: ${status['isConfigured']}');
  /// print('Work state: ${status['workState']}');
  /// ```
  Future<Map<String, dynamic>> getBackgroundUpdateStatus(String widgetId) {
    throw UnimplementedError(
      'getBackgroundUpdateStatus() has not been implemented.',
    );
  }

  /// Configures iOS timeline-based refresh for a widget.
  ///
  /// This tells the iOS widget extension to use `.after(date)` timeline policy
  /// instead of `.never`, allowing the widget to refresh periodically even when
  /// the app is not in the foreground.
  ///
  /// **Note:** WidgetKit manages the actual refresh schedule. The interval is a
  /// suggestion — iOS may delay refreshes to optimize battery life. Typical
  /// minimum effective interval is ~15-30 minutes.
  ///
  /// On Android, this is a no-op (use [configureBackgroundUpdate] instead).
  ///
  /// ## Parameters
  /// * [widgetId] - The widget identifier
  /// * [intervalMinutes] - Suggested refresh interval in minutes (minimum 5)
  ///
  /// ```dart
  /// await GlanceWidget.configureTimelineRefresh(
  ///   widgetId: 'weather',
  ///   intervalMinutes: 30,
  /// );
  /// ```
  Future<bool> configureTimelineRefresh({
    required String widgetId,
    int intervalMinutes = 30,
  }) {
    throw UnimplementedError(
      'configureTimelineRefresh() has not been implemented.',
    );
  }

  /// Cancels iOS timeline-based refresh for a widget.
  ///
  /// Reverts the widget to `.never` timeline policy, meaning it will only
  /// update when the app explicitly triggers a reload.
  ///
  /// On Android, this is a no-op.
  Future<bool> cancelTimelineRefresh(String widgetId) {
    throw UnimplementedError(
      'cancelTimelineRefresh() has not been implemented.',
    );
  }

  /// Marks widget configuration as complete.
  ///
  /// Call this after the user has finished configuring a widget
  /// (e.g., selected which data to display). This tells the platform
  /// to finalize the widget placement.
  ///
  /// On Android, this completes the configuration activity result.
  /// On iOS, this is a no-op as configuration is handled by the system.
  Future<bool> completeWidgetConfiguration(String widgetId) {
    throw UnimplementedError(
      'completeWidgetConfiguration() has not been implemented.',
    );
  }

  /// Triggers a one-time background update immediately (for testing).
  ///
  /// This bypasses the 15-minute minimum interval and runs the worker
  /// immediately. Useful for testing and debugging.
  ///
  /// **Note:** This only works if background updates are already configured
  /// for the widget using [configureBackgroundUpdate].
  ///
  /// ```dart
  /// // First configure background updates
  /// await GlanceWidget.configureBackgroundUpdate(...);
  ///
  /// // Then test immediately
  /// await GlanceWidget.testBackgroundUpdate('crypto_btc');
  /// ```
  Future<bool> testBackgroundUpdate(String widgetId) {
    throw UnimplementedError(
      'testBackgroundUpdate() has not been implemented.',
    );
  }
}
