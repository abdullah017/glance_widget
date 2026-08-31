import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glance_widget_platform_interface/glance_widget_platform_interface.dart';
import 'support/payload.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel methodChannel = MethodChannel(
    'dev.glance.widget/methods',
  );

  late List<MethodCall> log;
  late MethodChannelGlanceWidget platform;

  setUp(() {
    log = <MethodCall>[];
    platform = MethodChannelGlanceWidget();

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(methodChannel, (MethodCall methodCall) async {
          log.add(methodCall);
          switch (methodCall.method) {
            case 'updateSimpleWidget':
            case 'updateProgressWidget':
            case 'updateListWidget':
            case 'updateImageWidget':
            case 'updateChartWidget':
            case 'updateCalendarWidget':
            case 'updateGaugeWidget':
            case 'setGlobalTheme':
            case 'forceRefreshAll':
            case 'forgetWidget':
              return true;
            case 'getActiveWidgetIds':
              return <String>['widget1', 'widget2'];
            case 'getWidgetPushToken':
              return 'test_push_token_abc123';
            case 'isWidgetPushSupported':
              return true;
            case 'completeWidgetConfiguration':
              return true;
            default:
              return null;
          }
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(methodChannel, null);
  });

  group('MethodChannelGlanceWidget', () {
    group('updateSimpleWidget', () {
      test('sends correct method call', () async {
        await platform.updateSimpleWidget(
          widgetId: 'test_widget',
          data: const SimpleWidgetData(title: 'Test', value: '100'),
        );

        expect(log.length, 1);
        expect(log[0].method, 'updateSimpleWidget');

        final args = log[0].payload;
        expect(args['widgetId'], 'test_widget');
        expect(args.child('data')['title'], 'Test');
        expect(args.child('data')['value'], '100');
      });

      test('sends theme when provided', () async {
        await platform.updateSimpleWidget(
          widgetId: 'test_widget',
          data: const SimpleWidgetData(title: 'Test', value: '100'),
          theme: GlanceTheme.dark(),
        );

        expect(log.length, 1);
        final args = log[0].payload;
        expect(args['theme'], isNotNull);
        expect(args.child('theme')['isDark'], true);
      });

      test('sends null theme when not provided', () async {
        await platform.updateSimpleWidget(
          widgetId: 'test_widget',
          data: const SimpleWidgetData(title: 'Test', value: '100'),
        );

        expect(log.length, 1);
        final args = log[0].payload;
        expect(args['theme'], isNull);
      });
    });

    group('updateProgressWidget', () {
      test('sends correct method call', () async {
        await platform.updateProgressWidget(
          widgetId: 'progress_widget',
          data: const ProgressWidgetData(title: 'Loading', progress: 0.5),
        );

        expect(log.length, 1);
        expect(log[0].method, 'updateProgressWidget');

        final args = log[0].payload;
        expect(args['widgetId'], 'progress_widget');
        expect(args.child('data')['title'], 'Loading');
        expect(args.child('data')['progress'], 0.5);
      });

      test('sends progress type', () async {
        await platform.updateProgressWidget(
          widgetId: 'progress_widget',
          data: const ProgressWidgetData(
            title: 'Loading',
            progress: 0.75,
            progressType: ProgressType.linear,
          ),
        );

        expect(log.length, 1);
        final args = log[0].payload;
        expect(args.child('data')['progressType'], 'linear');
      });
    });

    group('updateListWidget', () {
      test('sends correct method call', () async {
        await platform.updateListWidget(
          widgetId: 'list_widget',
          data: const ListWidgetData(
            title: 'Tasks',
            items: [
              GlanceListItem(text: 'Item 1'),
              GlanceListItem(text: 'Item 2', checked: true),
            ],
          ),
        );

        expect(log.length, 1);
        expect(log[0].method, 'updateListWidget');

        final args = log[0].payload;
        expect(args['widgetId'], 'list_widget');
        expect(args.child('data')['title'], 'Tasks');
        expect(args.child('data')['items'], isA<List<Object?>>());
        expect(args.child('data').childList('items').length, 2);
      });

      test('sends showCheckboxes flag', () async {
        await platform.updateListWidget(
          widgetId: 'list_widget',
          data: const ListWidgetData(
            title: 'Tasks',
            items: [],
            showCheckboxes: true,
          ),
        );

        expect(log.length, 1);
        final args = log[0].payload;
        expect(args.child('data')['showCheckboxes'], true);
      });
    });

    group('updateImageWidget', () {
      test('sends correct method call', () async {
        await platform.updateImageWidget(
          widgetId: 'image_widget',
          data: const ImageWidgetData(
            title: 'Photo',
            imageUrl: 'https://example.com/photo.jpg',
          ),
        );

        expect(log.length, 1);
        expect(log[0].method, 'updateImageWidget');

        final args = log[0].payload;
        expect(args['widgetId'], 'image_widget');
        expect(args.child('data')['title'], 'Photo');
        expect(args.child('data')['imageUrl'], 'https://example.com/photo.jpg');
      });

      test('sends theme when provided', () async {
        await platform.updateImageWidget(
          widgetId: 'image_widget',
          data: const ImageWidgetData(title: 'Photo', imageBase64: 'AAAA'),
          theme: GlanceTheme.dark(),
        );

        expect(log.length, 1);
        final args = log[0].payload;
        expect(args['theme'], isNotNull);
        expect(args.child('theme')['isDark'], true);
      });

      test('sends null theme when not provided', () async {
        await platform.updateImageWidget(
          widgetId: 'image_widget',
          data: const ImageWidgetData(title: 'Photo', imageBase64: 'AAAA'),
        );

        expect(log.length, 1);
        final args = log[0].payload;
        expect(args['theme'], isNull);
      });

      test('sends fit parameter', () async {
        await platform.updateImageWidget(
          widgetId: 'image_widget',
          data: const ImageWidgetData(
            title: 'Photo',
            imageBase64: 'AAAA',
            fit: ImageFit.contain,
          ),
        );

        expect(log.length, 1);
        final args = log[0].payload;
        expect(args.child('data')['fit'], 'contain');
      });

      test('sends imageBase64 when provided', () async {
        await platform.updateImageWidget(
          widgetId: 'image_widget',
          data: const ImageWidgetData(
            title: 'Photo',
            imageBase64: 'base64data',
          ),
        );

        expect(log.length, 1);
        final args = log[0].payload;
        expect(args.child('data')['imageBase64'], 'base64data');
      });
    });

    group('updateChartWidget', () {
      test('sends correct method call', () async {
        await platform.updateChartWidget(
          widgetId: 'chart_widget',
          data: const ChartWidgetData(
            title: 'Sales',
            dataPoints: [10.0, 20.0, 30.0],
          ),
        );

        expect(log.length, 1);
        expect(log[0].method, 'updateChartWidget');

        final args = log[0].payload;
        expect(args['widgetId'], 'chart_widget');
        expect(args.child('data')['title'], 'Sales');
        expect(args.child('data')['dataPoints'], [10.0, 20.0, 30.0]);
      });

      test('sends chart type', () async {
        await platform.updateChartWidget(
          widgetId: 'chart_widget',
          data: const ChartWidgetData(
            title: 'Sales',
            dataPoints: [10.0, 20.0],
            chartType: ChartType.bar,
          ),
        );

        expect(log.length, 1);
        final args = log[0].payload;
        expect(args.child('data')['chartType'], 'bar');
      });

      test('sends theme when provided', () async {
        await platform.updateChartWidget(
          widgetId: 'chart_widget',
          data: const ChartWidgetData(title: 'Sales', dataPoints: [10.0]),
          theme: GlanceTheme.light(),
        );

        expect(log.length, 1);
        final args = log[0].payload;
        expect(args['theme'], isNotNull);
        expect(args.child('theme')['isDark'], false);
      });

      test('sends subtitle and color', () async {
        await platform.updateChartWidget(
          widgetId: 'chart_widget',
          data: const ChartWidgetData(
            title: 'Sales',
            dataPoints: [10.0],
            subtitle: 'Monthly',
            color: Color(0xFFFF0000),
          ),
        );

        expect(log.length, 1);
        final args = log[0].payload;
        expect(args.child('data')['subtitle'], 'Monthly');
        expect(args.child('data')['color'], 0xFFFF0000);
      });
    });

    group('updateCalendarWidget', () {
      test('sends correct method call', () async {
        final date = DateTime(2026, 3, 10);
        await platform.updateCalendarWidget(
          widgetId: 'calendar_widget',
          data: CalendarWidgetData(
            title: 'Today',
            date: date,
            events: const [CalendarEvent(time: '09:00', title: 'Standup')],
          ),
        );

        expect(log.length, 1);
        expect(log[0].method, 'updateCalendarWidget');

        final args = log[0].payload;
        expect(args['widgetId'], 'calendar_widget');
        expect(args.child('data')['title'], 'Today');
        expect(args.child('data')['date'], date.toIso8601String());
      });

      test('sends events', () async {
        await platform.updateCalendarWidget(
          widgetId: 'calendar_widget',
          data: CalendarWidgetData(
            title: 'Today',
            date: DateTime(2026, 3, 10),
            events: const [
              CalendarEvent(time: '09:00', title: 'Standup'),
              CalendarEvent(time: 'All Day', title: 'Birthday', isAllDay: true),
            ],
          ),
        );

        expect(log.length, 1);
        final args = log[0].payload;
        final events = args.child('data').childList('events');
        expect(events.length, 2);
        expect(events[0]['time'], '09:00');
        expect(events[0]['title'], 'Standup');
        expect(events[1]['isAllDay'], true);
      });

      test('sends theme when provided', () async {
        await platform.updateCalendarWidget(
          widgetId: 'calendar_widget',
          data: CalendarWidgetData(
            title: 'Today',
            date: DateTime(2026, 3, 10),
            events: const [],
          ),
          theme: GlanceTheme.dark(),
        );

        expect(log.length, 1);
        final args = log[0].payload;
        expect(args['theme'], isNotNull);
        expect(args.child('theme')['isDark'], true);
      });

      test('sends maxEvents', () async {
        await platform.updateCalendarWidget(
          widgetId: 'calendar_widget',
          data: CalendarWidgetData(
            title: 'Today',
            date: DateTime(2026, 3, 10),
            events: const [],
            maxEvents: 3,
          ),
        );

        expect(log.length, 1);
        final args = log[0].payload;
        expect(args.child('data')['maxEvents'], 3);
      });
    });

    group('updateGaugeWidget', () {
      test('sends correct method call', () async {
        await platform.updateGaugeWidget(
          widgetId: 'gauge_widget',
          data: const GaugeWidgetData(
            title: 'Performance',
            metrics: [GaugeMetric(label: 'CPU', value: 65.0, maxValue: 100.0)],
          ),
        );

        expect(log.length, 1);
        expect(log[0].method, 'updateGaugeWidget');

        final args = log[0].payload;
        expect(args['widgetId'], 'gauge_widget');
        expect(args.child('data')['title'], 'Performance');
      });

      test('sends metrics', () async {
        await platform.updateGaugeWidget(
          widgetId: 'gauge_widget',
          data: const GaugeWidgetData(
            title: 'System',
            metrics: [
              GaugeMetric(
                label: 'CPU',
                value: 75.0,
                maxValue: 100.0,
                unit: '%',
              ),
              GaugeMetric(label: 'RAM', value: 8.0, maxValue: 16.0, unit: 'GB'),
            ],
          ),
        );

        expect(log.length, 1);
        final args = log[0].payload;
        final metrics = args.child('data').childList('metrics');
        expect(metrics.length, 2);
        expect(metrics[0]['label'], 'CPU');
        expect(metrics[0]['value'], 75.0);
        expect(metrics[0]['maxValue'], 100.0);
        expect(metrics[0]['unit'], '%');
        expect(metrics[1]['label'], 'RAM');
      });

      test('sends theme when provided', () async {
        await platform.updateGaugeWidget(
          widgetId: 'gauge_widget',
          data: const GaugeWidgetData(
            title: 'Test',
            metrics: [GaugeMetric(label: 'X', value: 1.0, maxValue: 10.0)],
          ),
          theme: GlanceTheme.light(),
        );

        expect(log.length, 1);
        final args = log[0].payload;
        expect(args['theme'], isNotNull);
        expect(args.child('theme')['isDark'], false);
      });

      test('sends gauge type', () async {
        await platform.updateGaugeWidget(
          widgetId: 'gauge_widget',
          data: const GaugeWidgetData(
            title: 'Dashboard',
            metrics: [GaugeMetric(label: 'X', value: 1.0, maxValue: 10.0)],
            gaugeType: GaugeType.dashboard,
          ),
        );

        expect(log.length, 1);
        final args = log[0].payload;
        expect(args.child('data')['gaugeType'], 'dashboard');
      });

      test('sends metric color', () async {
        await platform.updateGaugeWidget(
          widgetId: 'gauge_widget',
          data: const GaugeWidgetData(
            title: 'Test',
            metrics: [
              GaugeMetric(
                label: 'X',
                value: 1.0,
                maxValue: 10.0,
                color: Color(0xFFFF0000),
              ),
            ],
          ),
        );

        expect(log.length, 1);
        final args = log[0].payload;
        final metrics = args.child('data').childList('metrics');
        expect(metrics[0]['color'], 0xFFFF0000);
      });
    });

    group('setGlobalTheme', () {
      test('sends correct method call', () async {
        await platform.setGlobalTheme(GlanceTheme.dark());

        expect(log.length, 1);
        expect(log[0].method, 'setGlobalTheme');

        final args = log[0].payload;
        expect(args['isDark'], true);
      });

      test('sends light theme', () async {
        await platform.setGlobalTheme(GlanceTheme.light());

        expect(log.length, 1);
        final args = log[0].payload;
        expect(args['isDark'], false);
      });
    });

    group('forceRefreshAll', () {
      test('sends correct method call', () async {
        await platform.forceRefreshAll();

        expect(log.length, 1);
        expect(log[0].method, 'forceRefreshAll');
      });
    });

    group('getActiveWidgetIds', () {
      test('returns list of widget IDs', () async {
        final result = await platform.getActiveWidgetIds();

        expect(result, ['widget1', 'widget2']);
        expect(log.length, 1);
        expect(log[0].method, 'getActiveWidgetIds');
      });
    });

    group('forgetWidget', () {
      test('sends the id the platform is to drop', () async {
        await platform.forgetWidget('btc');

        expect(log.length, 1);
        expect(log[0].method, 'forgetWidget');
        expect(log[0].arguments, {'widgetId': 'btc'});
      });
    });

    group('getWidgetPushToken', () {
      test('returns push token', () async {
        final result = await platform.getWidgetPushToken();

        expect(result, 'test_push_token_abc123');
        expect(log.length, 1);
        expect(log[0].method, 'getWidgetPushToken');
      });

      test('answers null when the platform has no token yet', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
              methodChannel,
              (MethodCall methodCall) async => null,
            );

        expect(await platform.getWidgetPushToken(), isNull);
      });
    });

    group('isWidgetPushSupported', () {
      test('sends correct method call', () async {
        final result = await platform.isWidgetPushSupported();

        expect(result, isTrue);
        expect(log.length, 1);
        expect(log[0].method, 'isWidgetPushSupported');
      });

      test('answers false when the platform returns null', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
              methodChannel,
              (MethodCall methodCall) async => null,
            );

        expect(await platform.isWidgetPushSupported(), isFalse);
      });
    });

    group('completeWidgetConfiguration', () {
      test('sends correct method call', () async {
        await platform.completeWidgetConfiguration('test_widget');

        expect(log.length, 1);
        expect(log[0].method, 'completeWidgetConfiguration');

        final args = log[0].payload;
        expect(args['widgetId'], 'test_widget');
      });

      test('throws when the platform refuses', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(methodChannel, (
              MethodCall methodCall,
            ) async {
              throw PlatformException(code: 'ERROR', message: 'Test error');
            });

        await expectLater(
          platform.completeWidgetConfiguration('test_widget'),
          throwsA(isA<GlanceWidgetException>()),
        );
      });
    });

    group('action event parsing', () {
      test('parses toggle action from event data', () {
        final eventData = <String, dynamic>{
          'widgetId': 'settings_widget',
          'type': 'toggle',
          'timestamp': 1234567890,
          'itemId': 'dark_mode',
          'value': true,
        };

        final action = GlanceWidgetAction.fromMap(eventData);
        expect(action.type, GlanceActionType.toggle);
        expect(action.widgetId, 'settings_widget');
        expect(action.itemId, 'dark_mode');
        expect(action.value, true);
      });

      test('parses checkboxToggle action from event data', () {
        final eventData = <String, dynamic>{
          'widgetId': 'todo_list',
          'type': 'checkboxToggle',
          'timestamp': 1234567890,
          'payload': <String, dynamic>{'itemIndex': 2, 'value': false},
        };

        final action = GlanceWidgetAction.fromMap(eventData);
        expect(action.type, GlanceActionType.checkboxToggle);
        expect(action.widgetId, 'todo_list');
        expect(action.itemIndex, 2);
        expect(action.value, false);
      });

      test('parses checkboxToggle with top-level fields', () {
        final eventData = <String, dynamic>{
          'widgetId': 'todo_list',
          'type': 'checkboxToggle',
          'timestamp': 1234567890,
          'itemIndex': 0,
          'value': true,
        };

        final action = GlanceWidgetAction.fromMap(eventData);
        expect(action.type, GlanceActionType.checkboxToggle);
        expect(action.itemIndex, 0);
        expect(action.value, true);
      });

      test('parses itemTap action with index in payload', () {
        final eventData = <String, dynamic>{
          'widgetId': 'list_widget',
          'type': 'itemTap',
          'timestamp': 1234567890,
          'payload': <String, dynamic>{'index': 5},
        };

        final action = GlanceWidgetAction.fromMap(eventData);
        expect(action.type, GlanceActionType.itemTap);
        expect(action.itemIndex, 5);
      });

      test('roundtrip: toMap then fromMap preserves all fields', () {
        final original = GlanceWidgetAction(
          widgetId: 'test_widget',
          type: GlanceActionType.checkboxToggle,
          timestamp: DateTime.fromMillisecondsSinceEpoch(1000),
          itemId: 'item_1',
          value: true,
          itemIndex: 3,
        );

        final map = original.toMap();
        final restored = GlanceWidgetAction.fromMap(map);

        expect(restored.widgetId, original.widgetId);
        expect(restored.type, original.type);
        expect(restored.itemId, original.itemId);
        expect(restored.value, original.value);
        expect(restored.itemIndex, original.itemIndex);
        expect(
          restored.timestamp.millisecondsSinceEpoch,
          original.timestamp.millisecondsSinceEpoch,
        );
      });
    });

    group('error handling', () {
      /// Fails every call the way an absent widget instance does.
      void failEveryCall() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(methodChannel, (
              MethodCall methodCall,
            ) async {
              throw PlatformException(
                code: 'UNAVAILABLE',
                message: 'Test error',
              );
            });
      }

      test('a rejected update throws instead of answering false', () async {
        failEveryCall();

        await expectLater(
          platform.updateSimpleWidget(
            widgetId: 'test',
            data: const SimpleWidgetData(title: 'Test', value: '100'),
          ),
          throwsA(
            isA<GlanceWidgetException>()
                .having((e) => e.code, 'code', 'UNAVAILABLE')
                .having(
                  (e) => e.message,
                  'message',
                  contains('Failed to update simple widget'),
                ),
          ),
        );
      });

      test('every mutation throws on a platform failure', () async {
        failEveryCall();

        final calls = <String, Future<void> Function()>{
          'updateSimpleWidget': () => platform.updateSimpleWidget(
            widgetId: 'w',
            data: const SimpleWidgetData(title: 'T', value: 'V'),
          ),
          'updateProgressWidget': () => platform.updateProgressWidget(
            widgetId: 'w',
            data: const ProgressWidgetData(title: 'T', progress: 0.5),
          ),
          'updateListWidget': () => platform.updateListWidget(
            widgetId: 'w',
            data: const ListWidgetData(title: 'T', items: []),
          ),
          'updateImageWidget': () => platform.updateImageWidget(
            widgetId: 'w',
            data: const ImageWidgetData(title: 'T'),
          ),
          'updateChartWidget': () => platform.updateChartWidget(
            widgetId: 'w',
            data: const ChartWidgetData(title: 'T', dataPoints: [1, 2]),
          ),
          'updateCalendarWidget': () => platform.updateCalendarWidget(
            widgetId: 'w',
            data: CalendarWidgetData(
              title: 'T',
              date: DateTime(2026),
              events: const [],
            ),
          ),
          'updateGaugeWidget': () => platform.updateGaugeWidget(
            widgetId: 'w',
            data: const GaugeWidgetData(
              title: 'T',
              metrics: [GaugeMetric(label: 'L', value: 1, maxValue: 2)],
            ),
          ),
          'setGlobalTheme': () => platform.setGlobalTheme(GlanceTheme.dark()),
          'forceRefreshAll': () => platform.forceRefreshAll(),
          'configureBackgroundUpdate': () => platform.configureBackgroundUpdate(
            widgetId: 'w',
            template: 'simple',
            apiUrl: 'https://example.com',
            title: 'T',
            valuePath: r'$.v',
          ),
          'cancelBackgroundUpdate': () => platform.cancelBackgroundUpdate('w'),
          'configureTimelineRefresh': () =>
              platform.configureTimelineRefresh(widgetId: 'w'),
          'cancelTimelineRefresh': () => platform.cancelTimelineRefresh('w'),
          'completeWidgetConfiguration': () =>
              platform.completeWidgetConfiguration('w'),
          'testBackgroundUpdate': () => platform.testBackgroundUpdate('w'),
          'forgetWidget': () => platform.forgetWidget('w'),
        };

        for (final entry in calls.entries) {
          await expectLater(
            entry.value(),
            throwsA(isA<GlanceWidgetException>()),
            reason: entry.key,
          );
        }
      });

      test('every query throws on a platform failure', () async {
        failEveryCall();

        final calls = <String, Future<Object?> Function()>{
          'getActiveWidgetIds': () => platform.getActiveWidgetIds(),
          'getWidgetPushToken': () => platform.getWidgetPushToken(),
          'isWidgetPushSupported': () => platform.isWidgetPushSupported(),
          'getBackgroundUpdateStatus': () =>
              platform.getBackgroundUpdateStatus('w'),
        };

        for (final entry in calls.entries) {
          await expectLater(
            entry.value(),
            throwsA(isA<GlanceWidgetException>()),
            reason: entry.key,
          );
        }
      });

      test('the original PlatformException is kept for diagnosis', () async {
        failEveryCall();

        try {
          await platform.forceRefreshAll();
          fail('expected a GlanceWidgetException');
        } on GlanceWidgetException catch (e) {
          expect(e.originalException, isA<PlatformException>());
        }
      });
    });
  });
}
