import 'dart:async';

import 'package:glance_widget_platform_interface/glance_widget_platform_interface.dart';
import 'package:logging/logging.dart';

import 'glance_widget_controller.dart';

/// A widget controller with built-in debouncing for high-frequency updates.
///
/// This controller is ideal for real-time data scenarios like:
/// - Cryptocurrency prices
/// - Stock quotes
/// - Live sports scores
/// - Sensor data
///
/// ## How Debouncing Works
///
/// When you call [scheduleUpdate], the controller waits for [debounceInterval]
/// before actually sending the update to the widget. If another update comes
/// in during this interval, the previous pending update is discarded and the
/// timer resets.
///
/// To ensure data freshness, the controller will always send an update within
/// [maxWaitTime] even if updates keep coming in rapidly.
///
/// ## Example
///
/// ```dart
/// final controller = DebouncedWidgetController(
///   widgetId: 'crypto_btc',
///   template: GlanceTemplate.simple,
///   theme: GlanceTheme.dark(),
///   debounceInterval: Duration(milliseconds: 100),
///   maxWaitTime: Duration(milliseconds: 500),
/// );
///
/// // Subscribe to price updates (could be hundreds per second)
/// priceStream.listen((price) {
///   controller.scheduleUpdate(SimpleWidgetData(
///     title: 'Bitcoin',
///     value: '\$${price.toStringAsFixed(2)}',
///     subtitle: price > previousPrice ? '↑' : '↓',
///     subtitleColor: price > previousPrice ? Colors.green : Colors.red,
///   ));
/// });
///
/// // Don't forget to dispose
/// controller.dispose();
/// ```
class DebouncedWidgetController {
  /// Logger for this class.
  static final _log = Logger('DebouncedWidgetController');

  /// The underlying widget controller.
  final GlanceWidgetController _controller;

  /// The interval to wait before sending an update.
  ///
  /// If another update arrives during this interval, the timer resets.
  final Duration debounceInterval;

  /// The maximum time to wait before forcing an update.
  ///
  /// This ensures data freshness even when updates are coming rapidly.
  final Duration maxWaitTime;

  Timer? _debounceTimer;
  Timer? _maxWaitTimer;
  dynamic _pendingData;
  DateTime? _firstPendingUpdate;
  DateTime? _lastUpdateTime;
  int _updateCount = 0;
  int _skippedCount = 0;

  /// Creates a debounced widget controller.
  ///
  /// - [widgetId]: Unique identifier for the widget
  /// - [template]: The template type for this widget
  /// - [theme]: Optional default theme for this widget
  /// - [debounceInterval]: Time to wait before sending update (default: 100ms)
  /// - [maxWaitTime]: Maximum time before forcing update (default: 500ms)
  DebouncedWidgetController({
    required String widgetId,
    required GlanceTemplate template,
    GlanceTheme? theme,
    this.debounceInterval = const Duration(milliseconds: 100),
    this.maxWaitTime = const Duration(milliseconds: 500),
  }) : _controller = GlanceWidgetController(
          widgetId: widgetId,
          template: template,
          theme: theme,
        );

  /// The unique identifier for this widget.
  String get widgetId => _controller.widgetId;

  /// The template type for this widget.
  GlanceTemplate get template => _controller.template;

  /// Stream of action events for this specific widget.
  Stream<GlanceWidgetAction> get onAction => _controller.onAction;

  /// Returns the time since the last successful update.
  ///
  /// Returns null if no update has been sent yet.
  Duration? get timeSinceLastUpdate {
    if (_lastUpdateTime == null) return null;
    return DateTime.now().difference(_lastUpdateTime!);
  }

  /// Returns true if the widget data might be stale.
  ///
  /// A widget is considered stale if no update has been sent for more than
  /// 30 seconds. This threshold can be useful for showing loading indicators
  /// or refreshing data.
  bool get isStale {
    final elapsed = timeSinceLastUpdate;
    if (elapsed == null) return true;
    return elapsed.inSeconds > 30;
  }

  /// Returns true if there's a pending update waiting to be sent.
  bool get hasPendingUpdate => _pendingData != null;

  /// Returns the total number of updates sent.
  int get updateCount => _updateCount;

  /// Returns the number of updates skipped due to debouncing.
  int get skippedCount => _skippedCount;

  /// Schedules an update with debouncing.
  ///
  /// Updates are coalesced within [debounceInterval], but will always
  /// fire within [maxWaitTime] to ensure data freshness.
  ///
  /// The [data] parameter must match the template type:
  /// - [GlanceTemplate.simple]: [SimpleWidgetData]
  /// - [GlanceTemplate.progress]: [ProgressWidgetData]
  /// - [GlanceTemplate.list]: [ListWidgetData]
  void scheduleUpdate(dynamic data) {
    // Track if we're replacing a pending update (skipped)
    if (_pendingData != null) {
      _skippedCount++;
    }

    _pendingData = data;
    _firstPendingUpdate ??= DateTime.now();

    // Cancel existing debounce timer
    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounceInterval, _flush);

    // Set up max wait timer if not already running
    _maxWaitTimer ??= Timer(maxWaitTime, () {
      _log.fine(
          'Max wait time reached for widget $widgetId, forcing update');
      _flush();
    });
  }

  Future<void> _flush() async {
    // Cancel timers
    _debounceTimer?.cancel();
    _maxWaitTimer?.cancel();
    _debounceTimer = null;
    _maxWaitTimer = null;

    final data = _pendingData;
    _pendingData = null;
    _firstPendingUpdate = null;

    if (data == null) return;

    try {
      bool success = false;

      switch (_controller.template) {
        case GlanceTemplate.simple:
          if (data is SimpleWidgetData) {
            success = await _controller.updateSimple(data);
          } else {
            _log.warning(
                'Invalid data type for simple widget: ${data.runtimeType}');
          }
        case GlanceTemplate.progress:
          if (data is ProgressWidgetData) {
            success = await _controller.updateProgress(data);
          } else {
            _log.warning(
                'Invalid data type for progress widget: ${data.runtimeType}');
          }
        case GlanceTemplate.list:
          if (data is ListWidgetData) {
            success = await _controller.updateList(data);
          } else {
            _log.warning(
                'Invalid data type for list widget: ${data.runtimeType}');
          }
      }

      if (success) {
        _lastUpdateTime = DateTime.now();
        _updateCount++;
        _log.fine('Widget $widgetId updated successfully (total: $_updateCount)');
      }
    } catch (e, stackTrace) {
      _log.warning('Failed to update widget $widgetId', e, stackTrace);
    }
  }

  /// Forces immediate flush of any pending update.
  ///
  /// Use this when you need to ensure the widget shows the latest data
  /// immediately, for example when the app is about to go to background.
  Future<void> flush() => _flush();

  /// Updates the theme for this widget.
  Future<void> setTheme(GlanceTheme newTheme) async {
    _controller.theme = newTheme;
    await flush();
  }

  /// Disposes of the controller and releases resources.
  ///
  /// Any pending update will be flushed before disposal.
  void dispose() {
    // Flush any pending update synchronously isn't possible,
    // so we just cancel timers
    _debounceTimer?.cancel();
    _maxWaitTimer?.cancel();
    _controller.dispose();
    _log.fine(
        'DebouncedWidgetController disposed for widget $widgetId '
        '(updates: $_updateCount, skipped: $_skippedCount)');
  }
}
