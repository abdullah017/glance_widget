import 'package:glance_widget/src/glance_widget_controller.dart';
import 'package:glance_widget_platform_interface/glance_widget_platform_interface.dart';

/// A [GlanceWidgetController] pinned to the image template,
/// which renders an image with a title and optional subtitle.
///
/// Using this instead of the generic form makes passing the wrong data
/// type a compile error rather than a runtime one.
class ImageWidgetController extends GlanceWidgetController<ImageWidgetData> {
  /// Creates a controller for the image widget identified by
  /// [widgetId], optionally pinned to [theme].
  ///
  /// ```dart
  /// final controller = ImageWidgetController(widgetId: 'my_widget');
  /// await controller.update(ImageWidgetData(title: 'Photo', imageUrl: url));
  /// ```
  ImageWidgetController({required super.widgetId, super.theme});
}
