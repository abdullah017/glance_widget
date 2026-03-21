import 'dart:async';

import 'package:flutter/services.dart';
import 'package:logging/logging.dart';

import 'glance_widget_platform.dart';
import 'types/glance_exception.dart';
import 'types/widget_data.dart';
import 'types/widget_theme.dart';
import 'types/widget_action.dart';

/// An implementation of [GlanceWidgetPlatform] that uses method channels.
class MethodChannelGlanceWidget extends GlanceWidgetPlatform {
  /// Logger for this class.
  static final _log = Logger('GlanceWidget');

  /// Whether to throw exceptions on errors instead of returning false.
  ///
  /// When set to `true`, methods will throw [GlanceWidgetException] on failure.
  /// When set to `false` (default), methods will log the error and return false.
  ///
  /// Set this to `true` in debug mode for better error visibility:
  /// ```dart
  /// MethodChannelGlanceWidget.throwOnError = kDebugMode;
  /// ```
  static bool throwOnError = false;

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
  StreamSubscription? _eventSubscription;

  @override
  Future<bool> updateSimpleWidget({
    required String widgetId,
    required SimpleWidgetData data,
    GlanceTheme? theme,
  }) async {
    try {
      final result = await _methodChannel.invokeMethod<bool>(
        'updateSimpleWidget',
        {'widgetId': widgetId, 'data': data.toMap(), 'theme': theme?.toMap()},
      );
      return result ?? false;
    } on PlatformException catch (e) {
      _log.warning('Failed to update simple widget: ${e.message}', e);
      if (throwOnError) {
        throw GlanceWidgetException.fromPlatformException(
          e,
          context: 'Failed to update simple widget',
        );
      }
      return false;
    }
  }

  @override
  Future<bool> updateProgressWidget({
    required String widgetId,
    required ProgressWidgetData data,
    GlanceTheme? theme,
  }) async {
    try {
      final result = await _methodChannel.invokeMethod<bool>(
        'updateProgressWidget',
        {'widgetId': widgetId, 'data': data.toMap(), 'theme': theme?.toMap()},
      );
      return result ?? false;
    } on PlatformException catch (e) {
      _log.warning('Failed to update progress widget: ${e.message}', e);
      if (throwOnError) {
        throw GlanceWidgetException.fromPlatformException(
          e,
          context: 'Failed to update progress widget',
        );
      }
      return false;
    }
  }

  @override
  Future<bool> updateListWidget({
    required String widgetId,
    required ListWidgetData data,
    GlanceTheme? theme,
  }) async {
    try {
      final result = await _methodChannel.invokeMethod<bool>(
        'updateListWidget',
        {'widgetId': widgetId, 'data': data.toMap(), 'theme': theme?.toMap()},
      );
      return result ?? false;
    } on PlatformException catch (e) {
      _log.warning('Failed to update list widget: ${e.message}', e);
      if (throwOnError) {
        throw GlanceWidgetException.fromPlatformException(
          e,
          context: 'Failed to update list widget',
        );
      }
      return false;
    }
  }

  @override
  Future<bool> updateImageWidget({
    required String widgetId,
    required ImageWidgetData data,
    GlanceTheme? theme,
  }) async {
    try {
      final result = await _methodChannel.invokeMethod<bool>(
        'updateImageWidget',
        {'widgetId': widgetId, 'data': data.toMap(), 'theme': theme?.toMap()},
      );
      return result ?? false;
    } on PlatformException catch (e) {
      _log.warning('Failed to update image widget: ${e.message}', e);
      if (throwOnError) {
        throw GlanceWidgetException.fromPlatformException(
          e,
          context: 'Failed to update image widget',
        );
      }
      return false;
    }
  }

  @override
  Future<bool> updateChartWidget({
    required String widgetId,
    required ChartWidgetData data,
    GlanceTheme? theme,
  }) async {
    try {
      final result = await _methodChannel.invokeMethod<bool>(
        'updateChartWidget',
        {'widgetId': widgetId, 'data': data.toMap(), 'theme': theme?.toMap()},
      );
      return result ?? false;
    } on PlatformException catch (e) {
      _log.warning('Failed to update chart widget: ${e.message}', e);
      if (throwOnError) {
        throw GlanceWidgetException.fromPlatformException(
          e,
          context: 'Failed to update chart widget',
        );
      }
      return false;
    }
  }

  @override
  Future<bool> updateCalendarWidget({
    required String widgetId,
    required CalendarWidgetData data,
    GlanceTheme? theme,
  }) async {
    try {
      final result = await _methodChannel.invokeMethod<bool>(
        'updateCalendarWidget',
        {'widgetId': widgetId, 'data': data.toMap(), 'theme': theme?.toMap()},
      );
      return result ?? false;
    } on PlatformException catch (e) {
      _log.warning('Failed to update calendar widget: ${e.message}', e);
      if (throwOnError) {
        throw GlanceWidgetException.fromPlatformException(
          e,
          context: 'Failed to update calendar widget',
        );
      }
      return false;
    }
  }

  @override
  Future<bool> updateGaugeWidget({
    required String widgetId,
    required GaugeWidgetData data,
    GlanceTheme? theme,
  }) async {
    try {
      final result = await _methodChannel.invokeMethod<bool>(
        'updateGaugeWidget',
        {'widgetId': widgetId, 'data': data.toMap(), 'theme': theme?.toMap()},
      );
      return result ?? false;
    } on PlatformException catch (e) {
      _log.warning('Failed to update gauge widget: ${e.message}', e);
      if (throwOnError) {
        throw GlanceWidgetException.fromPlatformException(
          e,
          context: 'Failed to update gauge widget',
        );
      }
      return false;
    }
  }

  @override
  Future<bool> setGlobalTheme(GlanceTheme theme) async {
    try {
      final result = await _methodChannel.invokeMethod<bool>(
        'setGlobalTheme',
        theme.toMap(),
      );
      return result ?? false;
    } on PlatformException catch (e) {
      _log.warning('Failed to set global theme: ${e.message}', e);
      if (throwOnError) {
        throw GlanceWidgetException.fromPlatformException(
          e,
          context: 'Failed to set global theme',
        );
      }
      return false;
    }
  }

  @override
  Future<bool> forceRefreshAll() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('forceRefreshAll');
      return result ?? false;
    } on PlatformException catch (e) {
      _log.warning('Failed to force refresh: ${e.message}', e);
      if (throwOnError) {
        throw GlanceWidgetException.fromPlatformException(
          e,
          context: 'Failed to force refresh all widgets',
        );
      }
      return false;
    }
  }

  @override
  Future<List<String>> getActiveWidgetIds() async {
    try {
      final result = await _methodChannel.invokeMethod<List<dynamic>>(
        'getActiveWidgetIds',
      );
      return result?.cast<String>() ?? [];
    } on PlatformException catch (e) {
      _log.warning('Failed to get active widget IDs: ${e.message}', e);
      if (throwOnError) {
        throw GlanceWidgetException.fromPlatformException(
          e,
          context: 'Failed to get active widget IDs',
        );
      }
      return [];
    }
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
      (event) {
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
  /// Returns `null` on unsupported platforms or if the token is not available.
  @override
  Future<String?> getWidgetPushToken() async {
    try {
      final result = await _methodChannel.invokeMethod<String?>(
        'getWidgetPushToken',
      );
      return result;
    } on PlatformException catch (e) {
      _log.warning('Failed to get widget push token: ${e.message}', e);
      if (throwOnError) {
        throw GlanceWidgetException.fromPlatformException(
          e,
          context: 'Failed to get widget push token',
        );
      }
      return null;
    }
  }

  @override
  Future<bool> isWidgetPushSupported() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>(
        'isWidgetPushSupported',
      );
      return result ?? false;
    } on PlatformException catch (e) {
      _log.warning('Failed to check widget push support: ${e.message}', e);
      if (throwOnError) {
        throw GlanceWidgetException.fromPlatformException(
          e,
          context: 'Failed to check widget push support',
        );
      }
      return false;
    }
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
  }) async {
    try {
      final result = await _methodChannel.invokeMethod<bool>(
        'configureBackgroundUpdate',
        {
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
      return result ?? false;
    } on PlatformException catch (e) {
      _log.warning('Failed to configure background update: ${e.message}', e);
      if (throwOnError) {
        throw GlanceWidgetException.fromPlatformException(
          e,
          context: 'Failed to configure background update',
        );
      }
      return false;
    }
  }

  @override
  Future<bool> cancelBackgroundUpdate(String widgetId) async {
    try {
      final result = await _methodChannel.invokeMethod<bool>(
        'cancelBackgroundUpdate',
        {'widgetId': widgetId},
      );
      return result ?? false;
    } on PlatformException catch (e) {
      _log.warning('Failed to cancel background update: ${e.message}', e);
      if (throwOnError) {
        throw GlanceWidgetException.fromPlatformException(
          e,
          context: 'Failed to cancel background update',
        );
      }
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>> getBackgroundUpdateStatus(String widgetId) async {
    try {
      final result = await _methodChannel.invokeMethod<Map<Object?, Object?>>(
        'getBackgroundUpdateStatus',
        {'widgetId': widgetId},
      );
      if (result == null) {
        return {'widgetId': widgetId, 'isConfigured': false};
      }
      return Map<String, dynamic>.from(result);
    } on PlatformException catch (e) {
      _log.warning('Failed to get background update status: ${e.message}', e);
      if (throwOnError) {
        throw GlanceWidgetException.fromPlatformException(
          e,
          context: 'Failed to get background update status',
        );
      }
      return {'widgetId': widgetId, 'isConfigured': false, 'error': e.message};
    }
  }

  @override
  Future<bool> configureTimelineRefresh({
    required String widgetId,
    int intervalMinutes = 30,
  }) async {
    try {
      final result = await _methodChannel.invokeMethod<bool>(
        'configureTimelineRefresh',
        {
          'widgetId': widgetId,
          'intervalMinutes': intervalMinutes,
        },
      );
      return result ?? false;
    } on PlatformException catch (e) {
      _log.warning('Failed to configure timeline refresh: ${e.message}', e);
      if (throwOnError) {
        throw GlanceWidgetException.fromPlatformException(
          e,
          context: 'Failed to configure timeline refresh',
        );
      }
      return false;
    }
  }

  @override
  Future<bool> cancelTimelineRefresh(String widgetId) async {
    try {
      final result = await _methodChannel.invokeMethod<bool>(
        'cancelTimelineRefresh',
        {'widgetId': widgetId},
      );
      return result ?? false;
    } on PlatformException catch (e) {
      _log.warning('Failed to cancel timeline refresh: ${e.message}', e);
      if (throwOnError) {
        throw GlanceWidgetException.fromPlatformException(
          e,
          context: 'Failed to cancel timeline refresh',
        );
      }
      return false;
    }
  }

  @override
  Future<bool> completeWidgetConfiguration(String widgetId) async {
    try {
      final result = await _methodChannel.invokeMethod<bool>(
        'completeWidgetConfiguration',
        {'widgetId': widgetId},
      );
      return result ?? false;
    } on PlatformException catch (e) {
      _log.warning('Failed to complete widget configuration: ${e.message}', e);
      if (throwOnError) {
        throw GlanceWidgetException.fromPlatformException(
          e,
          context: 'Failed to complete widget configuration',
        );
      }
      return false;
    }
  }

  @override
  Future<bool> testBackgroundUpdate(String widgetId) async {
    try {
      final result = await _methodChannel.invokeMethod<bool>(
        'testBackgroundUpdate',
        {'widgetId': widgetId},
      );
      return result ?? false;
    } on PlatformException catch (e) {
      _log.warning('Failed to test background update: ${e.message}', e);
      if (throwOnError) {
        throw GlanceWidgetException.fromPlatformException(
          e,
          context: 'Failed to test background update',
        );
      }
      return false;
    }
  }
}
