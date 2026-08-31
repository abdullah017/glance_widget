import 'dart:ui';

import 'package:glance_widget/src/glance_config.dart';
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
///
/// ## Error contract
///
/// Update methods return `Future<void>`: they either apply the change or throw
/// [GlanceWidgetException] describing why the platform refused. There is no
/// success flag to forget to check.
///
/// ```dart
/// try {
///   await GlanceWidget.simple(id: 'btc', title: 'Bitcoin', value: r'$94,532');
/// } on GlanceWidgetException catch (e) {
///   debugPrint('widget update failed: ${e.message}');
/// }
/// ```
///
/// On platforms without home screen widgets every call is a silent no-op --
/// see [isSupported].
class GlanceWidget {
  GlanceWidget._();

  static GlanceWidgetPlatform get _platform => GlanceWidgetPlatform.instance;

  /// Whether the current platform has a home screen widget system.
  ///
  /// `true` on Android and iOS. Everywhere else every call below is a no-op
  /// that completes normally, so shared code does not need `if (Platform.isX)`
  /// branches -- but a UI that offers "add a widget" should hide itself:
  ///
  /// ```dart
  /// if (GlanceWidget.isSupported) AddWidgetButton(),
  /// ```
  static bool get isSupported => GlanceConfig.isSupported;

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
  /// Throws [GlanceWidgetException] if the platform could not apply the
  /// update. Does nothing on platforms without home screen widgets.
  static Future<void> simple({
    required String id,
    required String title,
    required String value,
    String? subtitle,
    Color? subtitleColor,
    String? iconName,
    String? deepLinkUri,
    GlanceTheme? theme,
  }) {
    return PlatformGuard.guardVoid(
      () => _platform.updateSimpleWidget(
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
      ),
    );
  }

  /// Updates many widgets, of any mix of templates, in one platform call.
  ///
  /// The per-template helpers each cross the method channel once. Refreshing a
  /// dashboard of twenty widgets that way costs twenty round trips and
  /// serialises the shared theme twenty times; this costs one and sends the
  /// theme once.
  ///
  /// ```dart
  /// await GlanceWidget.batch(
  ///   [
  ///     GlanceWidgetUpdate(
  ///       widgetId: 'btc',
  ///       data: SimpleWidgetData(title: 'Bitcoin', value: r'$94,532'),
  ///     ),
  ///     GlanceWidgetUpdate(
  ///       widgetId: 'goal',
  ///       data: ProgressWidgetData(title: 'Steps', progress: 0.72),
  ///     ),
  ///   ],
  ///   theme: GlanceTheme.dark(),
  /// );
  /// ```
  ///
  /// [theme] applies to every update that does not carry one of its own.
  ///
  /// Every update is attempted. If some fail -- a widget with no instance on
  /// the home screen, say -- the ones that succeeded stay applied and a
  /// [GlanceWidgetBatchException] names the rest. A [GlanceWidgetException] is
  /// thrown if the call failed as a whole, and a
  /// [GlanceWidgetValidationException] if any update is malformed, in which
  /// case nothing is sent at all. Does nothing on platforms without home
  /// screen widgets.
  static Future<void> batch(
    List<GlanceWidgetUpdate> updates, {
    GlanceTheme? theme,
  }) {
    return PlatformGuard.guardVoid(
      () => _platform.updateBatch(updates, theme: theme),
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
  /// Throws [GlanceWidgetException] if the platform could not apply the
  /// update. Does nothing on platforms without home screen widgets.
  static Future<void> progress({
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
    return PlatformGuard.guardVoid(
      () => _platform.updateProgressWidget(
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
      ),
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
  /// Throws [GlanceWidgetException] if the platform could not apply the
  /// update. Does nothing on platforms without home screen widgets.
  static Future<void> list({
    required String id,
    required String title,
    required List<GlanceListItem> items,
    bool showCheckboxes = false,
    int maxItems = 5,
    String? deepLinkUri,
    GlanceTheme? theme,
  }) {
    return PlatformGuard.guardVoid(
      () => _platform.updateListWidget(
        widgetId: id,
        data: ListWidgetData(
          title: title,
          items: items,
          showCheckboxes: showCheckboxes,
          maxItems: maxItems,
          deepLinkUri: deepLinkUri,
        ),
        theme: theme,
      ),
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
  /// Throws [GlanceWidgetException] if the platform could not apply the
  /// update. Does nothing on platforms without home screen widgets.
  static Future<void> image({
    required String id,
    required String title,
    String? imageUrl,
    String? imageBase64,
    String? subtitle,
    ImageFit fit = ImageFit.cover,
    String? deepLinkUri,
    GlanceTheme? theme,
  }) {
    return PlatformGuard.guardVoid(
      () => _platform.updateImageWidget(
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
      ),
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
  /// Throws [GlanceWidgetException] if the platform could not apply the
  /// update. Does nothing on platforms without home screen widgets.
  static Future<void> chart({
    required String id,
    required String title,
    required List<double> dataPoints,
    ChartType chartType = ChartType.line,
    Color? color,
    String? subtitle,
    String? deepLinkUri,
    GlanceTheme? theme,
  }) {
    return PlatformGuard.guardVoid(
      () => _platform.updateChartWidget(
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
      ),
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
  /// Throws [GlanceWidgetException] if the platform could not apply the
  /// update. Does nothing on platforms without home screen widgets.
  static Future<void> calendar({
    required String id,
    required String title,
    required DateTime date,
    required List<CalendarEvent> events,
    int maxEvents = 5,
    String? deepLinkUri,
    GlanceTheme? theme,
  }) {
    return PlatformGuard.guardVoid(
      () => _platform.updateCalendarWidget(
        widgetId: id,
        data: CalendarWidgetData(
          title: title,
          date: date,
          events: events,
          maxEvents: maxEvents,
          deepLinkUri: deepLinkUri,
        ),
        theme: theme,
      ),
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
  /// Throws [GlanceWidgetException] if the platform could not apply the
  /// update. Does nothing on platforms without home screen widgets.
  static Future<void> gauge({
    required String id,
    required String title,
    required List<GaugeMetric> metrics,
    GaugeType gaugeType = GaugeType.radial,
    String? deepLinkUri,
    GlanceTheme? theme,
  }) {
    return PlatformGuard.guardVoid(
      () => _platform.updateGaugeWidget(
        widgetId: id,
        data: GaugeWidgetData(
          title: title,
          metrics: metrics,
          gaugeType: gaugeType,
          deepLinkUri: deepLinkUri,
        ),
        theme: theme,
      ),
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
  static Future<void> setTheme(GlanceTheme theme) {
    return PlatformGuard.guardVoid(() => _platform.setGlobalTheme(theme));
  }

  /// Forces a refresh of all widgets.
  ///
  /// Useful when you need to ensure all widgets are updated immediately.
  static Future<void> refreshAll() {
    return PlatformGuard.guardVoid(() => _platform.forceRefreshAll());
  }

  /// The widget ids this app has data stored for, in ascending order.
  ///
  /// **Not** the ids currently on the home screen -- neither platform can
  /// answer that. An id appears here as soon as the app writes to it, whether
  /// or not a widget carrying it has been placed, because the data is there
  /// waiting for one.
  ///
  /// What removes an id differs by platform, and it is worth knowing which you
  /// are relying on:
  ///
  /// * **Android** drops it by itself. Removing the last widget carrying an id
  ///   from the home screen runs `onDelete`, which deletes the cached image and
  ///   forgets the id. A second widget with the same id keeps both alive.
  /// * **iOS** never drops it on its own. WidgetKit does not tell an extension
  ///   its widget was removed, so nothing observes it happening; call
  ///   [forgetWidget] when your app knows an id is finished.
  ///
  /// Before v2.0.0 this returned every id the app had ever written, on both
  /// platforms, in a nondeterministic order. See #13.
  static Future<List<String>> getActiveWidgetIds() {
    return PlatformGuard.guard(
      () => _platform.getActiveWidgetIds(),
      <String>[],
    );
  }

  /// Drops everything stored for [widgetId].
  ///
  /// The payload, the downsampled image on disk, and the id itself. Use it
  /// when an id is finished -- a tracked parcel that arrived, a watchlist entry
  /// the user deleted -- so its data does not sit in the App Group forever.
  ///
  /// This does not remove a widget from the home screen; no API on either
  /// platform can. A placed widget still carrying [widgetId] will render its
  /// placeholder afterwards, because there is nothing left for it to read.
  ///
  /// On Android this is also what a removed widget triggers by itself, so
  /// calling it by hand is only needed for an id whose widget was never placed
  /// or is deliberately being reset. On iOS it is the only way an id is ever
  /// dropped.
  static Future<void> forgetWidget(String widgetId) {
    return PlatformGuard.guardVoid(() => _platform.forgetWidget(widgetId));
  }

  /// Starts a Live Activity: the Lock Screen card and, on a device that has
  /// one, the Dynamic Island.
  ///
  /// [activityId] is your own name for it. ActivityKit assigns an id you never
  /// see, and this is what [updateLiveActivity] and [endLiveActivity] use to
  /// find the activity again -- so it has to be an id your app can reproduce
  /// later, not a random one.
  ///
  /// ```dart
  /// if (await GlanceWidget.areLiveActivitiesEnabled()) {
  ///   await GlanceWidget.startLiveActivity(
  ///     activityId: 'delivery-42',
  ///     content: const LiveActivityContent(
  ///       title: 'Order on its way',
  ///       status: '12 min away',
  ///       progress: 0.4,
  ///       stats: {'Driver': 'Sam', 'Items': '3'},
  ///     ),
  ///   );
  /// }
  /// ```
  ///
  /// iOS 16.2+ only. **Android throws [UnsupportedError]** -- its nearest
  /// equivalent, Android 16's Live Updates, is a notification rather than a
  /// widget, and pretending otherwise would leave a caller believing something
  /// is on screen. Guard with [areLiveActivitiesEnabled], which answers `false`
  /// there rather than throwing.
  ///
  /// Your app needs `NSSupportsLiveActivities` in its `Info.plist` and a copy
  /// of `GlanceLiveActivityWidget.swift` in its widget extension; see
  /// WIDGET_SETUP.md.
  static Future<void> startLiveActivity({
    required String activityId,
    required LiveActivityContent content,
  }) {
    return PlatformGuard.guardVoid(
      () =>
          _platform.startLiveActivity(activityId: activityId, content: content),
    );
  }

  /// Replaces what a running Live Activity shows.
  ///
  /// Throws a [GlanceWidgetException] if no activity is running under
  /// [activityId] -- it may have been ended, or dismissed by the user, or the
  /// app may have been relaunched since it started. An activity outlives the
  /// process that requested it, and the plugin finds it again by
  /// [activityId] rather than by anything held in memory.
  static Future<void> updateLiveActivity({
    required String activityId,
    required LiveActivityContent content,
  }) {
    return PlatformGuard.guardVoid(
      () => _platform.updateLiveActivity(
        activityId: activityId,
        content: content,
      ),
    );
  }

  /// Ends a running Live Activity.
  ///
  /// [content] becomes its final state -- "Delivered" rather than a frozen "12
  /// min away". With [LiveActivityDismissal.standard] the card stays readable
  /// for a while afterwards, which is the point of passing one.
  static Future<void> endLiveActivity({
    required String activityId,
    LiveActivityContent? content,
    LiveActivityDismissal dismissal = LiveActivityDismissal.standard,
  }) {
    return PlatformGuard.guardVoid(
      () => _platform.endLiveActivity(
        activityId: activityId,
        content: content,
        dismissal: dismissal,
      ),
    );
  }

  /// Whether the activity started under [activityId] is still running.
  ///
  /// An activity outlives the app that started it -- it stays on the Lock
  /// Screen across a relaunch, and the user can dismiss it without the app
  /// hearing about it. So an app that resumes with work still in flight asks
  /// this rather than remembering: it is the difference between calling
  /// [updateLiveActivity] and calling [startLiveActivity].
  ///
  /// `false` on every platform that has no Live Activities.
  static Future<bool> isLiveActivityRunning(String activityId) {
    return PlatformGuard.guard(
      () => _platform.isLiveActivityRunning(activityId),
      false,
    );
  }

  /// Whether a Live Activity can be started right now.
  ///
  /// `false` when the user has turned Live Activities off for your app in
  /// Settings, on iOS before 16.2, and on every platform that has no Live
  /// Activities at all. This is the call to branch on: the three above throw
  /// on Android rather than doing nothing quietly.
  static Future<bool> areLiveActivitiesEnabled() {
    return PlatformGuard.guard(
      () => _platform.areLiveActivitiesEnabled(),
      false,
    );
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
  static Stream<GlanceWidgetAction> get onAction =>
      PlatformGuard.guardStream(() => _platform.onWidgetAction);

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
    return PlatformGuard.guard(() => _platform.getWidgetPushToken(), null);
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
    return PlatformGuard.guard(() => _platform.isWidgetPushSupported(), false);
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
  static Future<void> completeWidgetConfiguration(String widgetId) {
    return PlatformGuard.guardVoid(
      () => _platform.completeWidgetConfiguration(widgetId),
    );
  }
}
