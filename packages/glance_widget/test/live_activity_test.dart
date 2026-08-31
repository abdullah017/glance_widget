import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glance_widget_platform_interface/glance_widget_platform_interface.dart';

/// A Live Activity is the one surface in this plugin that exists on exactly
/// one platform. Everything else has an Android answer and an iOS answer;
/// Android's nearest equivalent to a Live Activity is a notification, which is
/// not something a widget plugin can stand in for.
///
/// So the contract under test is as much about what happens on the platform
/// that cannot do it as about the one that can.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel('dev.glance.widget/methods');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  late List<MethodCall> log;
  late MethodChannelGlanceWidget platform;

  /// Answers every Live Activity call the way iOS does.
  void mockIos({bool enabled = true, bool running = false}) {
    messenger.setMockMethodCallHandler(channel, (MethodCall call) async {
      log.add(call);
      if (call.method == 'areLiveActivitiesEnabled') return enabled;
      if (call.method == 'isLiveActivityRunning') return running;
      return true;
    });
  }

  /// Answers the way a platform with no implementation does: Android's plugin
  /// falls through to `result.notImplemented()`, which Flutter delivers as a
  /// [MissingPluginException].
  void mockUnimplemented() {
    messenger.setMockMethodCallHandler(channel, (MethodCall call) async {
      log.add(call);
      throw MissingPluginException(
        'No implementation found for method ${call.method}',
      );
    });
  }

  setUp(() {
    log = <MethodCall>[];
    platform = MethodChannelGlanceWidget();
  });

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  const content = LiveActivityContent(
    title: 'Order on its way',
    status: '12 min away',
    progress: 0.4,
    stats: {'Driver': 'Sam', 'Items': '3'},
  );

  group('the wire format', () {
    test('start sends the id and the content', () async {
      mockIos();
      await platform.startLiveActivity(
        activityId: 'delivery-42',
        content: content,
      );

      expect(log.single.method, 'startLiveActivity');
      final args = log.single.arguments as Map<Object?, Object?>;
      expect(args['activityId'], 'delivery-42');
      final sent = args['content']! as Map<Object?, Object?>;
      expect(sent['title'], 'Order on its way');
      expect(sent['status'], '12 min away');
      expect(sent['progress'], 0.4);
    });

    test('stats cross as an ordered list, not a map', () async {
      // Insertion order is the drawing order, and a map has no order to carry
      // across the channel. Written Driver-then-Items, drawn Driver-then-Items.
      mockIos();
      await platform.startLiveActivity(
        activityId: 'delivery-42',
        content: content,
      );

      final args = log.single.arguments as Map<Object?, Object?>;
      final sent = args['content']! as Map<Object?, Object?>;
      final stats = (sent['stats']! as List<Object?>)
          .cast<Map<Object?, Object?>>();
      expect(stats.map((s) => s['label']).toList(), <String>[
        'Driver',
        'Items',
      ]);
      expect(stats.map((s) => s['value']).toList(), <String>['Sam', '3']);
    });

    test('an omitted progress is left out rather than sent as null', () async {
      mockIos();
      await platform.startLiveActivity(
        activityId: 'd',
        content: const LiveActivityContent(title: 'T', status: 'S'),
      );

      final args = log.single.arguments as Map<Object?, Object?>;
      final sent = args['content']! as Map<Object?, Object?>;
      expect(sent.containsKey('progress'), isFalse);
      expect(sent['stats'], isEmpty);
    });

    test('end sends its dismissal and may omit the content', () async {
      mockIos();
      await platform.endLiveActivity(activityId: 'delivery-42');

      final args = log.single.arguments as Map<Object?, Object?>;
      expect(args['dismissal'], 'standard');
      expect(args.containsKey('content'), isFalse);
    });

    test('end carries a final state when one is given', () async {
      mockIos();
      await platform.endLiveActivity(
        activityId: 'delivery-42',
        content: const LiveActivityContent(title: 'Order', status: 'Delivered'),
        dismissal: LiveActivityDismissal.immediate,
      );

      final args = log.single.arguments as Map<Object?, Object?>;
      expect(args['dismissal'], 'immediate');
      expect(
        (args['content']! as Map<Object?, Object?>)['status'],
        'Delivered',
      );
    });
  });

  group('a platform that has no Live Activities', () {
    test('start throws UnsupportedError rather than doing nothing', () async {
      mockUnimplemented();

      await expectLater(
        platform.startLiveActivity(activityId: 'd', content: content),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('update throws UnsupportedError', () async {
      mockUnimplemented();

      await expectLater(
        platform.updateLiveActivity(activityId: 'd', content: content),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('end throws UnsupportedError', () async {
      mockUnimplemented();

      await expectLater(
        platform.endLiveActivity(activityId: 'd'),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('the availability query answers false instead of throwing', () async {
      // This is what a caller is told to branch on, so it has to be safe to
      // call anywhere. A throw here would mean wrapping the guard in a guard.
      mockUnimplemented();

      expect(await platform.areLiveActivitiesEnabled(), isFalse);
    });
  });

  group('a running activity', () {
    test('is asked about rather than remembered', () async {
      // An activity survives the process that started it, so an app resuming
      // with work in flight has to ask. The answer decides between calling
      // update and calling start.
      mockIos(running: true);

      expect(await platform.isLiveActivityRunning('delivery-42'), isTrue);
      expect(log.single.method, 'isLiveActivityRunning');
      expect(
        (log.single.arguments as Map<Object?, Object?>)['activityId'],
        'delivery-42',
      );
    });

    test('answers false when there is none', () async {
      mockIos();
      expect(await platform.isLiveActivityRunning('delivery-42'), isFalse);
    });

    test(
      'answers false rather than throwing where there are none at all',
      () async {
        mockUnimplemented();
        expect(await platform.isLiveActivityRunning('delivery-42'), isFalse);
      },
    );

    test('an empty activityId is refused', () async {
      mockIos();
      await expectLater(
        platform.isLiveActivityRunning(''),
        throwsA(isA<GlanceWidgetValidationException>()),
      );
      expect(log, isEmpty);
    });
  });

  group('availability', () {
    test('reports what the platform says', () async {
      mockIos();
      expect(await platform.areLiveActivitiesEnabled(), isTrue);
    });

    test('reports false when the user has turned them off', () async {
      mockIos(enabled: false);
      expect(await platform.areLiveActivitiesEnabled(), isFalse);
    });
  });

  group('a platform error', () {
    test('surfaces as a GlanceWidgetException, not an UnsupportedError', () {
      // LIVE_ACTIVITY_NOT_FOUND means iOS tried and could not; that is a
      // different thing from a platform that has no Live Activities, and a
      // caller has to be able to tell them apart.
      messenger.setMockMethodCallHandler(channel, (MethodCall call) async {
        throw PlatformException(
          code: 'LIVE_ACTIVITY_NOT_FOUND',
          message: 'No running activity has that activityId.',
        );
      });

      expect(
        platform.updateLiveActivity(activityId: 'gone', content: content),
        throwsA(
          isA<GlanceWidgetException>().having(
            (e) => e.code,
            'code',
            'LIVE_ACTIVITY_NOT_FOUND',
          ),
        ),
      );
    });
  });

  group('validation happens before the channel', () {
    setUp(mockIos);

    test('an empty activityId is refused', () async {
      await expectLater(
        platform.startLiveActivity(activityId: '', content: content),
        throwsA(isA<GlanceWidgetValidationException>()),
      );
      expect(log, isEmpty);
    });

    test('an empty title is refused', () async {
      await expectLater(
        platform.startLiveActivity(
          activityId: 'd',
          content: const LiveActivityContent(title: '', status: 'S'),
        ),
        throwsA(
          isA<GlanceWidgetValidationException>().having(
            (e) => e.field,
            'field',
            'title',
          ),
        ),
      );
      expect(log, isEmpty);
    });

    test('a progress outside 0..1 is refused', () async {
      await expectLater(
        platform.startLiveActivity(
          activityId: 'd',
          content: const LiveActivityContent(
            title: 'T',
            status: 'S',
            progress: 1.5,
          ),
        ),
        throwsA(
          isA<GlanceWidgetValidationException>().having(
            (e) => e.field,
            'field',
            'progress',
          ),
        ),
      );
      expect(log, isEmpty);
    });

    test('a NaN progress is refused', () async {
      await expectLater(
        platform.startLiveActivity(
          activityId: 'd',
          content: const LiveActivityContent(
            title: 'T',
            status: 'S',
            progress: double.nan,
          ),
        ),
        throwsA(isA<GlanceWidgetValidationException>()),
      );
    });

    test('content over ActivityKit 4KB limit is refused here', () async {
      // Over the limit, `request` throws on the native side with a message
      // that names nothing useful. Caught here, the caller is told which field
      // and by how much.
      await expectLater(
        platform.startLiveActivity(
          activityId: 'd',
          content: LiveActivityContent(
            title: 'T',
            status: 'S',
            stats: <String, String>{
              for (var i = 0; i < 200; i++) 'label$i': 'x' * 32,
            },
          ),
        ),
        throwsA(
          isA<GlanceWidgetValidationException>().having(
            (e) => e.field,
            'field',
            'content',
          ),
        ),
      );
      expect(log, isEmpty);
    });

    test('content just under the limit is allowed through', () async {
      await platform.startLiveActivity(
        activityId: 'd',
        content: LiveActivityContent(
          title: 'T',
          status: 'S',
          stats: <String, String>{'notes': 'x' * 3000},
        ),
      );

      expect(log.single.method, 'startLiveActivity');
    });

    test('end validates its final content too', () async {
      await expectLater(
        platform.endLiveActivity(
          activityId: 'd',
          content: const LiveActivityContent(title: 'T', status: ''),
        ),
        throwsA(isA<GlanceWidgetValidationException>()),
      );
      expect(log, isEmpty);
    });
  });
}
