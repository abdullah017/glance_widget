import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:glance_widget_platform_interface/glance_widget_platform_interface.dart';
import 'package:logging/logging.dart';

import 'glance_widget_controller.dart';

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
class DebouncedWidgetController<T extends WidgetData> {
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

  /// The widget ID this controller manages.
  String get widgetId => _innerController.widgetId;

  /// Number of updates actually dispatched to the platform.
  int get updateCount => _updateCount;

  /// Number of updates that were coalesced (skipped).
  int get skippedCount => _skippedCount;

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
    _debounceTimer = Timer(debounceInterval, _flush);

    _maxWaitTimer ??= Timer(maxWaitTime, _flush);
  }

  /// Forces immediate dispatch of any pending update.
  Future<void> flush() async => _flush();

  /// Updates the global theme and flushes any pending data.
  Future<bool> setTheme(GlanceTheme theme) async {
    final result = await _innerController.setTheme(theme);
    if (_pendingData != null) await _flush();
    return result;
  }

  /// Stream of action events for this widget.
  Stream<GlanceWidgetAction> get onAction => _innerController.onAction;

  /// Disposes all resources: timers, lifecycle listener, inner controller.
  void dispose() {
    _debounceTimer?.cancel();
    _maxWaitTimer?.cancel();
    _lifecycleListener.dispose();
    _innerController.dispose();
    _log.fine(
      'DebouncedWidgetController[$widgetId] disposed. '
      'Updates: $_updateCount, Skipped: $_skippedCount',
    );
  }

  void _handleLifecycleChange(AppLifecycleState state) {
    // Flush pending data when app goes to background
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      if (_pendingData != null) {
        _flush();
      }
    }
  }

  Future<void> _flush() async {
    _debounceTimer?.cancel();
    _maxWaitTimer?.cancel();
    _maxWaitTimer = null;

    final data = _pendingData;
    if (data != null) {
      _pendingData = null;
      await _innerController.update(data);
      _lastUpdateTime = DateTime.now();
      _updateCount++;
    }
  }
}
