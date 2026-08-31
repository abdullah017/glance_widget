import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glance_widget/glance_widget.dart';
import 'support/payload.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('dev.glance.widget/methods');
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return call.method == 'updateBatch'
              ? <Object?, Object?>{'failures': <Object?>[]}
              : true;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('GlanceWidget.batch', () {
    test('sends widgets of different templates in one call', () async {
      await GlanceWidget.batch(<GlanceWidgetUpdate>[
        const GlanceWidgetUpdate(
          widgetId: 'btc',
          data: SimpleWidgetData(title: 'Bitcoin', value: r'$94,532'),
        ),
        const GlanceWidgetUpdate(
          widgetId: 'steps',
          data: ProgressWidgetData(title: 'Steps', progress: 0.72),
        ),
        const GlanceWidgetUpdate(
          widgetId: 'chart',
          data: ChartWidgetData(title: 'Week', dataPoints: <double>[1, 2, 3]),
        ),
      ]);

      expect(calls, hasLength(1));
      expect(calls.single.method, 'updateBatch');
      final updates = calls.single.payload.childList('updates');
      expect(updates.map((u) => u['widgetId']), <String>[
        'btc',
        'steps',
        'chart',
      ]);
      expect(updates.map((u) => u['template']), <String>[
        'simple',
        'progress',
        'chart',
      ]);
    });

    test('sends the shared theme once instead of per widget', () async {
      await GlanceWidget.batch(<GlanceWidgetUpdate>[
        const GlanceWidgetUpdate(
          widgetId: 'a',
          data: SimpleWidgetData(title: 'A', value: '1'),
        ),
        const GlanceWidgetUpdate(
          widgetId: 'b',
          data: SimpleWidgetData(title: 'B', value: '2'),
        ),
      ], theme: GlanceTheme.dark());

      final payload = calls.single.payload;
      expect(payload.child('theme')['isDark'], true);
      for (final update in payload.childList('updates')) {
        expect(update.containsKey('theme'), isFalse);
      }
    });

    test('surfaces per-widget failures as a batch exception', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            return <Object?, Object?>{
              'failures': <Object?>[
                <Object?, Object?>{
                  'widgetId': 'missing',
                  'message': 'no widget instance on the home screen',
                  'code': 'WIDGET_NOT_FOUND',
                },
              ],
            };
          });

      await expectLater(
        GlanceWidget.batch(<GlanceWidgetUpdate>[
          const GlanceWidgetUpdate(
            widgetId: 'ok',
            data: SimpleWidgetData(title: 'A', value: '1'),
          ),
          const GlanceWidgetUpdate(
            widgetId: 'missing',
            data: SimpleWidgetData(title: 'B', value: '2'),
          ),
        ]),
        throwsA(
          isA<GlanceWidgetBatchException>()
              .having((e) => e.attempted, 'attempted', 2)
              .having(
                (e) => e.failures.single.widgetId,
                'failed widgetId',
                'missing',
              ),
        ),
      );
    });

    test('rejects a malformed update without touching the platform', () async {
      await expectLater(
        GlanceWidget.batch(<GlanceWidgetUpdate>[
          const GlanceWidgetUpdate(
            widgetId: 'ok',
            data: SimpleWidgetData(title: 'A', value: '1'),
          ),
          const GlanceWidgetUpdate(
            widgetId: 'bad',
            data: ImageWidgetData(title: 'no source at all'),
          ),
        ]),
        throwsA(isA<GlanceWidgetValidationException>()),
      );

      expect(calls, isEmpty);
    });
  });
}
