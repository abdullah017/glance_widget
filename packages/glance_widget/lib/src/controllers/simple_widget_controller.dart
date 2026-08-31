import 'package:glance_widget/src/glance_widget_controller.dart';
import 'package:glance_widget_platform_interface/glance_widget_platform_interface.dart';

/// A [GlanceWidgetController] pinned to the simple template,
/// which renders a title, a value and an optional subtitle.
///
/// Using this instead of the generic form makes passing the wrong data
/// type a compile error rather than a runtime one.
class SimpleWidgetController extends GlanceWidgetController<SimpleWidgetData> {
  /// Creates a controller for the simple widget identified by
  /// [widgetId], optionally pinned to [theme].
  ///
  /// ```dart
  /// final controller = SimpleWidgetController(widgetId: 'my_widget');
  /// await controller.update(SimpleWidgetData(title: 'Bitcoin', value: r'\$94,532'));
  /// ```
  SimpleWidgetController({required super.widgetId, super.theme});
}
