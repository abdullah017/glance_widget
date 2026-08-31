import 'package:glance_widget/src/glance_config.dart';
import 'package:glance_widget/src/json_path_validator.dart';
import 'package:glance_widget_platform_interface/glance_widget_platform_interface.dart';

/// Background update and timeline refresh operations.
///
/// This class is isolate-compatible — does NOT use AppLifecycleListener
/// or WidgetsBinding.
///
/// **Important:** In background handlers (e.g., Android WorkManager callback),
/// you must call:
/// ```dart
/// WidgetsFlutterBinding.ensureInitialized();
/// DartPluginRegistrant.ensureInitialized();
/// ```
class GlanceBackground {
  GlanceBackground._();

  /// Configures periodic background updates (Android: WorkManager).
  ///
  /// [template] specifies which widget template the native side should render.
  /// [intervalMinutes] minimum 15 (Android WorkManager constraint).
  /// [valuePath] JSONPath expression — e.g., `$.bitcoin.usd`
  /// [subtitlePath] optional JSONPath — e.g., `$.bitcoin.change_24h`
  static Future<void> configureUpdate({
    required String widgetId,
    required GlanceTemplate template,
    required String apiUrl,
    required String title,
    required String valuePath,
    Map<String, String> headers = const {},
    int intervalMinutes = 15,
    String? subtitlePath,
    String? valuePrefix,
    String? valueSuffix,
  }) async {
    return PlatformGuard.guardVoid(() async {
      JsonPathValidator.validate(valuePath);
      if (subtitlePath != null) JsonPathValidator.validate(subtitlePath);

      final clampedInterval = intervalMinutes < 15 ? 15 : intervalMinutes;

      await GlanceWidgetPlatform.instance.configureBackgroundUpdate(
        widgetId: widgetId,
        template: template.name,
        apiUrl: apiUrl,
        headers: headers,
        intervalMinutes: clampedInterval,
        title: title,
        valuePath: valuePath,
        subtitlePath: subtitlePath,
        valuePrefix: valuePrefix,
        valueSuffix: valueSuffix,
      );
    });
  }

  /// Cancels background updates for a widget.
  static Future<void> cancelUpdate(String widgetId) => PlatformGuard.guardVoid(
    () => GlanceWidgetPlatform.instance.cancelBackgroundUpdate(widgetId),
  );

  /// Gets the status of background updates for a widget.
  static Future<Map<String, dynamic>> getUpdateStatus(String widgetId) =>
      PlatformGuard.guard(
        () => GlanceWidgetPlatform.instance.getBackgroundUpdateStatus(widgetId),
        <String, dynamic>{'widgetId': widgetId, 'isConfigured': false},
      );

  /// Triggers a one-time background update immediately (for testing).
  static Future<void> testUpdate(String widgetId) => PlatformGuard.guardVoid(
    () => GlanceWidgetPlatform.instance.testBackgroundUpdate(widgetId),
  );

  /// Configures iOS timeline-based refresh for a widget.
  ///
  /// [intervalMinutes] is a suggestion — WidgetKit may delay refreshes
  /// to optimise battery life. Minimum 5 minutes.
  static Future<void> configureTimelineRefresh({
    required String widgetId,
    int intervalMinutes = 30,
  }) => PlatformGuard.guardVoid(
    () => GlanceWidgetPlatform.instance.configureTimelineRefresh(
      widgetId: widgetId,
      intervalMinutes: intervalMinutes < 5 ? 5 : intervalMinutes,
    ),
  );

  /// Cancels iOS timeline-based refresh for a widget.
  static Future<void> cancelTimelineRefresh(String widgetId) =>
      PlatformGuard.guardVoid(
        () => GlanceWidgetPlatform.instance.cancelTimelineRefresh(widgetId),
      );
}
