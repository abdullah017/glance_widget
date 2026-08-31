import 'package:glance_widget/src/glance_widget_controller.dart';
import 'package:glance_widget_platform_interface/glance_widget_platform_interface.dart';

/// A [GlanceWidgetController] pinned to the calendar template,
/// which renders a date with its list of events.
///
/// Using this instead of the generic form makes passing the wrong data
/// type a compile error rather than a runtime one.
class CalendarWidgetController
    extends GlanceWidgetController<CalendarWidgetData> {
  /// Creates a controller for the calendar widget identified by
  /// [widgetId], optionally pinned to [theme].
  ///
  /// ```dart
  /// final controller = CalendarWidgetController(widgetId: 'my_widget');
  /// await controller.update(CalendarWidgetData(title: 'Today', date: now, events: events));
  /// ```
  CalendarWidgetController({required super.widgetId, super.theme});
}
