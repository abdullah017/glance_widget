import 'dart:ui';

import 'package:glance_widget_platform_interface/glance_widget_platform_interface.dart';

/// Main class for creating and updating Glance widgets.
///
/// Provides static methods for quick widget updates and theme configuration.
///
/// ## Example
/// ```dart
/// // Simple widget for crypto price
/// await GlanceWidget.simple(
///   id: 'btc_price',
///   title: 'Bitcoin',
///   value: '\$94,532',
///   subtitle: '+2.34%',
///   subtitleColor: Colors.green,
/// );
///
/// // Progress widget for download
/// await GlanceWidget.progress(
///   id: 'download_1',
///   title: 'Downloading...',
///   progress: 0.75,
///   subtitle: '75% complete',
/// );
///
/// // List widget for todos
/// await GlanceWidget.list(
///   id: 'todo_list',
///   title: 'Today',
///   items: [
///     GlanceListItem(text: 'Buy groceries', checked: true),
///     GlanceListItem(text: 'Call mom'),
///   ],
///   showCheckboxes: true,
/// );
/// ```
class GlanceWidget {
  GlanceWidget._();

  static GlanceWidgetPlatform get _platform => GlanceWidgetPlatform.instance;

  /// Updates a Simple Widget with title, value, and optional subtitle.
  ///
  /// Perfect for displaying single values like:
  /// - Cryptocurrency prices
  /// - Weather temperature
  /// - Stock prices
  /// - Stats or metrics
  ///
  /// Parameters:
  /// - [id]: Unique identifier for this widget instance
  /// - [title]: The header text (e.g., "Bitcoin", "Temperature")
  /// - [value]: The main value to display (e.g., "\$94,532", "72°F")
  /// - [subtitle]: Optional secondary text (e.g., "+2.34%")
  /// - [subtitleColor]: Optional color for the subtitle
  /// - [iconName]: Optional predefined icon name
  /// - [theme]: Optional theme override for this widget
  ///
  /// Returns `true` if the widget was updated successfully.
  static Future<bool> simple({
    required String id,
    required String title,
    required String value,
    String? subtitle,
    Color? subtitleColor,
    String? iconName,
    String? deepLinkUri,
    GlanceTheme? theme,
  }) {
    return _platform.updateSimpleWidget(
      widgetId: id,
      data: SimpleWidgetData(
        title: title,
        value: value,
        subtitle: subtitle,
        subtitleColor: subtitleColor,
        iconName: iconName,
        deepLinkUri: deepLinkUri,
      ),
      theme: theme,
    );
  }

  /// Updates a Progress Widget with circular or linear progress indicator.
  ///
  /// Perfect for displaying progress like:
  /// - Download progress
  /// - Goal completion
  /// - Battery level
  /// - Task progress
  ///
  /// Parameters:
  /// - [id]: Unique identifier for this widget instance
  /// - [title]: The header text
  /// - [progress]: Progress value between 0.0 and 1.0
  /// - [subtitle]: Optional secondary text
  /// - [progressType]: Circular or linear progress indicator
  /// - [progressColor]: Optional color for the progress indicator
  /// - [trackColor]: Optional color for the progress track
  /// - [theme]: Optional theme override for this widget
  ///
  /// Returns `true` if the widget was updated successfully.
  static Future<bool> progress({
    required String id,
    required String title,
    required double progress,
    String? subtitle,
    ProgressType progressType = ProgressType.circular,
    Color? progressColor,
    Color? trackColor,
    String? deepLinkUri,
    GlanceTheme? theme,
  }) {
    return _platform.updateProgressWidget(
      widgetId: id,
      data: ProgressWidgetData(
        title: title,
        progress: progress,
        subtitle: subtitle,
        progressType: progressType,
        progressColor: progressColor,
        trackColor: trackColor,
        deepLinkUri: deepLinkUri,
      ),
      theme: theme,
    );
  }

  /// Updates a List Widget with scrollable items.
  ///
  /// Perfect for displaying lists like:
  /// - To-do items
  /// - News headlines
  /// - Recent activities
  /// - Quick notes
  ///
  /// Parameters:
  /// - [id]: Unique identifier for this widget instance
  /// - [title]: The header text
  /// - [items]: List of items to display
  /// - [showCheckboxes]: Whether to show checkboxes for items
  /// - [maxItems]: Maximum number of items to display (default: 5)
  /// - [theme]: Optional theme override for this widget
  ///
  /// Returns `true` if the widget was updated successfully.
  static Future<bool> list({
    required String id,
    required String title,
    required List<GlanceListItem> items,
    bool showCheckboxes = false,
    int maxItems = 5,
    String? deepLinkUri,
    GlanceTheme? theme,
  }) {
    return _platform.updateListWidget(
      widgetId: id,
      data: ListWidgetData(
        title: title,
        items: items,
        showCheckboxes: showCheckboxes,
        maxItems: maxItems,
        deepLinkUri: deepLinkUri,
      ),
      theme: theme,
    );
  }

  /// Updates an Image Widget with a title, image, and optional subtitle.
  ///
  /// Perfect for displaying images like:
  /// - Photo of the day
  /// - Album artwork
  /// - Weather icons
  /// - Product images
  ///
  /// Parameters:
  /// - [id]: Unique identifier for this widget instance
  /// - [title]: The header text
  /// - [imageUrl]: Optional URL to load the image from
  /// - [imageBase64]: Optional base64 encoded image
  /// - [subtitle]: Optional secondary text
  /// - [fit]: How the image should be fitted (default: cover)
  /// - [theme]: Optional theme override for this widget
  ///
  /// Returns `true` if the widget was updated successfully.
  static Future<bool> image({
    required String id,
    required String title,
    String? imageUrl,
    String? imageBase64,
    String? subtitle,
    ImageFit fit = ImageFit.cover,
    String? deepLinkUri,
    GlanceTheme? theme,
  }) {
    return _platform.updateImageWidget(
      widgetId: id,
      data: ImageWidgetData(
        title: title,
        imageUrl: imageUrl,
        imageBase64: imageBase64,
        subtitle: subtitle,
        fit: fit,
        deepLinkUri: deepLinkUri,
      ),
      theme: theme,
    );
  }

  /// Updates a Chart Widget with data point visualization.
  ///
  /// Perfect for displaying trends like:
  /// - Stock price history
  /// - Step count over time
  /// - Revenue trends
  /// - Temperature history
  ///
  /// Parameters:
  /// - [id]: Unique identifier for this widget instance
  /// - [title]: The header text
  /// - [dataPoints]: List of numeric values to visualize
  /// - [chartType]: Type of chart (line, bar, sparkline)
  /// - [color]: Optional chart color
  /// - [subtitle]: Optional secondary text
  /// - [theme]: Optional theme override for this widget
  ///
  /// Returns `true` if the widget was updated successfully.
  static Future<bool> chart({
    required String id,
    required String title,
    required List<double> dataPoints,
    ChartType chartType = ChartType.line,
    Color? color,
    String? subtitle,
    String? deepLinkUri,
    GlanceTheme? theme,
  }) {
    return _platform.updateChartWidget(
      widgetId: id,
      data: ChartWidgetData(
        title: title,
        dataPoints: dataPoints,
        chartType: chartType,
        color: color,
        subtitle: subtitle,
        deepLinkUri: deepLinkUri,
      ),
      theme: theme,
    );
  }

  /// Updates a Calendar Widget with events for a date.
  ///
  /// Perfect for displaying schedules like:
  /// - Today's meetings
  /// - Upcoming events
  /// - Class schedule
  /// - Reminders
  ///
  /// Parameters:
  /// - [id]: Unique identifier for this widget instance
  /// - [title]: The header text
  /// - [date]: The date to display
  /// - [events]: List of calendar events
  /// - [maxEvents]: Maximum events to show (default: 5, range: 1-10)
  /// - [theme]: Optional theme override for this widget
  ///
  /// Returns `true` if the widget was updated successfully.
  static Future<bool> calendar({
    required String id,
    required String title,
    required DateTime date,
    required List<CalendarEvent> events,
    int maxEvents = 5,
    String? deepLinkUri,
    GlanceTheme? theme,
  }) {
    return _platform.updateCalendarWidget(
      widgetId: id,
      data: CalendarWidgetData(
        title: title,
        date: date,
        events: events,
        maxEvents: maxEvents,
        deepLinkUri: deepLinkUri,
      ),
      theme: theme,
    );
  }

  /// Updates a Gauge Widget with metric values.
  ///
  /// Perfect for displaying metrics like:
  /// - CPU/memory usage
  /// - Speed gauge
  /// - Health metrics
  /// - Performance scores
  ///
  /// Parameters:
  /// - [id]: Unique identifier for this widget instance
  /// - [title]: The header text
  /// - [metrics]: List of gauge metrics to display
  /// - [gaugeType]: Radial or dashboard display (default: radial)
  /// - [theme]: Optional theme override for this widget
  ///
  /// Returns `true` if the widget was updated successfully.
  static Future<bool> gauge({
    required String id,
    required String title,
    required List<GaugeMetric> metrics,
    GaugeType gaugeType = GaugeType.radial,
    String? deepLinkUri,
    GlanceTheme? theme,
  }) {
    return _platform.updateGaugeWidget(
      widgetId: id,
      data: GaugeWidgetData(
        title: title,
        metrics: metrics,
        gaugeType: gaugeType,
        deepLinkUri: deepLinkUri,
      ),
      theme: theme,
    );
  }

  /// Sets the global theme for all widgets.
  ///
  /// This theme will be applied to all widgets that don't have a specific
  /// theme override.
  ///
  /// Example:
  /// ```dart
  /// await GlanceWidget.setTheme(GlanceTheme.dark());
  /// ```
  static Future<bool> setTheme(GlanceTheme theme) {
    return _platform.setGlobalTheme(theme);
  }

  /// Forces a refresh of all widgets.
  ///
  /// Useful when you need to ensure all widgets are updated immediately.
  static Future<bool> refreshAll() {
    return _platform.forceRefreshAll();
  }

  /// Gets the list of active widget IDs.
  ///
  /// Returns a list of widget IDs that are currently displayed on the
  /// home screen.
  static Future<List<String>> getActiveWidgetIds() {
    return _platform.getActiveWidgetIds();
  }

  /// Stream of widget action events.
  ///
  /// Listen to this stream to receive callbacks when users interact with
  /// widgets (taps, checkbox toggles, etc.)
  ///
  /// Example:
  /// ```dart
  /// GlanceWidget.onAction.listen((action) {
  ///   print('Widget ${action.widgetId} was ${action.type}');
  /// });
  /// ```
  static Stream<GlanceWidgetAction> get onAction => _platform.onWidgetAction;

  /// Gets the Widget Push Token for server-triggered updates (iOS 26+).
  ///
  /// This token can be sent to your server to trigger widget updates via APNs.
  /// When your server sends a push notification with `apns-push-type: widgets`,
  /// iOS will wake the widget and refresh it.
  ///
  /// Returns `null` on unsupported platforms (Android, iOS < 26) or if the
  /// token is not yet available.
  ///
  /// Example:
  /// ```dart
  /// final token = await GlanceWidget.getWidgetPushToken();
  /// if (token != null) {
  ///   await sendTokenToServer(token);
  /// }
  /// ```
  static Future<String?> getWidgetPushToken() {
    return _platform.getWidgetPushToken();
  }

  /// Checks if Widget Push Updates are supported on the current platform.
  ///
  /// Returns `true` on iOS 26+ where Widget Push Updates are available.
  /// Returns `false` on Android and older iOS versions.
  ///
  /// Use this to conditionally show UI or enable features that depend on
  /// server-triggered widget updates.
  ///
  /// Example:
  /// ```dart
  /// if (await GlanceWidget.isWidgetPushSupported()) {
  ///   final token = await GlanceWidget.getWidgetPushToken();
  ///   // Send token to server
  /// }
  /// ```
  static Future<bool> isWidgetPushSupported() {
    return _platform.isWidgetPushSupported();
  }

  /// Configures iOS timeline-based refresh for a widget.
  ///
  /// This allows iOS widgets to refresh periodically using WidgetKit's
  /// `.after(date)` timeline policy, even when the app is not in the foreground.
  ///
  /// **Note:** WidgetKit manages the actual refresh schedule and may delay
  /// refreshes to optimize battery life. The interval is a suggestion.
  ///
  /// On Android, this is a no-op — use [configureBackgroundUpdate] instead.
  ///
  /// Parameters:
  /// - [widgetId]: Unique identifier for the widget
  /// - [interval]: Suggested refresh interval (minimum 5 minutes)
  ///
  /// Example:
  /// ```dart
  /// await GlanceWidget.configureTimelineRefresh(
  ///   widgetId: 'weather',
  ///   interval: Duration(minutes: 30),
  /// );
  /// ```
  static Future<bool> configureTimelineRefresh({
    required String widgetId,
    Duration interval = const Duration(minutes: 30),
  }) {
    final intervalMinutes = interval.inMinutes < 5 ? 5 : interval.inMinutes;
    return _platform.configureTimelineRefresh(
      widgetId: widgetId,
      intervalMinutes: intervalMinutes,
    );
  }

  /// Cancels iOS timeline-based refresh for a widget.
  ///
  /// Reverts the widget to `.never` timeline policy, meaning it will only
  /// update when the app explicitly triggers a reload.
  ///
  /// On Android, this is a no-op.
  static Future<bool> cancelTimelineRefresh(String widgetId) {
    return _platform.cancelTimelineRefresh(widgetId);
  }

  /// Configures background updates for a widget.
  ///
  /// This allows widgets to update even when the app is closed by periodically
  /// fetching data from an API and updating the widget.
  ///
  /// **Note:** On Android, the minimum update interval is 15 minutes due to
  /// WorkManager constraints. This is a system limitation to preserve battery.
  /// For more frequent updates, use the app in the foreground with
  /// [DebouncedWidgetController].
  ///
  /// Parameters:
  /// - [widgetId]: Unique identifier for the widget
  /// - [template]: Widget template type (simple, progress, or list)
  /// - [apiUrl]: API endpoint URL to fetch data from
  /// - [headers]: Optional HTTP headers for API requests
  /// - [interval]: Update interval (minimum 15 minutes)
  /// - [title]: Widget title to display
  /// - [valuePath]: JSONPath expression to extract main value (e.g., "$.data.price")
  /// - [subtitlePath]: Optional JSONPath for subtitle
  /// - [valuePrefix]: Optional prefix for value (e.g., "$")
  /// - [valueSuffix]: Optional suffix for value (e.g., "%")
  ///
  /// Example:
  /// ```dart
  /// await GlanceWidget.configureBackgroundUpdate(
  ///   widgetId: 'crypto_btc',
  ///   template: GlanceTemplate.simple,
  ///   apiUrl: 'https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=usd',
  ///   interval: Duration(minutes: 15),
  ///   title: 'Bitcoin',
  ///   valuePath: r'$.bitcoin.usd',
  ///   valuePrefix: r'$',
  /// );
  /// ```
  ///
  /// Returns `true` if background updates were configured successfully.
  static Future<bool> configureBackgroundUpdate({
    required String widgetId,
    required GlanceTemplate template,
    required String apiUrl,
    Map<String, String>? headers,
    Duration interval = const Duration(minutes: 15),
    required String title,
    required String valuePath,
    String? subtitlePath,
    String? valuePrefix,
    String? valueSuffix,
  }) {
    // Ensure minimum interval of 15 minutes
    final intervalMinutes = interval.inMinutes < 15 ? 15 : interval.inMinutes;

    return _platform.configureBackgroundUpdate(
      widgetId: widgetId,
      template: template.name,
      apiUrl: apiUrl,
      headers: headers ?? {},
      intervalMinutes: intervalMinutes,
      title: title,
      valuePath: valuePath,
      subtitlePath: subtitlePath,
      valuePrefix: valuePrefix,
      valueSuffix: valueSuffix,
    );
  }

  /// Cancels background updates for a widget.
  ///
  /// Stops the periodic background update task for the specified widget.
  /// The widget will retain its last data but will no longer update automatically.
  ///
  /// Example:
  /// ```dart
  /// await GlanceWidget.cancelBackgroundUpdate('crypto_btc');
  /// ```
  ///
  /// Returns `true` if background updates were cancelled successfully.
  static Future<bool> cancelBackgroundUpdate(String widgetId) {
    return _platform.cancelBackgroundUpdate(widgetId);
  }

  /// Gets the status of background updates for a widget.
  ///
  /// Returns a map containing:
  /// - `widgetId`: The widget identifier
  /// - `isConfigured`: Whether background updates are configured
  /// - `isEnabled`: Whether background updates are enabled
  /// - `intervalMinutes`: Update interval in minutes
  /// - `workState`: Current work state (ENQUEUED, RUNNING, NOT_SCHEDULED)
  /// - `apiUrl`: The configured API URL
  ///
  /// Example:
  /// ```dart
  /// final status = await GlanceWidget.getBackgroundUpdateStatus('crypto_btc');
  /// if (status['isConfigured'] == true) {
  ///   print('Background updates are active');
  ///   print('Next update state: ${status['workState']}');
  /// }
  /// ```
  static Future<Map<String, dynamic>> getBackgroundUpdateStatus(
    String widgetId,
  ) {
    return _platform.getBackgroundUpdateStatus(widgetId);
  }

  /// Marks widget configuration as complete.
  ///
  /// Call this after the user has finished configuring a newly added widget.
  /// The `onAction` stream will emit a `configure` action when a widget
  /// needs configuration. After presenting a configuration UI to the user,
  /// call this method to finalize the widget placement.
  ///
  /// Example:
  /// ```dart
  /// GlanceWidget.onAction.listen((action) {
  ///   if (action.type == GlanceActionType.configure) {
  ///     // Show configuration UI
  ///     showWidgetConfig(action.widgetId).then((_) {
  ///       GlanceWidget.completeWidgetConfiguration(action.widgetId);
  ///     });
  ///   }
  /// });
  /// ```
  static Future<bool> completeWidgetConfiguration(String widgetId) {
    return _platform.completeWidgetConfiguration(widgetId);
  }

  /// Triggers a one-time background update immediately (for testing).
  ///
  /// This bypasses the 15-minute minimum interval and runs the background
  /// worker immediately. Useful for testing without waiting.
  ///
  /// **Note:** Background updates must be configured first using
  /// [configureBackgroundUpdate].
  ///
  /// Example:
  /// ```dart
  /// // First enable background updates
  /// await GlanceWidget.configureBackgroundUpdate(
  ///   widgetId: 'crypto_btc',
  ///   ...
  /// );
  ///
  /// // Then test immediately
  /// await GlanceWidget.testBackgroundUpdate('crypto_btc');
  /// ```
  ///
  /// Returns `true` if the test was triggered successfully.
  static Future<bool> testBackgroundUpdate(String widgetId) {
    return _platform.testBackgroundUpdate(widgetId);
  }
}
