import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glance_widget_platform_interface/glance_widget_platform_interface.dart';
import 'support/payload.dart';

/// Records what actually crossed the method channel.
class _Channel {
  _Channel(this.reply);

  /// Answers every call. `updateBatch` is answered with a map of per-widget
  /// failures; every other method is answered the way the plugins answer a
  /// mutation, with a bool -- `_invoke<bool>` casts the reply, so handing back
  /// the wrong shape fails inside the channel rather than in the code
  /// under test.
  final Object? Function(MethodCall call) reply;

  final calls = <MethodCall>[];

  static const _channel = MethodChannel('dev.glance.widget/methods');

  void install() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (call) async {
          calls.add(call);
          return reply(call);
        });
  }

  void remove() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
  }

  /// The number of bytes the standard codec puts on the wire for every call
  /// made so far, which is what a batch is meant to reduce.
  int get payloadBytes {
    const codec = StandardMethodCodec();
    return calls.fold(
      0,
      (total, call) => total + codec.encodeMethodCall(call).lengthInBytes,
    );
  }
}

/// Replies the way a plugin that applied everything would.
Object? _allApplied(MethodCall call) => call.method == 'updateBatch'
    ? <Object?, Object?>{'failures': <Object?>[]}
    : true;

List<GlanceWidgetUpdate> _twentyUpdates() => List.generate(
  20,
  (i) => GlanceWidgetUpdate(
    widgetId: 'widget_$i',
    data: SimpleWidgetData(title: 'Title $i', value: '$i'),
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _Channel channel;

  tearDown(() => channel.remove());

  group('updateBatch wire format', () {
    setUp(() {
      channel = _Channel(_allApplied)..install();
    });

    test('sends every update in a single call', () async {
      await GlanceWidgetPlatform.instance.updateBatch(_twentyUpdates());

      expect(channel.calls, hasLength(1));
      expect(channel.calls.single.method, 'updateBatch');
      final arguments = (channel.calls.single.arguments as Map)
          .cast<String, dynamic>();
      expect(arguments.childList('updates'), hasLength(20));
    });

    test('serialises a shared theme once, not once per widget', () async {
      await GlanceWidgetPlatform.instance.updateBatch(
        _twentyUpdates(),
        theme: GlanceTheme.dark(),
      );

      final arguments = (channel.calls.single.arguments as Map)
          .cast<String, dynamic>();
      expect(arguments['theme'], isA<Map<Object?, Object?>>());
      for (final update in arguments.childList('updates')) {
        expect(
          update.containsKey('theme'),
          isFalse,
          reason:
              'a widget without its own theme must not repeat the batch one',
        );
      }
    });

    test(
      'a per-widget theme overrides the batch theme for that widget',
      () async {
        final light = GlanceTheme.light();
        await GlanceWidgetPlatform.instance.updateBatch(<GlanceWidgetUpdate>[
          const GlanceWidgetUpdate(
            widgetId: 'a',
            data: SimpleWidgetData(title: 'A', value: '1'),
          ),
          GlanceWidgetUpdate(
            widgetId: 'b',
            data: const SimpleWidgetData(title: 'B', value: '2'),
            theme: light,
          ),
        ], theme: GlanceTheme.dark());

        final updates = (channel.calls.single.arguments as Map)
            .cast<String, dynamic>()
            .childList('updates');
        expect(updates[0].containsKey('theme'), isFalse);
        expect((updates[1]['theme']! as Map)['isDark'], false);
      },
    );

    test('carries the template so the native side can dispatch', () async {
      await GlanceWidgetPlatform.instance.updateBatch(<GlanceWidgetUpdate>[
        const GlanceWidgetUpdate(
          widgetId: 'a',
          data: SimpleWidgetData(title: 'A', value: '1'),
        ),
        const GlanceWidgetUpdate(
          widgetId: 'b',
          data: ProgressWidgetData(title: 'B', progress: 0.5),
        ),
      ]);

      final updates = (channel.calls.single.arguments as Map)
          .cast<String, dynamic>()
          .childList('updates');
      expect(updates.map((u) => u['template']), <String>['simple', 'progress']);
    });

    test('an empty batch makes no platform call at all', () async {
      await GlanceWidgetPlatform.instance.updateBatch(
        const <GlanceWidgetUpdate>[],
      );

      expect(channel.calls, isEmpty);
    });
  });

  group('updateBatch cost', () {
    setUp(() {
      channel = _Channel(_allApplied)..install();
    });

    test(
      'costs one round trip and fewer bytes than the same updates one by one',
      () async {
        final theme = GlanceTheme.dark();

        for (var i = 0; i < 20; i++) {
          await GlanceWidgetPlatform.instance.updateSimpleWidget(
            widgetId: 'widget_$i',
            data: SimpleWidgetData(title: 'Title $i', value: '$i'),
            theme: theme,
          );
        }
        final individualCalls = channel.calls.length;
        final individualBytes = channel.payloadBytes;

        channel.remove();
        channel = _Channel(_allApplied)..install();
        await GlanceWidgetPlatform.instance.updateBatch(
          _twentyUpdates(),
          theme: theme,
        );
        final batchCalls = channel.calls.length;
        final batchBytes = channel.payloadBytes;

        // Printed so the numbers are visible in CI output rather than only
        // asserted as an inequality.
        // ignore: avoid_print
        print(
          'individual: roundTrips=$individualCalls payloadBytes=$individualBytes\n'
          'batch:      roundTrips=$batchCalls payloadBytes=$batchBytes',
        );

        expect(individualCalls, 20);
        expect(batchCalls, 1);
        expect(
          batchBytes,
          lessThan(individualBytes),
          reason: 'a batch that costs more bytes has no reason to exist',
        );
      },
    );
  });

  group('updateBatch validation', () {
    setUp(() {
      channel = _Channel(_allApplied)..install();
    });

    test('one invalid entry rejects the whole batch before any call', () async {
      await expectLater(
        GlanceWidgetPlatform.instance.updateBatch(<GlanceWidgetUpdate>[
          const GlanceWidgetUpdate(
            widgetId: 'good',
            data: SimpleWidgetData(title: 'A', value: '1'),
          ),
          // No image source at all, which ImageWidgetData refuses.
          const GlanceWidgetUpdate(
            widgetId: 'bad',
            data: ImageWidgetData(title: 'B'),
          ),
        ]),
        throwsA(isA<GlanceWidgetValidationException>()),
      );

      expect(
        channel.calls,
        isEmpty,
        reason: 'a caller mistake must not half-apply to the home screen',
      );
    });

    test('an empty widgetId is refused', () async {
      await expectLater(
        GlanceWidgetPlatform.instance.updateBatch(<GlanceWidgetUpdate>[
          const GlanceWidgetUpdate(
            widgetId: '',
            data: SimpleWidgetData(title: 'A', value: '1'),
          ),
        ]),
        throwsA(
          isA<GlanceWidgetValidationException>().having(
            (e) => e.field,
            'field',
            'widgetId',
          ),
        ),
      );
      expect(channel.calls, isEmpty);
    });

    test(
      'the same widgetId twice is refused rather than silently racing',
      () async {
        await expectLater(
          GlanceWidgetPlatform.instance.updateBatch(<GlanceWidgetUpdate>[
            const GlanceWidgetUpdate(
              widgetId: 'same',
              data: SimpleWidgetData(title: 'A', value: '1'),
            ),
            const GlanceWidgetUpdate(
              widgetId: 'same',
              data: SimpleWidgetData(title: 'B', value: '2'),
            ),
          ]),
          throwsA(
            isA<GlanceWidgetValidationException>().having(
              (e) => e.field,
              'field',
              'widgetId',
            ),
          ),
        );
        expect(channel.calls, isEmpty);
      },
    );
  });

  group('updateBatch partial failure', () {
    test(
      'reports the widgets that failed and leaves the rest applied',
      () async {
        channel = _Channel(
          (_) => <Object?, Object?>{
            'failures': <Object?>[
              <Object?, Object?>{
                'widgetId': 'widget_3',
                'message': 'no widget instance on the home screen',
                'code': 'WIDGET_NOT_FOUND',
              },
            ],
          },
        )..install();

        await expectLater(
          GlanceWidgetPlatform.instance.updateBatch(_twentyUpdates()),
          throwsA(
            isA<GlanceWidgetBatchException>()
                .having((e) => e.attempted, 'attempted', 20)
                .having((e) => e.failures, 'failures', hasLength(1))
                .having(
                  (e) => e.failures.single.widgetId,
                  'failed widgetId',
                  'widget_3',
                )
                .having(
                  (e) => e.failures.single.code,
                  'failed code',
                  'WIDGET_NOT_FOUND',
                ),
          ),
        );
      },
    );

    test('a reply with no failures completes normally', () async {
      channel = _Channel(_allApplied)..install();

      await GlanceWidgetPlatform.instance.updateBatch(_twentyUpdates());
    });

    test(
      'a plugin that reports nothing is read as success, not as a crash',
      () async {
        channel = _Channel((_) => null)..install();

        await GlanceWidgetPlatform.instance.updateBatch(_twentyUpdates());
      },
    );

    test(
      'a platform error for the whole call still throws the usual exception',
      () async {
        channel = _Channel((_) {
          throw PlatformException(
            code: 'STORAGE_ERROR',
            message: 'disk is full',
          );
        })..install();

        await expectLater(
          GlanceWidgetPlatform.instance.updateBatch(_twentyUpdates()),
          throwsA(
            isA<GlanceWidgetException>()
                .having((e) => e.code, 'code', 'STORAGE_ERROR')
                .having(
                  (e) => e is GlanceWidgetBatchException,
                  'is a batch exception',
                  isFalse,
                ),
          ),
        );
      },
    );
  });
}
