import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glance_widget_platform_interface/glance_widget_platform_interface.dart';

/// Reading a widget back is the one call whose answer the plugin wrote itself,
/// so the failure that matters is not "the platform said no" -- it is the two
/// platforms and Dart disagreeing quietly about the format.
///
/// The record crosses as a JSON string on purpose: Android's JSON reader hands
/// back every number as a double once the static type is `Object`, and the
/// standard codec would nest the maps as `Map<Object?, Object?>`. What is
/// tested here is that Dart decodes what either platform wrote, and that the
/// three possible answers -- data, nothing, and something unreadable -- stay
/// three answers.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel('dev.glance.widget/methods');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  late List<MethodCall> log;
  late MethodChannelGlanceWidget platform;

  /// Answers `getWidgetData` with [record], the way both platforms do.
  void mockRecord(String? record) {
    messenger.setMockMethodCallHandler(channel, (MethodCall call) async {
      log.add(call);
      return record;
    });
  }

  setUp(() {
    log = <MethodCall>[];
    platform = MethodChannelGlanceWidget();
  });

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  String encode(
    WidgetData data, {
    String widgetId = 'btc',
    int updatedAt = 1,
  }) => jsonEncode(<String, Object?>{
    'widgetId': widgetId,
    'template': data.template.name,
    'updatedAt': updatedAt,
    'data': data.toMap(),
  });

  group('the call', () {
    test('asks for one widget by id', () async {
      mockRecord(null);
      await platform.getWidgetData('btc');

      expect(log, hasLength(1));
      expect(log.single.method, 'getWidgetData');
      expect(log.single.arguments, <String, Object?>{'widgetId': 'btc'});
    });

    test('an empty id is rejected before the channel', () async {
      mockRecord(null);
      await expectLater(
        platform.getWidgetData(''),
        throwsA(isA<GlanceWidgetValidationException>()),
      );
      expect(log, isEmpty);
    });
  });

  group('what comes back', () {
    test('a widget that was written reads back as what was sent', () async {
      const data = SimpleWidgetData(
        title: 'Bitcoin',
        value: r'$64,120',
        subtitle: '+2.4%',
      );
      mockRecord(encode(data, widgetId: 'btc', updatedAt: 1756000000000));

      final snapshot = await platform.getWidgetData('btc');

      expect(snapshot, isNotNull);
      expect(snapshot!.widgetId, 'btc');
      expect(snapshot.template, GlanceTemplate.simple);
      expect(snapshot.data, isA<SimpleWidgetData>());
      expect((snapshot.data as SimpleWidgetData).value, r'$64,120');
      expect(
        snapshot.updatedAt,
        DateTime.fromMillisecondsSinceEpoch(1756000000000),
      );
    });

    test('a widget that was never written reads back as nothing', () async {
      mockRecord(null);
      expect(await platform.getWidgetData('never-written'), isNull);
    });

    test('a record this version cannot read is not "nothing"', () async {
      // An app downgraded below the plugin that wrote the record. Answering
      // null here would tell the caller the widget is blank and safe to
      // overwrite, which is the opposite of what is on the screen.
      mockRecord(
        jsonEncode(<String, Object?>{
          'widgetId': 'btc',
          'template': 'hologram',
          'updatedAt': 1,
          'data': <String, Object?>{},
        }),
      );

      await expectLater(
        platform.getWidgetData('btc'),
        throwsA(isA<GlanceWidgetFormatException>()),
      );
    });
  });

  group('a platform failure', () {
    test('is reported with the context of what was being read', () async {
      messenger.setMockMethodCallHandler(channel, (MethodCall call) async {
        throw PlatformException(code: 'APP_GROUP_ACCESS_ERROR', message: 'no');
      });

      await expectLater(
        platform.getWidgetData('btc'),
        throwsA(
          isA<GlanceWidgetException>()
              .having((e) => e.code, 'code', 'APP_GROUP_ACCESS_ERROR')
              .having(
                (e) => e.message,
                'message',
                contains('Failed to read widget data'),
              ),
        ),
      );
    });
  });
}
