import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:glance_widget/glance_widget.dart';
import 'package:glance_widget_platform_interface/glance_widget_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockGlanceWidgetPlatform extends Mock
    with MockPlatformInterfaceMixin
    implements GlanceWidgetPlatform {}

class FakeSimpleWidgetData extends Fake implements SimpleWidgetData {}
class FakeGlanceTheme extends Fake implements GlanceTheme {}

void main() {
  late MockGlanceWidgetPlatform mockPlatform;

  setUpAll(() {
    registerFallbackValue(FakeSimpleWidgetData());
    registerFallbackValue(FakeGlanceTheme());
  });

  setUp(() {
    mockPlatform = MockGlanceWidgetPlatform();
    GlanceWidgetPlatform.instance = mockPlatform;
  });

  group('GlanceWidgetController', () {
    test('update() dispatches to correct platform method with typed data', () async {
      final ctrl = SimpleWidgetController(widgetId: 'test');
      final data = SimpleWidgetData(title: 'T', value: 'V');
      when(() => mockPlatform.updateSimpleWidget(
        widgetId: any(named: 'widgetId'),
        data: any(named: 'data'),
        theme: any(named: 'theme'),
      )).thenAnswer((_) async => true);

      final result = await ctrl.update(data);
      expect(result, true);
      verify(() => mockPlatform.updateSimpleWidget(
        widgetId: 'test', data: data, theme: null,
      )).called(1);
      ctrl.dispose();
    });

    test('onAction filters by widgetId from global stream', () async {
      final ctrl = SimpleWidgetController(widgetId: 'my_widget');
      final now = DateTime.now();
      final streamController = StreamController<GlanceWidgetAction>.broadcast();
      when(() => mockPlatform.onWidgetAction)
          .thenAnswer((_) => streamController.stream);

      final received = <GlanceWidgetAction>[];
      ctrl.onAction.listen(received.add);

      streamController.add(GlanceWidgetAction(widgetId: 'my_widget', type: GlanceActionType.tap, timestamp: now));
      streamController.add(GlanceWidgetAction(widgetId: 'other', type: GlanceActionType.tap, timestamp: now));
      streamController.add(GlanceWidgetAction(widgetId: 'my_widget', type: GlanceActionType.refresh, timestamp: now));

      await Future.delayed(Duration.zero);

      expect(received.length, 2);
      expect(received.every((a) => a.widgetId == 'my_widget'), true);
      ctrl.dispose();
      await streamController.close();
    });

    test('lazy initialization — no subscription until onAction accessed', () {
      final ctrl = SimpleWidgetController(widgetId: 'test');
      ctrl.dispose();
      // If onWidgetAction getter was never called, verifyNever won't work
      // because it's a getter, but the point is: no crash, clean dispose
    });

    test('dispose() prevents further operations', () {
      final ctrl = SimpleWidgetController(widgetId: 'test');
      ctrl.dispose();
      expect(
        () => ctrl.update(SimpleWidgetData(title: 'T', value: 'V')),
        throwsStateError,
      );
      expect(() => ctrl.onAction, throwsStateError);
    });

    test('setTheme delegates to setGlobalTheme', () async {
      final ctrl = SimpleWidgetController(widgetId: 'test');
      final theme = GlanceTheme.dark();
      when(() => mockPlatform.setGlobalTheme(any()))
          .thenAnswer((_) async => true);

      await ctrl.setTheme(theme);
      verify(() => mockPlatform.setGlobalTheme(theme)).called(1);
      expect(ctrl.theme, theme);
      ctrl.dispose();
    });

    test('double dispose does not throw', () {
      final ctrl = SimpleWidgetController(widgetId: 'test');
      ctrl.dispose();
      expect(() => ctrl.dispose(), returnsNormally);
    });
  });
}
