import 'package:glance_widget_platform_interface/src/types/widget_data.dart';
import 'package:glance_widget_platform_interface/src/types/widget_theme.dart';

/// One widget's share of a batch update: which widget, and what to show.
///
/// [data] is a [WidgetData], which is sealed, so the template it belongs to is
/// carried by the value itself rather than by the method it was passed to.
/// That is what lets a batch mix templates -- a to-do list widget and a chart
/// widget can be refreshed in the same call.
class GlanceWidgetUpdate {
  /// Sends [data] to the widget identified by [widgetId].
  ///
  /// [theme] overrides the batch's theme for this widget alone. Leave it null
  /// to use whatever the batch was given, which is the common case and the
  /// reason the theme is not repeated per widget on the wire.
  const GlanceWidgetUpdate({
    required this.widgetId,
    required this.data,
    this.theme,
  });

  /// The widget instance this update is addressed to.
  final String widgetId;

  /// What that widget should show.
  final WidgetData data;

  /// A theme for this widget only, overriding the batch's.
  final GlanceTheme? theme;

  /// Checks the invariants that must hold before this update leaves Dart.
  void validate() {
    WidgetData.checkNotEmpty(widgetId, 'widgetId');
    data.validate();
  }

  /// Serialises this update for the platform channel.
  ///
  /// `template` is the discriminator the native side switches on. Without it a
  /// batch would need one list per template, and adding a template would mean
  /// changing the shape of the payload rather than adding a case.
  Map<String, Object?> toMap() => <String, Object?>{
    'widgetId': widgetId,
    'template': data.template.name,
    'data': data.toMap(),
    if (theme != null) 'theme': theme!.toMap(),
  };

  @override
  String toString() =>
      'GlanceWidgetUpdate(widgetId: $widgetId, template: ${data.template.name})';
}
