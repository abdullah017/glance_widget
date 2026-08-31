import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:glance_widget/src/glance_widget_controller.dart';
import 'package:glance_widget_platform_interface/glance_widget_platform_interface.dart';
import 'package:logging/logging.dart';

/// Controller that debounces rapid widget updates for real-time data.
///
/// Use this when updating widgets with high-frequency data (crypto prices,
/// live scores, etc.) to avoid overwhelming the platform channel.
///
/// ```dart
/// final ctrl = DebouncedWidgetController<SimpleWidgetData>(
///   widgetId: 'crypto_btc',
///   debounceInterval: Duration(milliseconds: 200),
///   stalenessThreshold: Duration(seconds: 15),
/// );
///
/// // Call as often as needed — updates are coalesced
/// ctrl.scheduleUpdate(SimpleWidgetData(title: 'BTC', value: '\$94k'));
/// ```
///
/// ## Where failures surface
///
/// [scheduleUpdate] returns before the dispatch happens, so it cannot report a
/// failure to its caller. Dispatches triggered by the debounce timer, the max
/// wait timer, or the app going to the background therefore report through
/// [errors] instead; a dispatch you asked for with [flush] throws to you
/// directly. Either way a failed dispatch is never counted in [updateCount]
/// and never advances [timeSinceLastUpdate].
///
/// ```dart
/// ctrl.errors.listen((e) => debugPrint('widget update failed: $e'));
/// ```
class DebouncedWidgetController<T extends WidgetData> {
  /// Creates a debouncing controller for the widget identified by
  /// [widgetId], optionally pinned to [theme].
  ///
  /// Updates scheduled within [debounceInterval] of each other are
  /// coalesced into one dispatch. [maxWaitTime] bounds how long a
  /// continuously-updating stream can defer a dispatch, and
  /// [stalenessThreshold] is the age after which [isStale] reports true.
  DebouncedWidgetController({
    required String widgetId,
    GlanceTheme? theme,
    this.debounceInterval = const Duration(milliseconds: 100),
    this.maxWaitTime = const Duration(milliseconds: 500),
    this.stalenessThreshold = const Duration(seconds: 30),
  }) : _innerController = GlanceWidgetController<T>(
         widgetId: widgetId,
         theme: theme,
       ) {
    _lifecycleListener = AppLifecycleListener(
      onStateChange: _handleLifecycleChange,
    );
  }

  static final _log = Logger('GlanceWidget.DebouncedController');

  final GlanceWidgetController<T> _innerController;

  /// Minimum time between dispatched updates.
  final Duration debounceInterval;

  /// Maximum time to wait before forcing an update dispatch.
  final Duration maxWaitTime;

  /// Duration after which [isStale] returns true.
  final Duration stalenessThreshold;

  late final AppLifecycleListener _lifecycleListener;
  T? _pendingData;
  Timer? _debounceTimer;
  Timer? _maxWaitTimer;
  DateTime? _lastUpdateTime;
  int _updateCount = 0;
  int _skippedCount = 0;
  int _failedCount = 0;
  Object? _lastError;
  bool _disposed = false;

  /// Serialises dispatches: a timer may fire while an earlier dispatch is
  /// still in flight, and two concurrent writes could land out of order.
  Future<void> _inFlight = Future<void>.value();

  final _errorController = StreamController<Object>.broadcast();

  /// The widget ID this controller manages.
  String get widgetId => _innerController.widgetId;

  /// Number of updates actually dispatched to the platform.
  int get updateCount => _updateCount;

  /// Number of updates that were coalesced (skipped).
  int get skippedCount => _skippedCount;

  /// Number of dispatches the platform rejected.
  int get failedCount => _failedCount;

  /// The most recent dispatch failure, or `null` if none has occurred.
  Object? get lastError => _lastError;

  /// Failures from dispatches nobody is awaiting -- debounce timer, max wait
  /// timer, or the app-backgrounded flush.
  ///
  /// A broadcast stream: it is safe to listen late or not at all, though not
  /// listening means those failures are only visible through [failedCount] and
  /// [lastError].
  Stream<Object> get errors => _errorController.stream;

  /// Whether an update is waiting to be dispatched.
  bool get hasPendingUpdate => _pendingData != null;

  /// Duration since the last successful update dispatch.
  Duration? get timeSinceLastUpdate => _lastUpdateTime != null
      ? DateTime.now().difference(_lastUpdateTime!)
      : null;

  /// Whether the widget data is stale (no update within [stalenessThreshold]).
  bool get isStale {
    if (_lastUpdateTime == null) return true;
    return DateTime.now().difference(_lastUpdateTime!) > stalenessThreshold;
  }

  /// Schedules a widget update with debouncing.
  ///
  /// If called multiple times within [debounceInterval], only the last
  /// data is dispatched. If [maxWaitTime] is exceeded, forces dispatch.
  void scheduleUpdate(T data) {
    // Only count as skipped if we're replacing a pending update
    if (_pendingData != null) {
      _skippedCount++;
    }
    _pendingData = data;

    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounceInterval, _flushFromTimer);

    _maxWaitTimer ??= Timer(maxWaitTime, _flushFromTimer);
  }

  void _flushFromTimer() => unawaited(_flush(reportToStream: true));

  /// Forces immediate dispatch of any pending update.
  ///
  /// Throws [GlanceWidgetException] if the platform rejects the dispatch --
  /// the failure goes to you, not to [errors], because you are awaiting it.
  Future<void> flush() => _flush(reportToStream: false);

  /// Updates the global theme and flushes any pending data.
  ///
  /// Throws [GlanceWidgetException] if either the theme change or the flushed
  /// update is rejected.
  Future<void> setTheme(GlanceTheme theme) async {
    await _innerController.setTheme(theme);
    if (_pendingData != null) await _flush(reportToStream: false);
  }

  /// Stream of action events for this widget.
  Stream<GlanceWidgetAction> get onAction => _innerController.onAction;

  /// Disposes all resources: timers, lifecycle listener, inner controller.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _debounceTimer?.cancel();
    _maxWaitTimer?.cancel();
    _lifecycleListener.dispose();
    _innerController.dispose();
    _errorController.close();
    _log.fine(
      'DebouncedWidgetController[$widgetId] disposed. '
      'Updates: $_updateCount, Skipped: $_skippedCount, Failed: $_failedCount',
    );
  }

  void _handleLifecycleChange(AppLifecycleState state) {
    // Flush pending data when app goes to background
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      if (_pendingData != null) {
        unawaited(_flush(reportToStream: true));
      }
    }
  }

  /// Dispatches the pending update, if any.
  ///
  /// [reportToStream] decides where a failure goes: `true` for dispatches
  /// nobody awaits (timers, lifecycle), `false` when a caller is awaiting the
  /// returned future and should see the exception itself. Rethrowing from a
  /// timer callback would surface as an unhandled zone error instead.
  Future<void> _flush({required bool reportToStream}) {
    _debounceTimer?.cancel();
    _maxWaitTimer?.cancel();
    _maxWaitTimer = null;

    final data = _pendingData;
    if (data == null) return _inFlight;
    _pendingData = null;

    final dispatch = _inFlight.then((_) => _dispatch(data, reportToStream));
    // Keep the chain alive for the next dispatch even if this one fails, but
    // do not let that bookkeeping future look unhandled to the zone.
    _inFlight = dispatch.then((_) {}, onError: (Object _) {});
    return dispatch;
  }

  Future<void> _dispatch(T data, bool reportToStream) async {
    try {
      await _innerController.update(data);
    } catch (error) {
      _failedCount++;
      _lastError = error;
      _log.warning('DebouncedWidgetController[$widgetId] update failed', error);
      if (!reportToStream) rethrow;
      if (!_errorController.isClosed) _errorController.add(error);
      return;
    }
    _lastUpdateTime = DateTime.now();
    _updateCount++;
  }
}
