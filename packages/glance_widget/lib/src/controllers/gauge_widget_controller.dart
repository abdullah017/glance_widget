import 'package:glance_widget/src/glance_widget_controller.dart';
import 'package:glance_widget_platform_interface/glance_widget_platform_interface.dart';

/// A [GlanceWidgetController] pinned to the gauge template,
/// which renders radial or dashboard-style metrics.
///
/// Using this instead of the generic form makes passing the wrong data
/// type a compile error rather than a runtime one.
class GaugeWidgetController extends GlanceWidgetController<GaugeWidgetData> {
  /// Creates a controller for the gauge widget identified by
  /// [widgetId], optionally pinned to [theme].
  ///
  /// ```dart
  /// final controller = GaugeWidgetController(widgetId: 'my_widget');
  /// await controller.update(GaugeWidgetData(title: 'System', metrics: metrics));
  /// ```
  GaugeWidgetController({required super.widgetId, super.theme});
}
