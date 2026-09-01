import 'package:glance_widget_platform_interface/src/method_channel_glance_widget.dart';
import 'package:glance_widget_platform_interface/src/types/glance_exception.dart';
import 'package:glance_widget_platform_interface/src/types/glance_widget_update.dart';
import 'package:glance_widget_platform_interface/src/types/live_activity.dart';
import 'package:glance_widget_platform_interface/src/types/widget_action.dart';
import 'package:glance_widget_platform_interface/src/types/widget_data.dart';
import 'package:glance_widget_platform_interface/src/types/widget_snapshot.dart';
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

  /// Updates many widgets, of any mix of templates, in one platform call.
  ///
  /// Every update is attempted. If some fail, the ones that succeeded stay
  /// applied and a [GlanceWidgetBatchException] names the rest.
  ///
  /// [theme] applies to every update that does not carry its own.
  Future<void> updateBatch(
    List<GlanceWidgetUpdate> updates, {
    GlanceTheme? theme,
  }) {
    throw UnimplementedError('updateBatch() has not been implemented.');
  }

  /// Updates a Simple Widget with the given data.
  Future<void> updateSimpleWidget({
    required String widgetId,
    required SimpleWidgetData data,
    GlanceTheme? theme,
  }) {
    throw UnimplementedError('updateSimpleWidget() has not been implemented.');
  }

  /// Updates a Progress Widget with the given data.
  Future<void> updateProgressWidget({
    required String widgetId,
    required ProgressWidgetData data,
    GlanceTheme? theme,
  }) {
    throw UnimplementedError(
      'updateProgressWidget() has not been implemented.',
    );
  }

  /// Updates a List Widget with the given data.
  Future<void> updateListWidget({
    required String widgetId,
    required ListWidgetData data,
    GlanceTheme? theme,
  }) {
    throw UnimplementedError('updateListWidget() has not been implemented.');
  }

  /// Updates an Image Widget with the given data.
  Future<void> updateImageWidget({
    required String widgetId,
    required ImageWidgetData data,
    GlanceTheme? theme,
  }) {
    throw UnimplementedError('updateImageWidget() has not been implemented.');
  }

  /// Updates a Chart Widget with the given data.
  Future<void> updateChartWidget({
    required String widgetId,
    required ChartWidgetData data,
    GlanceTheme? theme,
  }) {
    throw UnimplementedError('updateChartWidget() has not been implemented.');
  }

  /// Updates a Calendar Widget with the given data.
  Future<void> updateCalendarWidget({
    required String widgetId,
    required CalendarWidgetData data,
    GlanceTheme? theme,
  }) {
    throw UnimplementedError(
      'updateCalendarWidget() has not been implemented.',
    );
  }

  /// Updates a Gauge Widget with the given data.
  Future<void> updateGaugeWidget({
    required String widgetId,
    required GaugeWidgetData data,
    GlanceTheme? theme,
  }) {
    throw UnimplementedError('updateGaugeWidget() has not been implemented.');
  }

  /// Sets the global theme for all widgets.
  Future<void> setGlobalTheme(GlanceTheme theme) {
    throw UnimplementedError('setGlobalTheme() has not been implemented.');
  }

  /// Forces refresh of all widgets.
  Future<void> forceRefreshAll() {
    throw UnimplementedError('forceRefreshAll() has not been implemented.');
  }

  /// Gets the list of active widget IDs.
  Future<List<String>> getActiveWidgetIds() {
    throw UnimplementedError('getActiveWidgetIds() has not been implemented.');
  }

  /// Reads back what [widgetId] is currently showing.
  ///
  /// Returns null when the platform has no record for that id -- it was never
  /// written, or it was forgotten. Throws [GlanceWidgetFormatException] when
  /// there is a record but this version of the plugin cannot read it, because
  /// "nothing there" and "something I do not understand" are different answers
  /// and only the first means the widget is safe to overwrite unseen.
  Future<GlanceWidgetSnapshot?> getWidgetData(String widgetId) {
    throw UnimplementedError('getWidgetData() has not been implemented.');
  }

  /// Drops everything stored for [widgetId].
  Future<void> forgetWidget(String widgetId) {
    throw UnimplementedError('forgetWidget() has not been implemented.');
  }

  /// Starts a Live Activity and shows it on the Lock Screen and, on a device
  /// that has one, in the Dynamic Island.
  ///
  /// [activityId] is the caller's own name for the activity; ActivityKit
  /// assigns an id of its own that the caller never sees, and this is what
  /// [updateLiveActivity] and [endLiveActivity] use to find it again.
  ///
  /// iOS 16.2+ only. Android throws [UnsupportedError]: its nearest equivalent,
  /// Android 16's Live Updates, is a notification rather than a widget and is
  /// not something this plugin can stand in for.
  Future<void> startLiveActivity({
    required String activityId,
    required LiveActivityContent content,
  }) {
    throw UnimplementedError('startLiveActivity() has not been implemented.');
  }

  /// Replaces the content of a running Live Activity.
  Future<void> updateLiveActivity({
    required String activityId,
    required LiveActivityContent content,
  }) {
    throw UnimplementedError('updateLiveActivity() has not been implemented.');
  }

  /// Ends a running Live Activity, optionally showing [content] as its final
  /// state.
  Future<void> endLiveActivity({
    required String activityId,
    LiveActivityContent? content,
    LiveActivityDismissal dismissal = LiveActivityDismissal.standard,
  }) {
    throw UnimplementedError('endLiveActivity() has not been implemented.');
  }

  /// Whether an activity started under [activityId] is still running.
  ///
  /// An activity outlives the process that requested it: the app can be killed
  /// and relaunched while the card is still on the Lock Screen. Nothing the
  /// app held in memory survives that, so this asks the system.
  Future<bool> isLiveActivityRunning(String activityId) {
    throw UnimplementedError(
      'isLiveActivityRunning() has not been implemented.',
    );
  }

  /// Whether Live Activities can be started right now.
  ///
  /// The user can turn them off for an app in Settings, and then a request
  /// fails rather than returning nothing. Returns `false` on Android and on
  /// iOS before 16.2.
  Future<bool> areLiveActivitiesEnabled() {
    throw UnimplementedError(
      'areLiveActivitiesEnabled() has not been implemented.',
    );
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
  Future<void> configureBackgroundUpdate({
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
  Future<void> cancelBackgroundUpdate(String widgetId) {
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
  Future<void> configureTimelineRefresh({
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
  Future<void> cancelTimelineRefresh(String widgetId) {
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
  Future<void> completeWidgetConfiguration(String widgetId) {
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
  Future<void> testBackgroundUpdate(String widgetId) {
    throw UnimplementedError(
      'testBackgroundUpdate() has not been implemented.',
    );
  }
}
