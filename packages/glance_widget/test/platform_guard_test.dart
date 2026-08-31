import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glance_widget/src/glance_config.dart';

void main() {
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    GlanceConfig.strictMode = false;
  });

  group('PlatformGuard', () {
    test('returns default on unsupported platform (strictMode=false)', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      GlanceConfig.strictMode = false;

      final result = await PlatformGuard.guard(
        () async => 'executed',
        'default',
      );
      expect(result, 'default');
    });

    test('throws on unsupported platform (strictMode=true)', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      GlanceConfig.strictMode = true;

      expect(
        () => PlatformGuard.guard(() async => 'executed', 'default'),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('executes action on supported platform (Android)', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;

      final result = await PlatformGuard.guard(
        () async => 'executed',
        'default',
      );
      expect(result, 'executed');
    });

    test('executes action on supported platform (iOS)', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

      final result = await PlatformGuard.guard(
        () async => 'executed',
        'default',
      );
      expect(result, 'executed');
    });
  });

  group('GlanceConfig', () {
    test('isSupported returns true for Android', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      expect(GlanceConfig.isSupported, true);
    });

    test('isSupported returns true for iOS', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      expect(GlanceConfig.isSupported, true);
    });

    test('isSupported returns false for Linux', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      expect(GlanceConfig.isSupported, false);
    });

    test('isSupported returns false for macOS', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      expect(GlanceConfig.isSupported, false);
    });

    test('isSupported returns false for Windows', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      expect(GlanceConfig.isSupported, false);
    });

    test('strictMode defaults to false', () {
      expect(GlanceConfig.strictMode, false);
    });
  });
}
