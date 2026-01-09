/// Android implementation of the glance_widget plugin.
library;

import 'package:glance_widget_platform_interface/glance_widget_platform_interface.dart';

/// The Android implementation of [GlanceWidgetPlatform].
///
/// This class implements the `package:glance_widget` functionality for Android
/// using Jetpack Glance.
class GlanceWidgetAndroid extends GlanceWidgetPlatform {
  /// Registers this class as the default instance of [GlanceWidgetPlatform].
  static void registerWith() {
    GlanceWidgetPlatform.instance = GlanceWidgetAndroid();
  }

  final MethodChannelGlanceWidget _methodChannel = MethodChannelGlanceWidget();

  @override
  Future<bool> updateSimpleWidget({
    required String widgetId,
    required SimpleWidgetData data,
    GlanceTheme? theme,
  }) {
    return _methodChannel.updateSimpleWidget(
      widgetId: widgetId,
      data: data,
      theme: theme,
    );
  }

  @override
  Future<bool> updateProgressWidget({
    required String widgetId,
    required ProgressWidgetData data,
    GlanceTheme? theme,
  }) {
    return _methodChannel.updateProgressWidget(
      widgetId: widgetId,
      data: data,
      theme: theme,
    );
  }

  @override
  Future<bool> updateListWidget({
    required String widgetId,
    required ListWidgetData data,
    GlanceTheme? theme,
  }) {
    return _methodChannel.updateListWidget(
      widgetId: widgetId,
      data: data,
      theme: theme,
    );
  }

  @override
  Future<bool> setGlobalTheme(GlanceTheme theme) {
    return _methodChannel.setGlobalTheme(theme);
  }

  @override
  Future<bool> forceRefreshAll() {
    return _methodChannel.forceRefreshAll();
  }

  @override
  Future<List<String>> getActiveWidgetIds() {
    return _methodChannel.getActiveWidgetIds();
  }

  @override
  Stream<GlanceWidgetAction> get onWidgetAction =>
      _methodChannel.onWidgetAction;
}
