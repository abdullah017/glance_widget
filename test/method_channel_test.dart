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
            case 'setGlobalTheme':
            case 'forceRefreshAll':
              return true;
            case 'getActiveWidgetIds':
              return <String>['widget1', 'widget2'];
            case 'getWidgetPushToken':
              return 'test_push_token_abc123';
            case 'isWidgetPushSupported':
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
