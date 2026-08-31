import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

/// Package-wide configuration and platform capability checks.
class GlanceConfig {
  GlanceConfig._();

  /// Whether home screen widgets are available on the current platform.
  ///
  /// Only Android and iOS have a home screen widget system. On every other
  /// platform -- web, desktop, tests running on the default host platform --
  /// widget calls are no-ops, so guard optional UI with this getter:
  ///
  /// ```dart
  /// if (GlanceWidget.isSupported) {
  ///   await GlanceWidget.simple(id: 'btc', title: 'Bitcoin', value: r'$94,532');
  /// }
  /// ```
  static bool get isSupported =>
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
}

/// Guards platform calls so they degrade to a no-op off Android and iOS.
///
/// A desktop or web build must not crash just because it shares code with the
/// mobile build, so unsupported platforms never throw here. Real failures on a
/// supported platform are a different matter: those propagate as
/// `GlanceWidgetException` and are never swallowed.
class PlatformGuard {
  PlatformGuard._();

  static final _log = Logger('GlanceWidget.PlatformGuard');

  /// Warned once per isolate; repeating it on every call would drown the log
  /// of an app that legitimately shares widget code with a desktop target.
  static bool _warned = false;

  static void _warnOnce() {
    if (_warned) return;
    _warned = true;
    _log.warning(
      'glance_widget has no home screen widgets on '
      '${defaultTargetPlatform.name}; calls are no-ops. '
      'Use GlanceWidget.isSupported to branch before calling.',
    );
  }

  /// Runs [action] on a supported platform, or answers [fallback] elsewhere.
  static Future<T> guard<T>(Future<T> Function() action, T fallback) async {
    if (!GlanceConfig.isSupported) {
      _warnOnce();
      return fallback;
    }
    return action();
  }

  /// Runs [action] on a supported platform, or does nothing elsewhere.
  static Future<void> guardVoid(Future<void> Function() action) async {
    if (!GlanceConfig.isSupported) {
      _warnOnce();
      return;
    }
    await action();
  }

  /// Returns the stream from [action] on a supported platform, or an empty
  /// stream elsewhere -- so `listen` still works and simply never fires.
  static Stream<T> guardStream<T>(Stream<T> Function() action) {
    if (!GlanceConfig.isSupported) {
      _warnOnce();
      return const Stream.empty();
    }
    return action();
  }

  /// Resets the one-shot warning latch. Visible for testing only.
  @visibleForTesting
  static void resetWarningLatch() {
    _warned = false;
  }
}
