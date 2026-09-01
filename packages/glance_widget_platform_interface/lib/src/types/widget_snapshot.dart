import 'dart:convert';

import 'package:glance_widget_platform_interface/src/types/glance_exception.dart';
import 'package:glance_widget_platform_interface/src/types/map_reader.dart';
import 'package:glance_widget_platform_interface/src/types/widget_data.dart';
import 'package:glance_widget_platform_interface/src/types/widget_theme.dart';

/// What a widget is currently showing, as the plugin last pushed it.
///
/// This is the widget's own copy read back, not the app's memory of it. It
/// survives the app being killed, because the platform stored it next to the
/// data the widget draws from.
///
/// [data] is the sealed [WidgetData] that was sent, so a `switch` over it is
/// checked for exhaustiveness. [updatedAt] and [theme] are not part of that
/// data -- they belong to the envelope the plugin wraps around it -- which is
/// why the read returns this rather than a bare [WidgetData].
class GlanceWidgetSnapshot {
  /// Creates a snapshot of [widgetId] as it was written at [updatedAt].
  const GlanceWidgetSnapshot({
    required this.widgetId,
    required this.data,
    required this.updatedAt,
    this.theme,
  });

  /// Decodes the record the platform stored.
  ///
  /// Throws [GlanceWidgetFormatException] when [source] is not a record this
  /// version of the plugin understands -- which is a different answer from
  /// there being no record at all, and only the latter means the widget is
  /// safe to overwrite unseen.
  factory GlanceWidgetSnapshot.decode(String source) {
    final Object? decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException catch (e) {
      throw GlanceWidgetFormatException(
        'stored record is not JSON: ${e.message}',
      );
    }
    final reader = MapReader.of(decoded, '');
    final template = reader.enumByName('template', GlanceTemplate.values);
    final data = reader.child('data');
    if (data == null) {
      throw const GlanceWidgetFormatException(
        'stored record has no data',
        field: 'data',
      );
    }
    final theme = reader.child('theme');
    return GlanceWidgetSnapshot(
      widgetId: reader.requireString('widgetId'),
      data: WidgetData.fromMap(template, data.map),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        reader.requireInt('updatedAt'),
      ),
      theme: theme == null ? null : GlanceTheme.fromReader(theme),
    );
  }

  /// The id the app used when it wrote this widget.
  final String widgetId;

  /// The data the widget is drawing from.
  final WidgetData data;

  /// When the plugin last pushed this data.
  final DateTime updatedAt;

  /// The theme sent alongside the data, if one was.
  final GlanceTheme? theme;

  /// Which template [data] belongs to.
  GlanceTemplate get template => data.template;

  @override
  String toString() =>
      'GlanceWidgetSnapshot($widgetId, ${template.name}, $updatedAt)';
}
