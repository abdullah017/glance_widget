import 'package:glance_widget/src/glance_widget_controller.dart';
import 'package:glance_widget_platform_interface/glance_widget_platform_interface.dart';

/// A [GlanceWidgetController] pinned to the chart template,
/// which renders a line, bar or sparkline visualisation.
///
/// Using this instead of the generic form makes passing the wrong data
/// type a compile error rather than a runtime one.
class ChartWidgetController extends GlanceWidgetController<ChartWidgetData> {
  /// Creates a controller for the chart widget identified by
  /// [widgetId], optionally pinned to [theme].
  ///
  /// ```dart
  /// final controller = ChartWidgetController(widgetId: 'my_widget');
  /// await controller.update(ChartWidgetData(title: 'Revenue', dataPoints: points));
  /// ```
  ChartWidgetController({required super.widgetId, super.theme});
}
