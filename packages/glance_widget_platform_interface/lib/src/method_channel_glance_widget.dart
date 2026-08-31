import 'dart:async';

import 'package:flutter/services.dart';
import 'package:glance_widget_platform_interface/src/glance_widget_platform.dart';
import 'package:glance_widget_platform_interface/src/types/glance_exception.dart';
import 'package:glance_widget_platform_interface/src/types/glance_widget_update.dart';
import 'package:glance_widget_platform_interface/src/types/live_activity.dart';
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
/// exceptions. Data that could not render at all is rejected before the call is
/// made, with a [GlanceWidgetValidationException] naming the offending field.
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

  /// Validates and dispatches a template update.
  ///
  /// `async` on purpose: [WidgetData.validate] throws, and a rejection from an
  /// `async` method arrives as a failed future rather than an exception raised
  /// before the future exists. A caller writing `update(...).catchError(...)`
  /// would never see a synchronous throw.
  Future<void> _updateWidget(
    String method,
    String context,
    String widgetId,
    WidgetData data,
    GlanceTheme? theme,
  ) async {
    // Validated here rather than in the constructors because this is the last
    // point before the data leaves Dart, it runs in release builds, and it
    // covers data assembled at runtime from a server response as much as a
    // literal written by hand.
    WidgetData.checkNotEmpty(widgetId, 'widgetId');
    data.validate();
    await _mutate(method, context, <String, Object?>{
      'widgetId': widgetId,
      'data': data.toMap(),
      'theme': theme?.toMap(),
    });
  }

  @override
  Future<void> updateBatch(
    List<GlanceWidgetUpdate> updates, {
    GlanceTheme? theme,
  }) async {
    if (updates.isEmpty) {
      return;
    }

    // Validated before anything crosses, so a batch with one bad entry is
    // rejected whole rather than applying nineteen widgets and then throwing.
    // A validation error is a mistake in the calling code; a partial apply
    // would leave the home screen in a state the caller never asked for.
    final seen = <String>{};
    for (final update in updates) {
      update.validate();
      if (!seen.add(update.widgetId)) {
        throw GlanceWidgetValidationException(
          'widgetId "${update.widgetId}" appears more than once in the batch',
          field: 'widgetId',
          invalidValue: update.widgetId,
        );
      }
    }

    // The theme is sent once for the whole batch rather than repeated per
    // widget. Updating twenty widgets with a shared theme used to serialise it
    // twenty times, which was most of the payload.
    final response = await _invoke<Map<Object?, Object?>>(
      'updateBatch',
      'Failed to update widgets',
      <String, Object?>{
        'theme': theme?.toMap(),
        'updates': updates.map((update) => update.toMap()).toList(),
      },
    );

    final failures = _batchFailures(response);
    if (failures.isNotEmpty) {
      throw GlanceWidgetBatchException(failures, attempted: updates.length);
    }
  }

  /// Reads the per-widget failures out of a batch reply.
  ///
  /// An older plugin that does not report them answers with null or without
  /// the key, which reads as "nothing failed" -- the same thing an empty list
  /// means, and the same thing the pre-batch methods conveyed by not throwing.
  static List<GlanceWidgetBatchFailure> _batchFailures(
    Map<Object?, Object?>? response,
  ) {
    final reported = response?['failures'];
    if (reported is! List) {
      return const <GlanceWidgetBatchFailure>[];
    }
    return reported.whereType<Map<Object?, Object?>>().map((failure) {
      return GlanceWidgetBatchFailure(
        widgetId: failure['widgetId']?.toString() ?? '<unknown>',
        message: failure['message']?.toString() ?? 'Unknown platform error',
        code: failure['code']?.toString(),
      );
    }).toList();
  }

  @override
  Future<void> updateSimpleWidget({
    required String widgetId,
    required SimpleWidgetData data,
    GlanceTheme? theme,
  }) => _updateWidget(
    'updateSimpleWidget',
    'Failed to update simple widget',
    widgetId,
    data,
    theme,
  );

  @override
  Future<void> updateProgressWidget({
    required String widgetId,
    required ProgressWidgetData data,
    GlanceTheme? theme,
  }) => _updateWidget(
    'updateProgressWidget',
    'Failed to update progress widget',
    widgetId,
    data,
    theme,
  );

  @override
  Future<void> updateListWidget({
    required String widgetId,
    required ListWidgetData data,
    GlanceTheme? theme,
  }) => _updateWidget(
    'updateListWidget',
    'Failed to update list widget',
    widgetId,
    data,
    theme,
  );

  @override
  Future<void> updateImageWidget({
    required String widgetId,
    required ImageWidgetData data,
    GlanceTheme? theme,
  }) => _updateWidget(
    'updateImageWidget',
    'Failed to update image widget',
    widgetId,
    data,
    theme,
  );

  @override
  Future<void> updateChartWidget({
    required String widgetId,
    required ChartWidgetData data,
    GlanceTheme? theme,
  }) => _updateWidget(
    'updateChartWidget',
    'Failed to update chart widget',
    widgetId,
    data,
    theme,
  );

  @override
  Future<void> updateCalendarWidget({
    required String widgetId,
    required CalendarWidgetData data,
    GlanceTheme? theme,
  }) => _updateWidget(
    'updateCalendarWidget',
    'Failed to update calendar widget',
    widgetId,
    data,
    theme,
  );

  @override
  Future<void> updateGaugeWidget({
    required String widgetId,
    required GaugeWidgetData data,
    GlanceTheme? theme,
  }) => _updateWidget(
    'updateGaugeWidget',
    'Failed to update gauge widget',
    widgetId,
    data,
    theme,
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
  Future<void> forgetWidget(String widgetId) => _mutate(
    'forgetWidget',
    'Failed to forget widget',
    <String, Object?>{'widgetId': widgetId},
  );

  /// Runs a Live Activity call, turning "this platform has no such method"
  /// into an [UnsupportedError].
  ///
  /// Android's plugin answers an unknown method with `notImplemented`, which
  /// Flutter delivers as a [MissingPluginException] -- a bug-shaped exception
  /// for what is here a permanent property of the platform. There is no
  /// Android equivalent to implement: Android 16's Live Updates are a
  /// notification, not a widget.
  Future<T> _liveActivity<T>(
    String method,
    String context,
    T Function(Object? result) parse, [
    Object? arguments,
  ]) async {
    try {
      final result = await _methodChannel.invokeMethod<Object?>(
        method,
        arguments,
      );
      return parse(result);
    } on MissingPluginException {
      throw UnsupportedError(
        'Live Activities are an iOS 16.2+ feature; this platform has no '
        'equivalent. Guard the call with areLiveActivitiesEnabled().',
      );
    } on PlatformException catch (e) {
      throw GlanceWidgetException.fromPlatformException(e, context: context);
    }
  }

  @override
  Future<void> startLiveActivity({
    required String activityId,
    required LiveActivityContent content,
  }) async {
    WidgetData.checkNotEmpty(activityId, 'activityId');
    content.validate();
    await _liveActivity<void>(
      'startLiveActivity',
      'Failed to start Live Activity',
      (_) {},
      <String, Object?>{'activityId': activityId, 'content': content.toMap()},
    );
  }

  @override
  Future<void> updateLiveActivity({
    required String activityId,
    required LiveActivityContent content,
  }) async {
    WidgetData.checkNotEmpty(activityId, 'activityId');
    content.validate();
    await _liveActivity<void>(
      'updateLiveActivity',
      'Failed to update Live Activity',
      (_) {},
      <String, Object?>{'activityId': activityId, 'content': content.toMap()},
    );
  }

  @override
  Future<void> endLiveActivity({
    required String activityId,
    LiveActivityContent? content,
    LiveActivityDismissal dismissal = LiveActivityDismissal.standard,
  }) async {
    WidgetData.checkNotEmpty(activityId, 'activityId');
    content?.validate();
    await _liveActivity<void>(
      'endLiveActivity',
      'Failed to end Live Activity',
      (_) {},
      <String, Object?>{
        'activityId': activityId,
        if (content != null) 'content': content.toMap(),
        'dismissal': dismissal.wireName,
      },
    );
  }

  @override
  Future<bool> isLiveActivityRunning(String activityId) async {
    WidgetData.checkNotEmpty(activityId, 'activityId');
    try {
      return await _liveActivity<bool>(
        'isLiveActivityRunning',
        'Failed to check whether the Live Activity is running',
        (result) => result as bool? ?? false,
        <String, Object?>{'activityId': activityId},
      );
    } on UnsupportedError {
      // Same reasoning as areLiveActivitiesEnabled: "is one running" has a
      // correct answer on a platform that cannot run them, and it is no.
      return false;
    }
  }

  @override
  Future<bool> areLiveActivitiesEnabled() async {
    // Unlike the three above, this one answers rather than throws on a
    // platform that has no Live Activities: "can I start one" has a correct
    // answer there, and it is no.
    try {
      return await _liveActivity<bool>(
        'areLiveActivitiesEnabled',
        'Failed to check Live Activity availability',
        (result) => result as bool? ?? false,
      );
    } on UnsupportedError {
      return false;
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
