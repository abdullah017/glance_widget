import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glance_widget/glance_widget.dart';
import 'package:glance_widget_platform_interface/glance_widget_platform_interface.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockGlanceWidgetPlatform extends Mock
    with MockPlatformInterfaceMixin
    implements GlanceWidgetPlatform {}

class FakeSimpleWidgetData extends Fake implements SimpleWidgetData {}

class FakeGlanceTheme extends Fake implements GlanceTheme {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockGlanceWidgetPlatform mockPlatform;

  setUpAll(() {
    registerFallbackValue(FakeSimpleWidgetData());
    registerFallbackValue(FakeGlanceTheme());
  });

  setUp(() {
    mockPlatform = MockGlanceWidgetPlatform();
    GlanceWidgetPlatform.instance = mockPlatform;
    when(
      () => mockPlatform.updateSimpleWidget(
        widgetId: any(named: 'widgetId'),
        data: any(named: 'data'),
        theme: any(named: 'theme'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => mockPlatform.onWidgetAction,
    ).thenAnswer((_) => const Stream.empty());
    when(
      () => mockPlatform.setGlobalTheme(any()),
    ).thenAnswer((_) async {});
  });

  group('DebouncedWidgetController', () {
    test('multiple rapid updates coalesce to single dispatch', () {
      fakeAsync((async) {
        final ctrl = DebouncedWidgetController<SimpleWidgetData>(
          widgetId: 'test',
          debounceInterval: const Duration(milliseconds: 100),
        );

        ctrl.scheduleUpdate(const SimpleWidgetData(title: 'A', value: '1'));
        ctrl.scheduleUpdate(const SimpleWidgetData(title: 'B', value: '2'));
        ctrl.scheduleUpdate(const SimpleWidgetData(title: 'C', value: '3'));

        async.elapse(const Duration(milliseconds: 150));

        expect(ctrl.updateCount, 1);
        expect(ctrl.skippedCount, 2); // First is not a skip, 2nd and 3rd are
        ctrl.dispose();
      });
    });

    test('maxWaitTime forces flush even with continuous updates', () {
      fakeAsync((async) {
        final ctrl = DebouncedWidgetController<SimpleWidgetData>(
          widgetId: 'test',
          debounceInterval: const Duration(milliseconds: 100),
          maxWaitTime: const Duration(milliseconds: 500),
        );

        // Send update every 50ms — debounce timer keeps resetting
        for (var i = 0; i < 20; i++) {
          ctrl.scheduleUpdate(SimpleWidgetData(title: 'T', value: '$i'));
          async.elapse(const Duration(milliseconds: 50));
        }

        // maxWaitTime should have forced at least 1 flush
        expect(ctrl.updateCount, greaterThanOrEqualTo(1));
        ctrl.dispose();
      });
    });

    test('flush() sends immediately', () {
      fakeAsync((async) {
        final ctrl = DebouncedWidgetController<SimpleWidgetData>(
          widgetId: 'test',
        );

        ctrl.scheduleUpdate(const SimpleWidgetData(title: 'T', value: 'V'));
        ctrl.flush();
        async.flushMicrotasks();

        expect(ctrl.updateCount, 1);
        expect(ctrl.hasPendingUpdate, false);
        ctrl.dispose();
      });
    });

    test('isStale returns true before any update', () {
      final ctrl = DebouncedWidgetController<SimpleWidgetData>(
        widgetId: 'test',
        stalenessThreshold: const Duration(seconds: 10),
      );
      expect(ctrl.isStale, true);
      ctrl.dispose();
    });

    test('isStale returns false immediately after flush', () async {
      final ctrl = DebouncedWidgetController<SimpleWidgetData>(
        widgetId: 'test',
        stalenessThreshold: const Duration(seconds: 10),
      );
      ctrl.scheduleUpdate(const SimpleWidgetData(title: 'T', value: 'V'));
      await ctrl.flush();
      expect(ctrl.isStale, false);
      ctrl.dispose();
    });

    test('stalenessThreshold is configurable', () {
      final ctrl = DebouncedWidgetController<SimpleWidgetData>(
        widgetId: 'test',
        stalenessThreshold: const Duration(seconds: 15),
      );
      expect(ctrl.stalenessThreshold, const Duration(seconds: 15));
      ctrl.dispose();
    });

    test('dispose cancels timers', () {
      fakeAsync((async) {
        final ctrl = DebouncedWidgetController<SimpleWidgetData>(
          widgetId: 'test',
        );
        ctrl.scheduleUpdate(const SimpleWidgetData(title: 'T', value: 'V'));
        ctrl.dispose();
        // No crash when timers fire after dispose
        async.elapse(const Duration(seconds: 1));
      });
    });

    test('no pending update means flush is no-op', () {
      fakeAsync((async) {
        final ctrl = DebouncedWidgetController<SimpleWidgetData>(
          widgetId: 'test',
        );
        ctrl.flush();
        async.flushMicrotasks();
        expect(ctrl.updateCount, 0);
        ctrl.dispose();
      });
    });

    test('timeSinceLastUpdate returns null before first update', () {
      final ctrl = DebouncedWidgetController<SimpleWidgetData>(
        widgetId: 'test',
      );
      expect(ctrl.timeSinceLastUpdate, isNull);
      ctrl.dispose();
    });
  });
}
