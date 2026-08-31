import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

/// Package configuration.
class GlanceConfig {
  GlanceConfig._();

  /// When true, throws UnsupportedError on unsupported platforms.
  /// When false (default), returns default values and logs a warning.
  static bool strictMode = false;

  /// Whether the current platform is supported (Android or iOS).
  static bool get isSupported =>
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
}

/// Static utility for guarding platform calls on unsupported platforms.
class PlatformGuard {
  PlatformGuard._();
  static final _log = Logger('GlanceWidget.PlatformGuard');

  /// Executes [action] on supported platforms, returns [defaultValue] otherwise.
  static Future<T> guard<T>(Future<T> Function() action, T defaultValue) async {
    if (!GlanceConfig.isSupported) {
      if (GlanceConfig.strictMode) {
        throw UnsupportedError(
          'glance_widget is not supported on ${defaultTargetPlatform.name}. '
          'Supported platforms: Android, iOS.',
        );
      }
      _log.warning('glance_widget: unsupported platform, returning default');
      return defaultValue;
    }
    return action();
  }
}
