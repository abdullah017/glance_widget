import 'package:glance_widget/src/glance_widget_controller.dart';
import 'package:glance_widget_platform_interface/glance_widget_platform_interface.dart';

/// A [GlanceWidgetController] pinned to the progress template,
/// which renders a circular or linear progress indicator.
///
/// Using this instead of the generic form makes passing the wrong data
/// type a compile error rather than a runtime one.
class ProgressWidgetController
    extends GlanceWidgetController<ProgressWidgetData> {
  /// Creates a controller for the progress widget identified by
  /// [widgetId], optionally pinned to [theme].
  ///
  /// ```dart
  /// final controller = ProgressWidgetController(widgetId: 'my_widget');
  /// await controller.update(ProgressWidgetData(title: 'Downloading', progress: 0.75));
  /// ```
  ProgressWidgetController({required super.widgetId, super.theme});
}
