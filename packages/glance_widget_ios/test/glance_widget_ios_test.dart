import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glance_widget_ios/glance_widget_ios.dart';
import 'package:glance_widget_platform_interface/glance_widget_platform_interface.dart';

/// Every call this implementation makes must land on the shared channel, under
/// the exact name the Swift side switches on. A test that only checks the class
/// hierarchy would pass just as happily if a method forwarded to the wrong one.
const MethodChannel _channel = MethodChannel('dev.glance.widget/methods');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<MethodCall> log;
  late GlanceWidgetIos ios;
  Object? Function(MethodCall call)? respond;

  setUp(() {
    log = <MethodCall>[];
    respond = null;
    ios = GlanceWidgetIos();
    MethodChannelGlanceWidget.throwOnError = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (MethodCall call) async {
          log.add(call);
          final Object? Function(MethodCall)? custom = respond;
          if (custom != null) return custom(call);
          return switch (call.method) {
            'getActiveWidgetIds' => <String>['home'],
            'getWidgetPushToken' => 'apns-token',
            'getBackgroundUpdateStatus' => <String, Object?>{'enabled': false},
            _ => true,
          };
        });
  });

  tearDown(() {
    MethodChannelGlanceWidget.throwOnError = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
  });

  group('registration', () {
    test('extends GlanceWidgetPlatform', () {
      expect(ios, isA<GlanceWidgetPlatform>());
    });

    test('registerWith installs itself as the platform instance', () {
      GlanceWidgetIos.registerWith();
      expect(GlanceWidgetPlatform.instance, isA<GlanceWidgetIos>());
    });
  });

  group('template updates reach the channel', () {
    test('updateSimpleWidget forwards id, data and theme', () async {
      await ios.updateSimpleWidget(
        widgetId: 'w1',
        data: const SimpleWidgetData(title: 'Bitcoin', value: r'$64,120'),
        theme: GlanceTheme.light(),
      );

      expect(log.single.method, 'updateSimpleWidget');
      final args = (log.single.arguments as Map<Object?, Object?>)
          .cast<String, Object?>();
      expect(args['widgetId'], 'w1');
      expect((args['data']! as Map<Object?, Object?>)['value'], r'$64,120');
      expect(args['theme'], isNotNull);
    });

    test('each template calls its own channel method', () async {
      await ios.updateProgressWidget(
        widgetId: 'p',
        data: const ProgressWidgetData(title: 'Download', progress: 0.5),
      );
      await ios.updateListWidget(
        widgetId: 'l',
        data: const ListWidgetData(title: 'Todo', items: <GlanceListItem>[]),
      );
      await ios.updateImageWidget(
        widgetId: 'i',
        data: const ImageWidgetData(title: 'Photo', imageUrl: 'u'),
      );

      expect(log.map((MethodCall c) => c.method), <String>[
        'updateProgressWidget',
        'updateListWidget',
        'updateImageWidget',
      ]);
    });
  });

  group('WidgetKit-specific surface', () {
    test(
      'getWidgetPushToken returns the token the platform reported',
      () async {
        expect(await ios.getWidgetPushToken(), 'apns-token');
        expect(log.single.method, 'getWidgetPushToken');
        expect(log.single.arguments, isNull);
      },
    );

    test('configureTimelineRefresh sends the default interval', () async {
      await ios.configureTimelineRefresh(widgetId: 'w1');

      expect(log.single.method, 'configureTimelineRefresh');
      final args = (log.single.arguments as Map<Object?, Object?>)
          .cast<String, Object?>();
      expect(args['widgetId'], 'w1');
      expect(args['intervalMinutes'], 30);
    });

    test('configureTimelineRefresh sends an explicit interval', () async {
      await ios.configureTimelineRefresh(widgetId: 'w1', intervalMinutes: 5);

      final args = (log.single.arguments as Map<Object?, Object?>)
          .cast<String, Object?>();
      expect(args['intervalMinutes'], 5);
    });

    test('cancelTimelineRefresh passes the id positionally', () async {
      await ios.cancelTimelineRefresh('w1');

      expect(log.single.method, 'cancelTimelineRefresh');
    });
  });

  group('platform failures', () {
    setUp(() {
      respond = (MethodCall call) =>
          throw PlatformException(code: 'UNAVAILABLE', message: 'no widget');
    });

    test('a failed update reports false by default', () async {
      expect(
        await ios.updateSimpleWidget(
          widgetId: 'w1',
          data: const SimpleWidgetData(title: 'T', value: 'V'),
        ),
        isFalse,
      );
    });

    test(
      'throwOnError surfaces the failure instead of swallowing it',
      () async {
        MethodChannelGlanceWidget.throwOnError = true;

        await expectLater(
          ios.updateSimpleWidget(
            widgetId: 'w1',
            data: const SimpleWidgetData(title: 'T', value: 'V'),
          ),
          throwsA(isA<GlanceWidgetException>()),
        );
      },
    );
  });
}
