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
    GlanceTheme? theme,
  }) {
    return _platform.updateListWidget(
      widgetId: id,
      data: ListWidgetData(
        title: title,
        items: items,
        showCheckboxes: showCheckboxes,
        maxItems: maxItems,
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
}
