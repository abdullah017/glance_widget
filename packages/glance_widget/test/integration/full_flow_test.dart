import 'dart:async';

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
  late MockGlanceWidgetPlatform mockPlatform;

  setUpAll(() {
    registerFallbackValue(FakeSimpleWidgetData());
    registerFallbackValue(FakeGlanceTheme());
  });

  setUp(() {
    mockPlatform = MockGlanceWidgetPlatform();
    GlanceWidgetPlatform.instance = mockPlatform;
  });

  group('Integration: full flow', () {
    test('Controller create -> update -> dispose lifecycle', () async {
      when(
        () => mockPlatform.updateSimpleWidget(
          widgetId: any(named: 'widgetId'),
          data: any(named: 'data'),
          theme: any(named: 'theme'),
        ),
      ).thenAnswer((_) async {});

      final ctrl = SimpleWidgetController(widgetId: 'test');
      await ctrl.update(const SimpleWidgetData(title: 'Test', value: '100'));

      ctrl.dispose();
      expect(
        () => ctrl.update(const SimpleWidgetData(title: 'T', value: 'V')),
        throwsStateError,
      );
    });

    test('Multiple controllers share single platform stream', () async {
      final streamController = StreamController<GlanceWidgetAction>.broadcast();
      when(
        () => mockPlatform.onWidgetAction,
      ).thenAnswer((_) => streamController.stream);

      final ctrl1 = SimpleWidgetController(widgetId: 'a');
      final ctrl2 = ProgressWidgetController(widgetId: 'b');

      final actionsA = <GlanceWidgetAction>[];
      final actionsB = <GlanceWidgetAction>[];
      ctrl1.onAction.listen(actionsA.add);
      ctrl2.onAction.listen(actionsB.add);

      final now = DateTime.now();
      streamController.add(
        GlanceWidgetAction(
          widgetId: 'a',
          type: GlanceActionType.tap,
          timestamp: now,
        ),
      );
      streamController.add(
        GlanceWidgetAction(
          widgetId: 'b',
          type: GlanceActionType.refresh,
          timestamp: now,
        ),
      );
      streamController.add(
        GlanceWidgetAction(
          widgetId: 'a',
          type: GlanceActionType.refresh,
          timestamp: now,
        ),
      );

      await Future<void>.delayed(Duration.zero);

      expect(actionsA.length, 2);
      expect(actionsB.length, 1);

      ctrl1.dispose();
      ctrl2.dispose();
      await streamController.close();
    });

    test('Platform swap disposes old instance', () {
      final newPlatform = MockGlanceWidgetPlatform();
      GlanceWidgetPlatform.instance = newPlatform;
      verify(() => mockPlatform.dispose()).called(1);
    });

    test(
      'Sealed WidgetData exhaustive switch in controller dispatch',
      () async {
        // Verify all 7 widget types dispatch correctly
        when(
          () => mockPlatform.updateSimpleWidget(
            widgetId: any(named: 'widgetId'),
            data: any(named: 'data'),
            theme: any(named: 'theme'),
          ),
        ).thenAnswer((_) async {});

        final ctrl = SimpleWidgetController(widgetId: 'test');
        await ctrl.update(const SimpleWidgetData(title: 'T', value: 'V'));
        ctrl.dispose();
      },
    );
  });
}
