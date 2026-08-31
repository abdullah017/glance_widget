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

  @override
  Future<bool> updateImageWidget({
    required String widgetId,
    required ImageWidgetData data,
    GlanceTheme? theme,
  }) {
    return _methodChannel.updateImageWidget(
      widgetId: widgetId,
      data: data,
      theme: theme,
    );
  }

  @override
  Future<bool> updateChartWidget({
    required String widgetId,
    required ChartWidgetData data,
    GlanceTheme? theme,
  }) {
    return _methodChannel.updateChartWidget(
      widgetId: widgetId,
      data: data,
      theme: theme,
    );
  }

  @override
  Future<bool> updateCalendarWidget({
    required String widgetId,
    required CalendarWidgetData data,
    GlanceTheme? theme,
  }) {
    return _methodChannel.updateCalendarWidget(
      widgetId: widgetId,
      data: data,
      theme: theme,
    );
  }

  @override
  Future<bool> updateGaugeWidget({
    required String widgetId,
    required GaugeWidgetData data,
    GlanceTheme? theme,
  }) {
    return _methodChannel.updateGaugeWidget(
      widgetId: widgetId,
      data: data,
      theme: theme,
    );
  }

  @override
  Future<String?> getWidgetPushToken() {
    return _methodChannel.getWidgetPushToken();
  }

  @override
  Future<bool> isWidgetPushSupported() {
    return _methodChannel.isWidgetPushSupported();
  }

  @override
  Future<bool> configureBackgroundUpdate({
    required String widgetId,
    required String template,
    required String apiUrl,
    Map<String, String> headers = const {},
    int intervalMinutes = 15,
    required String title,
    required String valuePath,
    String? subtitlePath,
    String? valuePrefix,
    String? valueSuffix,
  }) {
    return _methodChannel.configureBackgroundUpdate(
      widgetId: widgetId,
      template: template,
      apiUrl: apiUrl,
      headers: headers,
      intervalMinutes: intervalMinutes,
      title: title,
      valuePath: valuePath,
      subtitlePath: subtitlePath,
      valuePrefix: valuePrefix,
      valueSuffix: valueSuffix,
    );
  }

  @override
  Future<bool> cancelBackgroundUpdate(String widgetId) {
    return _methodChannel.cancelBackgroundUpdate(widgetId);
  }

  @override
  Future<Map<String, dynamic>> getBackgroundUpdateStatus(String widgetId) {
    return _methodChannel.getBackgroundUpdateStatus(widgetId);
  }

  @override
  Future<bool> configureTimelineRefresh({
    required String widgetId,
    int intervalMinutes = 30,
  }) {
    return _methodChannel.configureTimelineRefresh(
      widgetId: widgetId,
      intervalMinutes: intervalMinutes,
    );
  }

  @override
  Future<bool> cancelTimelineRefresh(String widgetId) {
    return _methodChannel.cancelTimelineRefresh(widgetId);
  }

  @override
  Future<bool> completeWidgetConfiguration(String widgetId) {
    return _methodChannel.completeWidgetConfiguration(widgetId);
  }

  @override
  Future<bool> testBackgroundUpdate(String widgetId) {
    return _methodChannel.testBackgroundUpdate(widgetId);
  }

  @override
  void dispose() {
    _methodChannel.dispose();
  }
}
