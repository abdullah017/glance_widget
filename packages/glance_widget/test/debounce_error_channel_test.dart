import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glance_widget/glance_widget.dart';
import 'package:glance_widget_platform_interface/glance_widget_platform_interface.dart';

const MethodChannel _channel = MethodChannel('dev.glance.widget/methods');

/// Makes every channel call fail the way a missing widget instance does.
void _failEveryCall() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_channel, (MethodCall call) async {
        throw PlatformException(code: 'UNAVAILABLE', message: 'no widget');
      });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    GlanceWidgetPlatform.instance = MethodChannelGlanceWidget();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
  });

  group('DebouncedWidgetController error channel', () {
    testWidgets('a failed timer dispatch is not counted as an update', (
      WidgetTester tester,
    ) async {
      _failEveryCall();

      final controller = DebouncedWidgetController<SimpleWidgetData>(
        widgetId: 'w1',
        debounceInterval: const Duration(milliseconds: 10),
      );
      addTearDown(controller.dispose);

      controller.scheduleUpdate(const SimpleWidgetData(title: 'T', value: 'V'));
      await tester.pump(const Duration(milliseconds: 50));

      expect(controller.updateCount, 0);
      expect(controller.failedCount, 1);
      expect(controller.timeSinceLastUpdate, isNull);
      expect(controller.isStale, isTrue);
    });

    testWidgets('a failed timer dispatch reaches the errors stream', (
      WidgetTester tester,
    ) async {
      _failEveryCall();

      final controller = DebouncedWidgetController<SimpleWidgetData>(
        widgetId: 'w1',
        debounceInterval: const Duration(milliseconds: 10),
      );
      addTearDown(controller.dispose);

      final seen = <Object>[];
      final subscription = controller.errors.listen(seen.add);
      addTearDown(subscription.cancel);

      controller.scheduleUpdate(const SimpleWidgetData(title: 'T', value: 'V'));
      await tester.pump(const Duration(milliseconds: 50));

      expect(seen, hasLength(1));
      expect(seen.single, isA<GlanceWidgetException>());
      expect(controller.lastError, same(seen.single));
      // It went to the stream, not to the zone.
      expect(tester.takeException(), isNull);
    });

    testWidgets('flush throws to its caller instead of the errors stream', (
      WidgetTester tester,
    ) async {
      _failEveryCall();

      final controller = DebouncedWidgetController<SimpleWidgetData>(
        widgetId: 'w1',
        // Long enough that the timer cannot win the race with flush().
        debounceInterval: const Duration(seconds: 10),
      );
      addTearDown(controller.dispose);

      final seen = <Object>[];
      final subscription = controller.errors.listen(seen.add);
      addTearDown(subscription.cancel);

      controller.scheduleUpdate(const SimpleWidgetData(title: 'T', value: 'V'));

      await expectLater(controller.flush(), throwsA(isA<GlanceWidgetException>()));
      expect(seen, isEmpty, reason: 'the awaiting caller already got it');
      expect(controller.failedCount, 1);
      expect(controller.updateCount, 0);
    });

    testWidgets('a successful dispatch still counts and clears the pending data', (
      WidgetTester tester,
    ) async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_channel, (MethodCall call) async => true);

      final controller = DebouncedWidgetController<SimpleWidgetData>(
        widgetId: 'w1',
        debounceInterval: const Duration(milliseconds: 10),
      );
      addTearDown(controller.dispose);

      controller.scheduleUpdate(const SimpleWidgetData(title: 'T', value: 'V'));
      await tester.pump(const Duration(milliseconds: 50));

      expect(controller.updateCount, 1);
      expect(controller.failedCount, 0);
      expect(controller.hasPendingUpdate, isFalse);
      expect(controller.timeSinceLastUpdate, isNotNull);
    });

    testWidgets('a failure does not stop the next dispatch from succeeding', (
      WidgetTester tester,
    ) async {
      var shouldFail = true;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_channel, (MethodCall call) async {
            if (shouldFail) {
              throw PlatformException(code: 'UNAVAILABLE', message: 'no widget');
            }
            return true;
          });

      final controller = DebouncedWidgetController<SimpleWidgetData>(
        widgetId: 'w1',
        debounceInterval: const Duration(milliseconds: 10),
      );
      addTearDown(controller.dispose);
      final subscription = controller.errors.listen((_) {});
      addTearDown(subscription.cancel);

      controller.scheduleUpdate(const SimpleWidgetData(title: 'T', value: '1'));
      await tester.pump(const Duration(milliseconds: 50));
      expect(controller.failedCount, 1);

      shouldFail = false;
      controller.scheduleUpdate(const SimpleWidgetData(title: 'T', value: '2'));
      await tester.pump(const Duration(milliseconds: 50));

      expect(controller.updateCount, 1);
      expect(controller.failedCount, 1);
    });
  });

  group('platform support gate', () {
    testWidgets('an unsupported platform never reaches the channel', (
      WidgetTester tester,
    ) async {
      // The override is cleared inside the body, not in a tearDown: the test
      // framework asserts that foundation debug variables are unset *before*
      // tearDown callbacks run.
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      try {
        var calls = 0;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(_channel, (MethodCall call) async {
              calls++;
              return true;
            });

        final controller = DebouncedWidgetController<SimpleWidgetData>(
          widgetId: 'w1',
          debounceInterval: const Duration(milliseconds: 10),
        );
        addTearDown(controller.dispose);

        controller.scheduleUpdate(
          const SimpleWidgetData(title: 'T', value: 'V'),
        );
        await tester.pump(const Duration(milliseconds: 50));

        expect(calls, 0);
        // A no-op is a completed dispatch, not a failure.
        expect(controller.failedCount, 0);
        expect(controller.updateCount, 1);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });
  });
}
