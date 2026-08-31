import 'package:glance_widget/src/glance_widget_controller.dart';
import 'package:glance_widget_platform_interface/glance_widget_platform_interface.dart';

/// A [GlanceWidgetController] pinned to the list template,
/// which renders a short list of items with optional checkboxes.
///
/// Using this instead of the generic form makes passing the wrong data
/// type a compile error rather than a runtime one.
class ListWidgetController extends GlanceWidgetController<ListWidgetData> {
  /// Creates a controller for the list widget identified by
  /// [widgetId], optionally pinned to [theme].
  ///
  /// ```dart
  /// final controller = ListWidgetController(widgetId: 'my_widget');
  /// await controller.update(ListWidgetData(title: 'Today', items: items));
  /// ```
  ListWidgetController({required super.widgetId, super.theme});
}
