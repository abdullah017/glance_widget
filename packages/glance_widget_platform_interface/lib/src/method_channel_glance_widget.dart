import 'dart:async';

import 'package:flutter/services.dart';
import 'package:glance_widget_platform_interface/src/glance_widget_platform.dart';
import 'package:glance_widget_platform_interface/src/types/glance_exception.dart';
import 'package:glance_widget_platform_interface/src/types/widget_action.dart';
import 'package:glance_widget_platform_interface/src/types/widget_data.dart';
import 'package:glance_widget_platform_interface/src/types/widget_theme.dart';
import 'package:logging/logging.dart';

/// An implementation of [GlanceWidgetPlatform] that uses method channels.
///
/// ## Error contract
///
/// Every operation either completes or throws [GlanceWidgetException]. There is
/// no success flag to inspect: the native plugins answer with an error whenever
/// a widget could not be updated -- no widget instance on the home screen,
/// unreachable App Group storage, a failed write -- and those arrive here as
/// exceptions.
class MethodChannelGlanceWidget extends GlanceWidgetPlatform {
  /// Logger for this class.
  static final _log = Logger('GlanceWidget');

  /// The method channel used to interact with the native platform.
  static const MethodChannel _methodChannel = MethodChannel(
    'dev.glance.widget/methods',
  );

  /// The event channel for receiving widget action events.
  static const EventChannel _eventChannel = EventChannel(
    'dev.glance.widget/events',
  );

  /// Stream controller for widget actions.
  StreamController<GlanceWidgetAction>? _actionController;
  StreamSubscription<Object?>? _eventSubscription;

  /// Invokes [method] and translates a platform failure into a
  /// [GlanceWidgetException] carrying [context].
  Future<T?> _invoke<T>(
    String method,
    String context, [
    Object? arguments,
  ]) async {
    try {
      return await _methodChannel.invokeMethod<T>(method, arguments);
    } on PlatformException catch (e) {
      throw GlanceWidgetException.fromPlatformException(e, context: context);
    }
  }

  /// Invokes a mutating [method]; completing normally means the platform
  /// applied the change.
  Future<void> _mutate(
    String method,
    String context, [
    Object? arguments,
  ]) async {
    await _invoke<bool>(method, context, arguments);
  }

  Map<String, Object?> _payload(
    String widgetId,
    WidgetData data,
    GlanceTheme? theme,
  ) => <String, Object?>{
    'widgetId': widgetId,
    'data': data.toMap(),
    'theme': theme?.toMap(),
  };

  @override
  Future<void> updateSimpleWidget({
    required String widgetId,
    required SimpleWidgetData data,
    GlanceTheme? theme,
  }) => _mutate(
    'updateSimpleWidget',
    'Failed to update simple widget',
    _payload(widgetId, data, theme),
  );

  @override
  Future<void> updateProgressWidget({
    required String widgetId,
    required ProgressWidgetData data,
    GlanceTheme? theme,
  }) => _mutate(
    'updateProgressWidget',
    'Failed to update progress widget',
    _payload(widgetId, data, theme),
  );

  @override
  Future<void> updateListWidget({
    required String widgetId,
    required ListWidgetData data,
    GlanceTheme? theme,
  }) => _mutate(
    'updateListWidget',
    'Failed to update list widget',
    _payload(widgetId, data, theme),
  );

  @override
  Future<void> updateImageWidget({
    required String widgetId,
    required ImageWidgetData data,
    GlanceTheme? theme,
  }) => _mutate(
    'updateImageWidget',
    'Failed to update image widget',
    _payload(widgetId, data, theme),
  );

  @override
  Future<void> updateChartWidget({
    required String widgetId,
    required ChartWidgetData data,
    GlanceTheme? theme,
  }) => _mutate(
    'updateChartWidget',
    'Failed to update chart widget',
    _payload(widgetId, data, theme),
  );

  @override
  Future<void> updateCalendarWidget({
    required String widgetId,
    required CalendarWidgetData data,
    GlanceTheme? theme,
  }) => _mutate(
    'updateCalendarWidget',
    'Failed to update calendar widget',
    _payload(widgetId, data, theme),
  );

  @override
  Future<void> updateGaugeWidget({
    required String widgetId,
    required GaugeWidgetData data,
    GlanceTheme? theme,
  }) => _mutate(
    'updateGaugeWidget',
    'Failed to update gauge widget',
    _payload(widgetId, data, theme),
  );

  @override
  Future<void> setGlobalTheme(GlanceTheme theme) =>
      _mutate('setGlobalTheme', 'Failed to set global theme', theme.toMap());

  @override
  Future<void> forceRefreshAll() =>
      _mutate('forceRefreshAll', 'Failed to force refresh all widgets');

  @override
  Future<List<String>> getActiveWidgetIds() async {
    final result = await _invoke<List<Object?>>(
      'getActiveWidgetIds',
      'Failed to get active widget IDs',
    );
    return result?.cast<String>() ?? <String>[];
  }

  @override
  Stream<GlanceWidgetAction> get onWidgetAction {
    _actionController ??= StreamController<GlanceWidgetAction>.broadcast(
      onListen: _startListening,
      onCancel: _stopListening,
    );
    return _actionController!.stream;
  }

  void _startListening() {
    _eventSubscription = _eventChannel.receiveBroadcastStream().listen(
      (Object? event) {
        if (event is Map) {
          final action = GlanceWidgetAction.fromMap(
            Map<String, dynamic>.from(event),
          );
          _actionController?.add(action);
        }
      },
      onError: (Object error) {
        _log.warning('Widget action stream error: $error', error);
        _actionController?.addError(error);
      },
    );
  }

  void _stopListening() {
    _eventSubscription?.cancel();
    _eventSubscription = null;
  }

  /// Releases resources. Called automatically when platform instance is swapped.
  @override
  void dispose() {
    _stopListening();
    _actionController?.close();
    _actionController = null;
  }

  /// Gets the Widget Push Token for server-triggered updates (iOS 26+).
  ///
  /// This token can be sent to your server to trigger widget updates via APNs.
  /// Returns `null` when the platform has no token yet.
  @override
  Future<String?> getWidgetPushToken() =>
      _invoke<String>('getWidgetPushToken', 'Failed to get widget push token');

  @override
  Future<bool> isWidgetPushSupported() async {
    final result = await _invoke<bool>(
      'isWidgetPushSupported',
      'Failed to check widget push support',
    );
    return result ?? false;
  }

  @override
  Future<void> configureBackgroundUpdate({
    required String widgetId,
    required String template,
    required String apiUrl,
    required String title,
    required String valuePath,
    Map<String, String> headers = const <String, String>{},
    int intervalMinutes = 15,
    String? subtitlePath,
    String? valuePrefix,
    String? valueSuffix,
  }) => _mutate(
    'configureBackgroundUpdate',
    'Failed to configure background update',
    <String, Object?>{
      'widgetId': widgetId,
      'template': template,
      'apiUrl': apiUrl,
      'headers': headers,
      'intervalMinutes': intervalMinutes,
      'title': title,
      'valuePath': valuePath,
      'subtitlePath': subtitlePath,
      'valuePrefix': valuePrefix,
      'valueSuffix': valueSuffix,
      'enabled': true,
    },
  );

  @override
  Future<void> cancelBackgroundUpdate(String widgetId) => _mutate(
    'cancelBackgroundUpdate',
    'Failed to cancel background update',
    <String, Object?>{'widgetId': widgetId},
  );

  @override
  Future<Map<String, dynamic>> getBackgroundUpdateStatus(
    String widgetId,
  ) async {
    final result = await _invoke<Map<Object?, Object?>>(
      'getBackgroundUpdateStatus',
      'Failed to get background update status',
      <String, Object?>{'widgetId': widgetId},
    );
    if (result == null) {
      return <String, dynamic>{'widgetId': widgetId, 'isConfigured': false};
    }
    return Map<String, dynamic>.from(result);
  }

  @override
  Future<void> configureTimelineRefresh({
    required String widgetId,
    int intervalMinutes = 30,
  }) => _mutate(
    'configureTimelineRefresh',
    'Failed to configure timeline refresh',
    <String, Object?>{'widgetId': widgetId, 'intervalMinutes': intervalMinutes},
  );

  @override
  Future<void> cancelTimelineRefresh(String widgetId) => _mutate(
    'cancelTimelineRefresh',
    'Failed to cancel timeline refresh',
    <String, Object?>{'widgetId': widgetId},
  );

  @override
  Future<void> completeWidgetConfiguration(String widgetId) => _mutate(
    'completeWidgetConfiguration',
    'Failed to complete widget configuration',
    <String, Object?>{'widgetId': widgetId},
  );

  @override
  Future<void> testBackgroundUpdate(String widgetId) => _mutate(
    'testBackgroundUpdate',
    'Failed to test background update',
    <String, Object?>{'widgetId': widgetId},
  );
}
