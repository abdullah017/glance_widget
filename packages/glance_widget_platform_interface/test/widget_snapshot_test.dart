import 'dart:convert';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:glance_widget_platform_interface/glance_widget_platform_interface.dart';

/// Builds the record the platform stores, the same way the platform builds it:
/// the template name, the payload exactly as `toMap` produced it, and the
/// envelope around them.
String record(
  WidgetData data, {
  String widgetId = 'w1',
  int updatedAt = 1756000000000,
  GlanceTheme? theme,
}) => jsonEncode(<String, Object?>{
  'widgetId': widgetId,
  'template': data.template.name,
  'updatedAt': updatedAt,
  'data': data.toMap(),
  'theme': theme?.toMap(),
});

void main() {
  // Every template's data goes out as a map and has to come back as the same
  // map. Comparing `toMap()` rather than the objects is deliberate: the wire
  // format is the thing that has to survive, and the classes have no `==`.
  group('a round trip loses nothing', () {
    final cases = <String, WidgetData>{
      'simple': const SimpleWidgetData(
        title: 'Bitcoin',
        value: '\$64,120',
        subtitle: '+2.4%',
        subtitleColor: Color(0xFF4CAF50),
        iconName: 'bitcoin',
        iconBase64: 'AAAA',
        deepLinkUri: 'myapp://coin/btc',
      ),
      'simple with every optional left out': const SimpleWidgetData(
        title: 'Bitcoin',
        value: '\$64,120',
      ),
      'progress': const ProgressWidgetData(
        title: 'Downloading',
        progress: 0.42,
        subtitle: '3 of 7 files',
        progressType: ProgressType.linear,
        progressColor: Color(0xFF2196F3),
        trackColor: Color(0x33FFFFFF),
      ),
      'list': const ListWidgetData(
        title: 'Groceries',
        items: <GlanceListItem>[
          GlanceListItem(text: 'Milk', checked: true, iconName: 'cart'),
          GlanceListItem(text: 'Bread', secondaryText: 'sourdough'),
        ],
        showCheckboxes: true,
        maxItems: 8,
      ),
      'list with no items': const ListWidgetData(
        title: 'Groceries',
        items: <GlanceListItem>[],
      ),
      'image': const ImageWidgetData(
        title: 'Sunset',
        imageUrl: 'https://example.com/a.png',
        subtitle: 'Yesterday',
        fit: ImageFit.contain,
      ),
      'chart': const ChartWidgetData(
        title: 'Revenue',
        dataPoints: <double>[1, 2.5, 3],
        chartType: ChartType.bar,
        color: Color(0xFFFFA726),
        subtitle: 'this week',
      ),
      'calendar': CalendarWidgetData(
        title: "Today's Events",
        date: DateTime(2026, 8, 31, 9, 30),
        events: const <CalendarEvent>[
          CalendarEvent(time: '09:00', title: 'Standup'),
          CalendarEvent(
            time: 'All Day',
            title: 'Conference',
            color: Color(0xFFE91E63),
            isAllDay: true,
          ),
        ],
        maxEvents: 3,
      ),
      'gauge': const GaugeWidgetData(
        title: 'System',
        metrics: <GaugeMetric>[
          GaugeMetric(
            label: 'CPU',
            value: 41,
            maxValue: 100,
            unit: '%',
            color: Color(0xFF4CAF50),
          ),
          GaugeMetric(label: 'Disk', value: 88, maxValue: 100),
        ],
        gaugeType: GaugeType.dashboard,
      ),
    };

    cases.forEach((name, data) {
      test(name, () {
        final snapshot = GlanceWidgetSnapshot.decode(record(data));
        expect(snapshot.data.toMap(), equals(data.toMap()));
        expect(snapshot.template, data.template);
        expect(snapshot.data.runtimeType, data.runtimeType);
      });
    });
  });

  group('the envelope', () {
    const data = SimpleWidgetData(title: 'T', value: 'V');

    test('carries the id and the time of the write', () {
      final snapshot = GlanceWidgetSnapshot.decode(
        record(data, widgetId: 'btc-price', updatedAt: 1756000000000),
      );
      expect(snapshot.widgetId, 'btc-price');
      expect(
        snapshot.updatedAt,
        DateTime.fromMillisecondsSinceEpoch(1756000000000),
      );
    });

    test('carries the theme when one was sent', () {
      final theme = GlanceTheme.dark().copyWith(borderRadius: 24);
      final snapshot = GlanceWidgetSnapshot.decode(record(data, theme: theme));
      expect(snapshot.theme?.toMap(), equals(theme.toMap()));
    });

    test('has no theme when none was sent', () {
      expect(GlanceWidgetSnapshot.decode(record(data)).theme, isNull);
    });
  });

  // The two platforms encode the same value differently and neither is wrong:
  // Gson writes a Kotlin Double as `1.0`, iOS writes the same Double as `1`,
  // and an ARGB int large enough to have its high bit set comes back as a
  // double from a JSON reader that has no integer type. Reading numbers as
  // `num` is what makes one Dart parser work for both.
  group('numbers survive either platform encoder', () {
    test('an integral progress arrives as an int', () {
      final json = jsonEncode(<String, Object?>{
        'widgetId': 'w1',
        'template': 'progress',
        'updatedAt': 1756000000000,
        'data': <String, Object?>{
          'title': 'Done',
          'progress': 1,
          'progressType': 'circular',
        },
      });
      final data = GlanceWidgetSnapshot.decode(json).data as ProgressWidgetData;
      expect(data.progress, 1.0);
    });

    test('a colour written as a double is the same colour', () {
      final json = jsonEncode(<String, Object?>{
        'widgetId': 'w1',
        'template': 'simple',
        'updatedAt': 1756000000000,
        'data': <String, Object?>{
          'title': 'T',
          'value': 'V',
          'subtitleColor': 4283215696.0,
        },
      });
      final data = GlanceWidgetSnapshot.decode(json).data as SimpleWidgetData;
      expect(data.subtitleColor, const Color(0xFF4CAF50));
    });

    test('chart points written as ints are doubles', () {
      final json = jsonEncode(<String, Object?>{
        'widgetId': 'w1',
        'template': 'chart',
        'updatedAt': 1756000000000,
        'data': <String, Object?>{
          'title': 'Revenue',
          'dataPoints': <Object>[1, 2, 3],
          'chartType': 'line',
        },
      });
      final data = GlanceWidgetSnapshot.decode(json).data as ChartWidgetData;
      expect(data.dataPoints, <double>[1.0, 2.0, 3.0]);
    });
  });

  // "There is no record" is `null` and is handled by the caller of `decode`.
  // Everything here is "there is a record and I cannot read it", which must
  // never quietly become the first answer.
  group('an unreadable record fails loudly', () {
    Matcher throwsFormat(String field) => throwsA(
      isA<GlanceWidgetFormatException>()
          .having((e) => e.field, 'field', field)
          .having((e) => e.code, 'code', 'UNREADABLE_RECORD'),
    );

    test('text that is not JSON', () {
      expect(
        () => GlanceWidgetSnapshot.decode('not json'),
        throwsA(isA<GlanceWidgetFormatException>()),
      );
    });

    test('a template this version does not have', () {
      final json = jsonEncode(<String, Object?>{
        'widgetId': 'w1',
        'template': 'hologram',
        'updatedAt': 1,
        'data': <String, Object?>{},
      });
      expect(() => GlanceWidgetSnapshot.decode(json), throwsFormat('template'));
    });

    test('a record with no payload', () {
      final json = jsonEncode(<String, Object?>{
        'widgetId': 'w1',
        'template': 'simple',
        'updatedAt': 1,
      });
      expect(() => GlanceWidgetSnapshot.decode(json), throwsFormat('data'));
    });

    test('a field of the wrong type names itself', () {
      final json = jsonEncode(<String, Object?>{
        'widgetId': 'w1',
        'template': 'progress',
        'updatedAt': 1,
        'data': <String, Object?>{
          'title': 'Downloading',
          'progress': 'nearly',
          'progressType': 'circular',
        },
      });
      expect(
        () => GlanceWidgetSnapshot.decode(json),
        throwsFormat('progress.progress'),
      );
    });

    test('a bad field inside a list names its index', () {
      final json = jsonEncode(<String, Object?>{
        'widgetId': 'w1',
        'template': 'gauge',
        'updatedAt': 1,
        'data': <String, Object?>{
          'title': 'System',
          'gaugeType': 'radial',
          'metrics': <Object>[
            <String, Object?>{'label': 'CPU', 'value': 41, 'maxValue': 100},
            <String, Object?>{'label': 'Disk', 'value': 88},
          ],
        },
      });
      expect(
        () => GlanceWidgetSnapshot.decode(json),
        throwsFormat('gauge.metrics[1].maxValue'),
      );
    });

    test('an enum value from a newer plugin', () {
      final json = jsonEncode(<String, Object?>{
        'widgetId': 'w1',
        'template': 'image',
        'updatedAt': 1,
        'data': <String, Object?>{
          'title': 'Sunset',
          'imageUrl': 'https://example.com/a.png',
          'fit': 'scaleDown',
        },
      });
      expect(
        () => GlanceWidgetSnapshot.decode(json),
        throwsFormat('image.fit'),
      );
    });

    test('a date that is not a date', () {
      final json = jsonEncode(<String, Object?>{
        'widgetId': 'w1',
        'template': 'calendar',
        'updatedAt': 1,
        'data': <String, Object?>{
          'title': 'Today',
          'date': 'tomorrow',
          'events': <Object>[],
        },
      });
      expect(
        () => GlanceWidgetSnapshot.decode(json),
        throwsFormat('calendar.date'),
      );
    });
  });
}
