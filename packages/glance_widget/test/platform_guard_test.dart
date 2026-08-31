import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glance_widget/src/glance_config.dart';

void main() {
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    PlatformGuard.resetWarningLatch();
  });

  group('PlatformGuard.guard', () {
    test('answers the fallback on an unsupported platform', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;

      final result = await PlatformGuard.guard(
        () async => 'executed',
        'default',
      );
      expect(result, 'default');
    });

    test('never throws on an unsupported platform', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;

      await expectLater(
        PlatformGuard.guard(() async => 'executed', 'default'),
        completion('default'),
      );
    });

    test('executes the action on Android', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;

      final result = await PlatformGuard.guard(
        () async => 'executed',
        'default',
      );
      expect(result, 'executed');
    });

    test('executes the action on iOS', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

      final result = await PlatformGuard.guard(
        () async => 'executed',
        'default',
      );
      expect(result, 'executed');
    });

    test('lets a real failure on a supported platform through', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;

      await expectLater(
        PlatformGuard.guard<String>(
          () async => throw StateError('boom'),
          'default',
        ),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('PlatformGuard.guardVoid', () {
    test('skips the action on an unsupported platform', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      var ran = false;

      await PlatformGuard.guardVoid(() async {
        ran = true;
      });

      expect(ran, isFalse);
    });

    test('runs the action on a supported platform', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      var ran = false;

      await PlatformGuard.guardVoid(() async {
        ran = true;
      });

      expect(ran, isTrue);
    });

    test('lets a real failure through', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;

      await expectLater(
        PlatformGuard.guardVoid(() async => throw StateError('boom')),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('PlatformGuard.guardStream', () {
    test('yields an empty stream on an unsupported platform', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;

      final events = await PlatformGuard.guardStream(
        () => Stream<int>.fromIterable(<int>[1, 2, 3]),
      ).toList();

      expect(events, isEmpty);
    });

    test('yields the real stream on a supported platform', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;

      final events = await PlatformGuard.guardStream(
        () => Stream<int>.fromIterable(<int>[1, 2, 3]),
      ).toList();

      expect(events, <int>[1, 2, 3]);
    });
  });

  group('GlanceConfig.isSupported', () {
    test('is true for Android', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      expect(GlanceConfig.isSupported, isTrue);
    });

    test('is true for iOS', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      expect(GlanceConfig.isSupported, isTrue);
    });

    test('is false for every desktop platform', () {
      for (final platform in <TargetPlatform>[
        TargetPlatform.linux,
        TargetPlatform.macOS,
        TargetPlatform.windows,
        TargetPlatform.fuchsia,
      ]) {
        debugDefaultTargetPlatformOverride = platform;
        expect(GlanceConfig.isSupported, isFalse, reason: platform.name);
      }
    });
  });
}
