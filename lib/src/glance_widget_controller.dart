import 'dart:async';

import 'package:glance_widget_platform_interface/glance_widget_platform_interface.dart';
import 'package:logging/logging.dart';

/// Template types for Glance widgets.
enum GlanceTemplate {
  /// Simple widget with title, value, and subtitle.
  simple,

  /// Progress widget with circular or linear progress indicator.
  progress,

  /// List widget with scrollable items.
  list,
}

/// Controller for managing a single Glance widget instance.
///
/// Use this for more advanced control over a widget, including:
/// - Typed data updates
/// - Action event handling
/// - Theme management
///
/// Example:
/// ```dart
/// final controller = GlanceWidgetController(
///   widgetId: 'crypto_btc',
///   template: GlanceTemplate.simple,
/// );
///
/// // Update with new data
/// await controller.updateSimple(
///   SimpleWidgetData(
///     title: 'Bitcoin',
///     value: '\$94,532',
///     subtitle: '+2.34%',
///   ),
/// );
///
/// // Listen for taps
/// controller.onAction.listen((action) {
///   print('Widget tapped!');
/// });
///
/// // Don't forget to dispose
/// controller.dispose();
/// ```
class GlanceWidgetController {
  /// Logger for this class.
  static final _log = Logger('GlanceWidgetController');

  /// Creates a controller for a specific widget.
  ///
  /// - [widgetId]: Unique identifier for the widget
  /// - [template]: The template type for this widget
  /// - [theme]: Optional default theme for this widget
  GlanceWidgetController({
    required this.widgetId,
    required this.template,
    this.theme,
  }) {
    _setupActionListener();
  }

  /// The unique identifier for this widget.
  final String widgetId;

  /// The template type for this widget.
  final GlanceTemplate template;

  /// The default theme for this widget.
  GlanceTheme? theme;

  final _actionController = StreamController<GlanceWidgetAction>.broadcast();
  StreamSubscription<GlanceWidgetAction>? _subscription;

  void _setupActionListener() {
    _subscription = GlanceWidgetPlatform.instance.onWidgetAction.listen(
      (action) {
        if (action.widgetId == widgetId) {
          _actionController.add(action);
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        _log.warning(
          'Widget action stream error for widget $widgetId',
          error,
          stackTrace,
        );
        _actionController.addError(error, stackTrace);
      },
      onDone: () {
        _log.fine('Widget action stream closed for widget $widgetId');
      },
    );
  }

  /// Stream of action events for this specific widget.
  Stream<GlanceWidgetAction> get onAction => _actionController.stream;

  /// Updates a Simple widget with the given data.
  ///
  /// Throws [StateError] if this controller is not for a simple widget.
  Future<bool> updateSimple(SimpleWidgetData data) {
    if (template != GlanceTemplate.simple) {
      throw StateError(
        'Cannot update simple widget: controller is for ${template.name} template',
      );
    }
    return GlanceWidgetPlatform.instance.updateSimpleWidget(
      widgetId: widgetId,
      data: data,
      theme: theme,
    );
  }

  /// Updates a Progress widget with the given data.
  ///
  /// Throws [StateError] if this controller is not for a progress widget.
  Future<bool> updateProgress(ProgressWidgetData data) {
    if (template != GlanceTemplate.progress) {
      throw StateError(
        'Cannot update progress widget: controller is for ${template.name} template',
      );
    }
    return GlanceWidgetPlatform.instance.updateProgressWidget(
      widgetId: widgetId,
      data: data,
      theme: theme,
    );
  }

  /// Updates a List widget with the given data.
  ///
  /// Throws [StateError] if this controller is not for a list widget.
  Future<bool> updateList(ListWidgetData data) {
    if (template != GlanceTemplate.list) {
      throw StateError(
        'Cannot update list widget: controller is for ${template.name} template',
      );
    }
    return GlanceWidgetPlatform.instance.updateListWidget(
      widgetId: widgetId,
      data: data,
      theme: theme,
    );
  }

  /// Updates the theme for this widget.
  Future<void> setTheme(GlanceTheme newTheme) async {
    theme = newTheme;
    // Trigger a refresh with the new theme
    await GlanceWidgetPlatform.instance.forceRefreshAll();
  }

  /// Disposes of the controller and releases resources.
  void dispose() {
    _subscription?.cancel();
    _actionController.close();
  }
}
