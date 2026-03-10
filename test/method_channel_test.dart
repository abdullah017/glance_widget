import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glance_widget_platform_interface/glance_widget_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel methodChannel = MethodChannel(
    'com.example.glance_widget/methods',
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
        final result = await platform.updateSimpleWidget(
          widgetId: 'test_widget',
          data: const SimpleWidgetData(title: 'Test', value: '100'),
        );

        expect(result, true);
        expect(log.length, 1);
        expect(log[0].method, 'updateSimpleWidget');

        final args = log[0].arguments as Map;
        expect(args['widgetId'], 'test_widget');
        expect(args['data']['title'], 'Test');
        expect(args['data']['value'], '100');
      });

      test('sends theme when provided', () async {
        await platform.updateSimpleWidget(
          widgetId: 'test_widget',
          data: const SimpleWidgetData(title: 'Test', value: '100'),
          theme: GlanceTheme.dark(),
        );

        expect(log.length, 1);
        final args = log[0].arguments as Map;
        expect(args['theme'], isNotNull);
        expect(args['theme']['isDark'], true);
      });

      test('sends null theme when not provided', () async {
        await platform.updateSimpleWidget(
          widgetId: 'test_widget',
          data: const SimpleWidgetData(title: 'Test', value: '100'),
        );

        expect(log.length, 1);
        final args = log[0].arguments as Map;
        expect(args['theme'], isNull);
      });
    });

    group('updateProgressWidget', () {
      test('sends correct method call', () async {
        final result = await platform.updateProgressWidget(
          widgetId: 'progress_widget',
          data: const ProgressWidgetData(title: 'Loading', progress: 0.5),
        );

        expect(result, true);
        expect(log.length, 1);
        expect(log[0].method, 'updateProgressWidget');

        final args = log[0].arguments as Map;
        expect(args['widgetId'], 'progress_widget');
        expect(args['data']['title'], 'Loading');
        expect(args['data']['progress'], 0.5);
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
        final args = log[0].arguments as Map;
        expect(args['data']['progressType'], 'linear');
      });
    });

    group('updateListWidget', () {
      test('sends correct method call', () async {
        final result = await platform.updateListWidget(
          widgetId: 'list_widget',
          data: const ListWidgetData(
            title: 'Tasks',
            items: [
              GlanceListItem(text: 'Item 1'),
              GlanceListItem(text: 'Item 2', checked: true),
            ],
          ),
        );

        expect(result, true);
        expect(log.length, 1);
        expect(log[0].method, 'updateListWidget');

        final args = log[0].arguments as Map;
        expect(args['widgetId'], 'list_widget');
        expect(args['data']['title'], 'Tasks');
        expect(args['data']['items'], isA<List>());
        expect((args['data']['items'] as List).length, 2);
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
        final args = log[0].arguments as Map;
        expect(args['data']['showCheckboxes'], true);
      });
    });

    group('updateImageWidget', () {
      test('sends correct method call', () async {
        final result = await platform.updateImageWidget(
          widgetId: 'image_widget',
          data: const ImageWidgetData(
            title: 'Photo',
            imageUrl: 'https://example.com/photo.jpg',
          ),
        );

        expect(result, true);
        expect(log.length, 1);
        expect(log[0].method, 'updateImageWidget');

        final args = log[0].arguments as Map;
        expect(args['widgetId'], 'image_widget');
        expect(args['data']['title'], 'Photo');
        expect(args['data']['imageUrl'], 'https://example.com/photo.jpg');
      });

      test('sends theme when provided', () async {
        await platform.updateImageWidget(
          widgetId: 'image_widget',
          data: const ImageWidgetData(title: 'Photo'),
          theme: GlanceTheme.dark(),
        );

        expect(log.length, 1);
        final args = log[0].arguments as Map;
        expect(args['theme'], isNotNull);
        expect(args['theme']['isDark'], true);
      });

      test('sends null theme when not provided', () async {
        await platform.updateImageWidget(
          widgetId: 'image_widget',
          data: const ImageWidgetData(title: 'Photo'),
        );

        expect(log.length, 1);
        final args = log[0].arguments as Map;
        expect(args['theme'], isNull);
      });

      test('sends fit parameter', () async {
        await platform.updateImageWidget(
          widgetId: 'image_widget',
          data: const ImageWidgetData(
            title: 'Photo',
            fit: ImageFit.contain,
          ),
        );

        expect(log.length, 1);
        final args = log[0].arguments as Map;
        expect(args['data']['fit'], 'contain');
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
        final args = log[0].arguments as Map;
        expect(args['data']['imageBase64'], 'base64data');
      });
    });

    group('updateChartWidget', () {
      test('sends correct method call', () async {
        final result = await platform.updateChartWidget(
          widgetId: 'chart_widget',
          data: ChartWidgetData(
            title: 'Sales',
            dataPoints: [10.0, 20.0, 30.0],
          ),
        );

        expect(result, true);
        expect(log.length, 1);
        expect(log[0].method, 'updateChartWidget');

        final args = log[0].arguments as Map;
        expect(args['widgetId'], 'chart_widget');
        expect(args['data']['title'], 'Sales');
        expect(args['data']['dataPoints'], [10.0, 20.0, 30.0]);
      });

      test('sends chart type', () async {
        await platform.updateChartWidget(
          widgetId: 'chart_widget',
          data: ChartWidgetData(
            title: 'Sales',
            dataPoints: [10.0, 20.0],
            chartType: ChartType.bar,
          ),
        );

        expect(log.length, 1);
        final args = log[0].arguments as Map;
        expect(args['data']['chartType'], 'bar');
      });

      test('sends theme when provided', () async {
        await platform.updateChartWidget(
          widgetId: 'chart_widget',
          data: ChartWidgetData(
            title: 'Sales',
            dataPoints: [10.0],
          ),
          theme: GlanceTheme.light(),
        );

        expect(log.length, 1);
        final args = log[0].arguments as Map;
        expect(args['theme'], isNotNull);
        expect(args['theme']['isDark'], false);
      });

      test('sends subtitle and color', () async {
        await platform.updateChartWidget(
          widgetId: 'chart_widget',
          data: ChartWidgetData(
            title: 'Sales',
            dataPoints: [10.0],
            subtitle: 'Monthly',
            color: Color(0xFFFF0000),
          ),
        );

        expect(log.length, 1);
        final args = log[0].arguments as Map;
        expect(args['data']['subtitle'], 'Monthly');
        expect(args['data']['color'], 0xFFFF0000);
      });
    });

    group('updateCalendarWidget', () {
      test('sends correct method call', () async {
        final date = DateTime(2026, 3, 10);
        final result = await platform.updateCalendarWidget(
          widgetId: 'calendar_widget',
          data: CalendarWidgetData(
            title: 'Today',
            date: date,
            events: const [
              CalendarEvent(time: '09:00', title: 'Standup'),
            ],
          ),
        );

        expect(result, true);
        expect(log.length, 1);
        expect(log[0].method, 'updateCalendarWidget');

        final args = log[0].arguments as Map;
        expect(args['widgetId'], 'calendar_widget');
        expect(args['data']['title'], 'Today');
        expect(args['data']['date'], date.toIso8601String());
      });

      test('sends events', () async {
        await platform.updateCalendarWidget(
          widgetId: 'calendar_widget',
          data: CalendarWidgetData(
            title: 'Today',
            date: DateTime(2026, 3, 10),
            events: const [
              CalendarEvent(time: '09:00', title: 'Standup'),
              CalendarEvent(
                time: 'All Day',
                title: 'Birthday',
                isAllDay: true,
              ),
            ],
          ),
        );

        expect(log.length, 1);
        final args = log[0].arguments as Map;
        final events = args['data']['events'] as List;
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
        final args = log[0].arguments as Map;
        expect(args['theme'], isNotNull);
        expect(args['theme']['isDark'], true);
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
        final args = log[0].arguments as Map;
        expect(args['data']['maxEvents'], 3);
      });
    });

    group('updateGaugeWidget', () {
      test('sends correct method call', () async {
        final result = await platform.updateGaugeWidget(
          widgetId: 'gauge_widget',
          data: GaugeWidgetData(
            title: 'Performance',
            metrics: [
              GaugeMetric(label: 'CPU', value: 65.0, maxValue: 100.0),
            ],
          ),
        );

        expect(result, true);
        expect(log.length, 1);
        expect(log[0].method, 'updateGaugeWidget');

        final args = log[0].arguments as Map;
        expect(args['widgetId'], 'gauge_widget');
        expect(args['data']['title'], 'Performance');
      });

      test('sends metrics', () async {
        await platform.updateGaugeWidget(
          widgetId: 'gauge_widget',
          data: GaugeWidgetData(
            title: 'System',
            metrics: [
              GaugeMetric(
                label: 'CPU',
                value: 75.0,
                maxValue: 100.0,
                unit: '%',
              ),
              GaugeMetric(
                label: 'RAM',
                value: 8.0,
                maxValue: 16.0,
                unit: 'GB',
              ),
            ],
          ),
        );

        expect(log.length, 1);
        final args = log[0].arguments as Map;
        final metrics = args['data']['metrics'] as List;
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
          data: GaugeWidgetData(
            title: 'Test',
            metrics: [
              GaugeMetric(label: 'X', value: 1.0, maxValue: 10.0),
            ],
          ),
          theme: GlanceTheme.light(),
        );

        expect(log.length, 1);
        final args = log[0].arguments as Map;
        expect(args['theme'], isNotNull);
        expect(args['theme']['isDark'], false);
      });

      test('sends gauge type', () async {
        await platform.updateGaugeWidget(
          widgetId: 'gauge_widget',
          data: GaugeWidgetData(
            title: 'Dashboard',
            metrics: [
              GaugeMetric(label: 'X', value: 1.0, maxValue: 10.0),
            ],
            gaugeType: GaugeType.dashboard,
          ),
        );

        expect(log.length, 1);
        final args = log[0].arguments as Map;
        expect(args['data']['gaugeType'], 'dashboard');
      });

      test('sends metric color', () async {
        await platform.updateGaugeWidget(
          widgetId: 'gauge_widget',
          data: GaugeWidgetData(
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
        final args = log[0].arguments as Map;
        final metrics = args['data']['metrics'] as List;
        expect(metrics[0]['color'], 0xFFFF0000);
      });
    });

    group('setGlobalTheme', () {
      test('sends correct method call', () async {
        final result = await platform.setGlobalTheme(GlanceTheme.dark());

        expect(result, true);
        expect(log.length, 1);
        expect(log[0].method, 'setGlobalTheme');

        final args = log[0].arguments as Map;
        expect(args['isDark'], true);
      });

      test('sends light theme', () async {
        await platform.setGlobalTheme(GlanceTheme.light());

        expect(log.length, 1);
        final args = log[0].arguments as Map;
        expect(args['isDark'], false);
      });
    });

    group('forceRefreshAll', () {
      test('sends correct method call', () async {
        final result = await platform.forceRefreshAll();

        expect(result, true);
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

    group('getWidgetPushToken', () {
      test('returns push token', () async {
        final result = await platform.getWidgetPushToken();

        expect(result, 'test_push_token_abc123');
        expect(log.length, 1);
        expect(log[0].method, 'getWidgetPushToken');
      });

      test('returns null on error', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(methodChannel, (
              MethodCall methodCall,
            ) async {
              throw PlatformException(code: 'ERROR', message: 'Test error');
            });

        final result = await platform.getWidgetPushToken();

        expect(result, isNull);
      });
    });

    group('isWidgetPushSupported', () {
      test('returns true when supported', () async {
        final result = await platform.isWidgetPushSupported();

        expect(result, true);
        expect(log.length, 1);
        expect(log[0].method, 'isWidgetPushSupported');
      });

      test('returns false on error', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(methodChannel, (
              MethodCall methodCall,
            ) async {
              throw PlatformException(code: 'ERROR', message: 'Test error');
            });

        final result = await platform.isWidgetPushSupported();

        expect(result, false);
      });
    });

    group('completeWidgetConfiguration', () {
      test('sends correct method call', () async {
        final result = await platform.completeWidgetConfiguration('test_widget');

        expect(result, true);
        expect(log.length, 1);
        expect(log[0].method, 'completeWidgetConfiguration');

        final args = log[0].arguments as Map;
        expect(args['widgetId'], 'test_widget');
      });

      test('returns false on error', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(methodChannel, (
              MethodCall methodCall,
            ) async {
              throw PlatformException(code: 'ERROR', message: 'Test error');
            });

        final result = await platform.completeWidgetConfiguration('test_widget');

        expect(result, false);
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
          'payload': <String, dynamic>{
            'itemIndex': 2,
            'value': false,
          },
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
      test('returns false on PlatformException by default', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(methodChannel, (
              MethodCall methodCall,
            ) async {
              throw PlatformException(code: 'ERROR', message: 'Test error');
            });

        final result = await platform.updateSimpleWidget(
          widgetId: 'test',
          data: const SimpleWidgetData(title: 'Test', value: '100'),
        );

        expect(result, false);
      });

      test('throws GlanceWidgetException when throwOnError is true', () async {
        MethodChannelGlanceWidget.throwOnError = true;

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(methodChannel, (
              MethodCall methodCall,
            ) async {
              throw PlatformException(code: 'ERROR', message: 'Test error');
            });

        await expectLater(
          platform.updateSimpleWidget(
            widgetId: 'test',
            data: const SimpleWidgetData(title: 'Test', value: '100'),
          ),
          throwsA(isA<GlanceWidgetException>()),
        );

        // Reset for other tests
        MethodChannelGlanceWidget.throwOnError = false;
      });

      test('returns empty list on getActiveWidgetIds error', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(methodChannel, (
              MethodCall methodCall,
            ) async {
              throw PlatformException(code: 'ERROR', message: 'Test error');
            });

        final result = await platform.getActiveWidgetIds();

        expect(result, isEmpty);
      });
    });
  });
}
