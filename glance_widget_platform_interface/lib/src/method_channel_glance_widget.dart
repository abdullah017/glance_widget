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
  static const MethodChannel _methodChannel =
      MethodChannel('com.example.glance_widget/methods');

  /// The event channel for receiving widget action events.
  static const EventChannel _eventChannel =
      EventChannel('com.example.glance_widget/events');

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
        {
          'widgetId': widgetId,
          'data': data.toMap(),
          'theme': theme?.toMap(),
        },
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
        {
          'widgetId': widgetId,
          'data': data.toMap(),
          'theme': theme?.toMap(),
        },
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
        {
          'widgetId': widgetId,
          'data': data.toMap(),
          'theme': theme?.toMap(),
        },
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
      final result =
          await _methodChannel.invokeMethod<List<dynamic>>('getActiveWidgetIds');
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
      onError: (error) {
        _log.warning('Widget action stream error: $error', error as Object?);
        _actionController?.addError(error);
      },
    );
  }

  void _stopListening() {
    _eventSubscription?.cancel();
    _eventSubscription = null;
  }
}
