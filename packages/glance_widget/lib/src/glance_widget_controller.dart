import 'dart:async';

import 'package:glance_widget/src/glance_config.dart';
import 'package:glance_widget_platform_interface/glance_widget_platform_interface.dart';

/// Generic controller for managing a single Glance widget instance.
///
/// Provides compile-time type safety — the wrong data type causes a
/// compilation error, not a runtime exception.
///
/// Use convenience subclasses for simpler construction:
/// ```dart
/// final ctrl = SimpleWidgetController(widgetId: 'btc');
/// await ctrl.update(SimpleWidgetData(title: 'BTC', value: '\$94k'));
/// ```
///
/// Or use the generic form directly:
/// ```dart
/// final ctrl = GlanceWidgetController<ChartWidgetData>(widgetId: 'chart1');
/// await ctrl.update(ChartWidgetData(title: 'Trend', dataPoints: [1, 2, 3]));
/// ```
class GlanceWidgetController<T extends WidgetData> {
  /// Creates a controller for a specific widget.
  ///
  /// No side effects in constructor — stream subscription is lazy.
  GlanceWidgetController({required this.widgetId, this.theme});

  /// The unique identifier for this widget.
  final String widgetId;

  /// The current theme for this widget (passed to platform on updates).
  GlanceTheme? theme;

  // Lazy initialization — no subscription until onAction is accessed
  StreamSubscription<GlanceWidgetAction>? _subscription;
  final _actionController = StreamController<GlanceWidgetAction>.broadcast();
  bool _disposed = false;

  /// Updates the widget with type-safe data.
  ///
  /// The wrong data type causes a COMPILATION ERROR:
  /// ```dart
  /// final ctrl = SimpleWidgetController(widgetId: 'test');
  /// ctrl.update(ProgressWidgetData(...)); // Won't compile!
  /// ```
  ///
  /// Completes once the platform has applied the update, and throws
  /// [GlanceWidgetException] when it could not. On a platform without home
  /// screen widgets this is a no-op.
  Future<void> update(T data) async {
    _assertNotDisposed();
    return PlatformGuard.guardVoid(() => _dispatchUpdate(data));
  }

  /// Stream of action events for this specific widget.
  ///
  /// Lazily subscribes to the global platform stream and filters by widgetId.
  /// Multiple controllers share a single native EventChannel subscription.
  Stream<GlanceWidgetAction> get onAction {
    _assertNotDisposed();
    _subscription ??= PlatformGuard.guardStream(
      () => GlanceWidgetPlatform.instance.onWidgetAction,
    )
        .where((action) => action.widgetId == widgetId)
        .listen(_actionController.add, onError: _actionController.addError);
    return _actionController.stream;
  }

  /// Updates the global theme and stores it locally for future updates.
  Future<void> setTheme(GlanceTheme newTheme) async {
    _assertNotDisposed();
    theme = newTheme;
    return PlatformGuard.guardVoid(
      () => GlanceWidgetPlatform.instance.setGlobalTheme(newTheme),
    );
  }

  /// Disposes of the controller and releases resources.
  ///
  /// After disposal, calling [update], [onAction], or [setTheme]
  /// throws [StateError].
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _subscription?.cancel();
    _actionController.close();
  }

  /// Dispatches the update to the correct platform method using
  /// sealed class pattern matching.
  Future<void> _dispatchUpdate(WidgetData data) {
    final platform = GlanceWidgetPlatform.instance;
    return switch (data) {
      SimpleWidgetData() => platform.updateSimpleWidget(
        widgetId: widgetId,
        data: data,
        theme: theme,
      ),
      ProgressWidgetData() => platform.updateProgressWidget(
        widgetId: widgetId,
        data: data,
        theme: theme,
      ),
      ListWidgetData() => platform.updateListWidget(
        widgetId: widgetId,
        data: data,
        theme: theme,
      ),
      ImageWidgetData() => platform.updateImageWidget(
        widgetId: widgetId,
        data: data,
        theme: theme,
      ),
      ChartWidgetData() => platform.updateChartWidget(
        widgetId: widgetId,
        data: data,
        theme: theme,
      ),
      CalendarWidgetData() => platform.updateCalendarWidget(
        widgetId: widgetId,
        data: data,
        theme: theme,
      ),
      GaugeWidgetData() => platform.updateGaugeWidget(
        widgetId: widgetId,
        data: data,
        theme: theme,
      ),
    };
  }

  void _assertNotDisposed() {
    if (_disposed) {
      throw StateError(
        'GlanceWidgetController<$T> for "$widgetId" has been disposed. '
        'Create a new controller or check your widget lifecycle.',
      );
    }
  }
}
