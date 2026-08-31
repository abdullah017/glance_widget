import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glance_widget_android/glance_widget_android.dart';
import 'package:glance_widget_platform_interface/glance_widget_platform_interface.dart';

/// Every call this implementation makes must land on the shared channel, under
/// the exact name the Kotlin side switches on. A test that only checks the class
/// hierarchy would pass just as happily if a method forwarded to the wrong one.
const MethodChannel _channel = MethodChannel('dev.glance.widget/methods');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<MethodCall> log;
  late GlanceWidgetAndroid android;

  setUp(() {
    log = <MethodCall>[];
    android = GlanceWidgetAndroid();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (MethodCall call) async {
          log.add(call);
          return switch (call.method) {
            'getActiveWidgetIds' => <String>['a', 'b'],
            'getWidgetPushToken' => 'token',
            'getBackgroundUpdateStatus' => <String, Object?>{'enabled': true},
            _ => true,
          };
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
  });

  group('registration', () {
    test('extends GlanceWidgetPlatform', () {
      expect(android, isA<GlanceWidgetPlatform>());
    });

    test('registerWith installs itself as the platform instance', () {
      GlanceWidgetAndroid.registerWith();
      expect(GlanceWidgetPlatform.instance, isA<GlanceWidgetAndroid>());
    });
  });

  group('template updates reach the channel', () {
    test('updateSimpleWidget forwards id, data and theme', () async {
      await android.updateSimpleWidget(
        widgetId: 'w1',
        data: const SimpleWidgetData(title: 'Bitcoin', value: r'$64,120'),
        theme: GlanceTheme.dark(),
      );

      expect(log, hasLength(1));
      expect(log.single.method, 'updateSimpleWidget');
      final args = (log.single.arguments as Map<Object?, Object?>)
          .cast<String, Object?>();
      expect(args['widgetId'], 'w1');
      expect((args['data']! as Map<Object?, Object?>)['title'], 'Bitcoin');
      expect(args['theme'], isNotNull);
    });

    test('a null theme is forwarded as null, not dropped', () async {
      await android.updateSimpleWidget(
        widgetId: 'w1',
        data: const SimpleWidgetData(title: 'T', value: 'V'),
      );

      final args = (log.single.arguments as Map<Object?, Object?>)
          .cast<String, Object?>();
      expect(args.containsKey('theme'), isTrue);
      expect(args['theme'], isNull);
    });

    test('each template calls its own channel method', () async {
      await android.updateProgressWidget(
        widgetId: 'p',
        data: const ProgressWidgetData(title: 'Download', progress: 0.5),
      );
      await android.updateListWidget(
        widgetId: 'l',
        data: const ListWidgetData(title: 'Todo', items: <GlanceListItem>[]),
      );
      await android.updateImageWidget(
        widgetId: 'i',
        data: const ImageWidgetData(title: 'Photo', imageUrl: 'u'),
      );
      await android.updateChartWidget(
        widgetId: 'c',
        // Not `const`: `ChartWidgetData` and `GaugeWidgetData` assert on
        // `List.length`, which Dart cannot evaluate in a constant expression, so
        // those two constructors can never be used as `const`. Tracked for the
        // v2 validation rework.
        data: ChartWidgetData(
          title: 'Revenue',
          dataPoints: const <double>[1, 2],
        ),
      );
      await android.updateCalendarWidget(
        widgetId: 'ca',
        data: CalendarWidgetData(
          title: 'Today',
          date: DateTime.utc(2026, 8, 31),
          events: const <CalendarEvent>[],
        ),
      );
      await android.updateGaugeWidget(
        widgetId: 'g',
        data: GaugeWidgetData(
          title: 'CPU',
          metrics: const <GaugeMetric>[
            GaugeMetric(label: 'load', value: 42, maxValue: 100),
          ],
        ),
      );

      expect(log.map((MethodCall c) => c.method), <String>[
        'updateProgressWidget',
        'updateListWidget',
        'updateImageWidget',
        'updateChartWidget',
        'updateCalendarWidget',
        'updateGaugeWidget',
      ]);
    });
  });

  group('results come back from the channel', () {
    test('getActiveWidgetIds returns the ids the platform reported', () async {
      expect(await android.getActiveWidgetIds(), <String>['a', 'b']);
    });

    test('getBackgroundUpdateStatus returns the platform map', () async {
      expect(await android.getBackgroundUpdateStatus('w1'), <String, Object?>{
        'enabled': true,
      });
      expect(log.single.method, 'getBackgroundUpdateStatus');
    });

    test('forceRefreshAll takes no arguments', () async {
      await android.forceRefreshAll();
      expect(log.single.method, 'forceRefreshAll');
      expect(log.single.arguments, isNull);
    });
  });
}
