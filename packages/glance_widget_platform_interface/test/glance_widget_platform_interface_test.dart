import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:glance_widget_platform_interface/glance_widget_platform_interface.dart';
import 'support/payload.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GlanceWidgetPlatform', () {
    test('default instance is MethodChannelGlanceWidget', () {
      expect(GlanceWidgetPlatform.instance, isA<MethodChannelGlanceWidget>());
    });

    test('cannot be implemented with `implements`', () {
      expect(() {
        GlanceWidgetPlatform.instance = _InvalidImplementation();
      }, throwsA(isA<AssertionError>()));
    });
  });

  group('GlanceTheme', () {
    test('dark theme factory creates dark theme', () {
      final theme = GlanceTheme.dark();
      expect(theme.isDark, true);
    });

    test('light theme factory creates light theme', () {
      final theme = GlanceTheme.light();
      expect(theme.isDark, false);
    });

    test('toMap returns all required keys', () {
      final theme = GlanceTheme.dark();
      final map = theme.toMap();

      expect(map.containsKey('backgroundColor'), true);
      expect(map.containsKey('textColor'), true);
      expect(map.containsKey('secondaryTextColor'), true);
      expect(map.containsKey('accentColor'), true);
      expect(map.containsKey('borderRadius'), true);
      expect(map.containsKey('isDark'), true);
    });
  });

  group('SimpleWidgetData', () {
    test('toMap includes required fields', () {
      const data = SimpleWidgetData(title: 'Test', value: '100');
      final map = data.toMap();

      expect(map['title'], 'Test');
      expect(map['value'], '100');
    });
  });

  group('ProgressWidgetData', () {
    test('toMap includes progress value', () {
      const data = ProgressWidgetData(title: 'Loading', progress: 0.5);
      final map = data.toMap();

      expect(map['title'], 'Loading');
      expect(map['progress'], 0.5);
    });

    test('progressType defaults to circular', () {
      const data = ProgressWidgetData(title: 'Test', progress: 0.5);
      expect(data.progressType, ProgressType.circular);
    });
  });

  group('ListWidgetData', () {
    test('toMap includes items', () {
      const data = ListWidgetData(
        title: 'Tasks',
        items: [GlanceListItem(text: 'Item 1')],
      );
      final map = data.toMap();

      expect(map['title'], 'Tasks');
      expect(map.childList('items').length, 1);
    });
  });

  group('GlanceWidgetAction', () {
    test('fromMap parses tap action', () {
      final action = GlanceWidgetAction.fromMap({
        'widgetId': 'test',
        'type': 'tap',
        'timestamp': 1234567890,
      });

      expect(action.widgetId, 'test');
      expect(action.type, GlanceActionType.tap);
    });

    test('fromMap parses itemTap action', () {
      final action = GlanceWidgetAction.fromMap({
        'widgetId': 'test',
        'type': 'itemTap',
        'timestamp': 1234567890,
        'payload': {'index': 0},
      });

      expect(action.type, GlanceActionType.itemTap);
      expect(action.payload?['index'], 0);
    });
  });

  group('GlanceWidgetException', () {
    test('stores message', () {
      const exception = GlanceWidgetException('Test error');
      expect(exception.message, 'Test error');
    });

    test('stores code when provided', () {
      const exception = GlanceWidgetException('Error', code: 'TEST_CODE');
      expect(exception.code, 'TEST_CODE');
    });
  });

  group('ImageWidgetData', () {
    test('toMap includes required fields', () {
      const data = ImageWidgetData(title: 'Photo');
      final map = data.toMap();

      expect(map['title'], 'Photo');
      expect(map['fit'], 'cover');
    });

    test('toMap includes imageUrl when provided', () {
      const data = ImageWidgetData(
        title: 'Photo',
        imageUrl: 'https://example.com/img.png',
      );
      final map = data.toMap();

      expect(map['imageUrl'], 'https://example.com/img.png');
    });

    test('toMap includes imageBase64 when provided', () {
      const data = ImageWidgetData(title: 'Photo', imageBase64: 'base64data');
      final map = data.toMap();

      expect(map['imageBase64'], 'base64data');
    });

    test('toMap serializes all fit values', () {
      const coverData = ImageWidgetData(title: 'T', fit: ImageFit.cover);
      expect(coverData.toMap()['fit'], 'cover');

      const containData = ImageWidgetData(title: 'T', fit: ImageFit.contain);
      expect(containData.toMap()['fit'], 'contain');

      const fillData = ImageWidgetData(title: 'T', fit: ImageFit.fill);
      expect(fillData.toMap()['fit'], 'fill');
    });

    test('toMap includes subtitle when provided', () {
      const data = ImageWidgetData(title: 'Photo', subtitle: 'A caption');
      final map = data.toMap();

      expect(map['subtitle'], 'A caption');
    });

    test('toMap has null values for optional fields when not set', () {
      const data = ImageWidgetData(title: 'Photo');
      final map = data.toMap();

      expect(map['imageUrl'], isNull);
      expect(map['imageBase64'], isNull);
      expect(map['subtitle'], isNull);
    });

    test('default fit is cover', () {
      const data = ImageWidgetData(title: 'Photo');
      expect(data.fit, ImageFit.cover);
    });
  });

  group('ChartWidgetData', () {
    test('toMap includes required fields', () {
      const data = ChartWidgetData(
        title: 'Sales',
        dataPoints: [10.0, 20.0, 30.0],
      );
      final map = data.toMap();

      expect(map['title'], 'Sales');
      expect(map['dataPoints'], [10.0, 20.0, 30.0]);
      expect(map['chartType'], 'line');
    });

    test('toMap serializes all chart types', () {
      const lineData = ChartWidgetData(
        title: 'T',
        dataPoints: [1.0],
        chartType: ChartType.line,
      );
      expect(lineData.toMap()['chartType'], 'line');

      const barData = ChartWidgetData(
        title: 'T',
        dataPoints: [1.0],
        chartType: ChartType.bar,
      );
      expect(barData.toMap()['chartType'], 'bar');

      const sparklineData = ChartWidgetData(
        title: 'T',
        dataPoints: [1.0],
        chartType: ChartType.sparkline,
      );
      expect(sparklineData.toMap()['chartType'], 'sparkline');
    });

    test('toMap includes color when provided', () {
      const data = ChartWidgetData(
        title: 'Sales',
        dataPoints: [10.0],
        color: Color(0xFF00FF00),
      );
      final map = data.toMap();

      expect(map['color'], 0xFF00FF00);
    });

    test('toMap includes subtitle when provided', () {
      const data = ChartWidgetData(
        title: 'Sales',
        dataPoints: [10.0],
        subtitle: 'Monthly revenue',
      );
      final map = data.toMap();

      expect(map['subtitle'], 'Monthly revenue');
    });

    test('toMap has null values for optional fields when not set', () {
      const data = ChartWidgetData(title: 'Sales', dataPoints: [1.0]);
      final map = data.toMap();

      expect(map['color'], isNull);
      expect(map['subtitle'], isNull);
    });

    test('default chartType is line', () {
      const data = ChartWidgetData(title: 'T', dataPoints: [1.0]);
      expect(data.chartType, ChartType.line);
    });
  });

  group('CalendarWidgetData', () {
    test('toMap includes required fields', () {
      final date = DateTime(2026, 3, 10);
      final data = CalendarWidgetData(
        title: 'Today',
        date: date,
        events: const [],
      );
      final map = data.toMap();

      expect(map['title'], 'Today');
      expect(map['date'], date.toIso8601String());
      expect(map['events'], isEmpty);
      expect(map['maxEvents'], 5);
    });

    test('toMap serializes date as ISO8601', () {
      final date = DateTime(2026, 12, 25, 14, 30, 0);
      final data = CalendarWidgetData(
        title: 'Christmas',
        date: date,
        events: const [],
      );
      final map = data.toMap();

      expect(map['date'], date.toIso8601String());
    });

    test('toMap serializes events correctly', () {
      final data = CalendarWidgetData(
        title: 'Today',
        date: DateTime(2026, 3, 10),
        events: const [
          CalendarEvent(time: '09:00', title: 'Standup'),
          CalendarEvent(
            time: 'All Day',
            title: 'Birthday',
            isAllDay: true,
            color: Color(0xFFFF0000),
          ),
        ],
      );
      final map = data.toMap();
      final events = map.childList('events');

      expect(events.length, 2);
      expect(events[0]['time'], '09:00');
      expect(events[0]['title'], 'Standup');
      expect(events[0]['isAllDay'], false);
      expect(events[1]['isAllDay'], true);
      expect(events[1]['color'], 0xFFFF0000);
    });

    test('toMap includes maxEvents', () {
      final data = CalendarWidgetData(
        title: 'Today',
        date: DateTime(2026, 3, 10),
        events: const [],
        maxEvents: 8,
      );
      final map = data.toMap();

      expect(map['maxEvents'], 8);
    });

    test('default maxEvents is 5', () {
      final data = CalendarWidgetData(
        title: 'Today',
        date: DateTime(2026, 3, 10),
        events: const [],
      );
      expect(data.maxEvents, 5);
    });

    test('CalendarEvent toMap includes all fields', () {
      const event = CalendarEvent(
        time: '14:30',
        title: 'Meeting',
        color: Color(0xFF0000FF),
        isAllDay: false,
      );
      final map = event.toMap();

      expect(map['time'], '14:30');
      expect(map['title'], 'Meeting');
      expect(map['color'], 0xFF0000FF);
      expect(map['isAllDay'], false);
    });

    test('CalendarEvent toMap has null color when not set', () {
      const event = CalendarEvent(time: '09:00', title: 'Call');
      final map = event.toMap();

      expect(map['color'], isNull);
    });

    test('CalendarEvent default isAllDay is false', () {
      const event = CalendarEvent(time: '10:00', title: 'Task');
      expect(event.isAllDay, false);
    });
  });

  group('GaugeWidgetData', () {
    test('toMap includes required fields', () {
      const data = GaugeWidgetData(
        title: 'Performance',
        metrics: [GaugeMetric(label: 'CPU', value: 65.0, maxValue: 100.0)],
      );
      final map = data.toMap();

      expect(map['title'], 'Performance');
      expect(map['gaugeType'], 'radial');
      expect(map['metrics'], isA<List<Object?>>());
      expect(map.childList('metrics').length, 1);
    });

    test('toMap serializes all gauge types', () {
      const radialData = GaugeWidgetData(
        title: 'T',
        metrics: [GaugeMetric(label: 'X', value: 1.0, maxValue: 10.0)],
        gaugeType: GaugeType.radial,
      );
      expect(radialData.toMap()['gaugeType'], 'radial');

      const dashboardData = GaugeWidgetData(
        title: 'T',
        metrics: [GaugeMetric(label: 'X', value: 1.0, maxValue: 10.0)],
        gaugeType: GaugeType.dashboard,
      );
      expect(dashboardData.toMap()['gaugeType'], 'dashboard');
    });

    test('toMap serializes metrics correctly', () {
      const data = GaugeWidgetData(
        title: 'System',
        metrics: [
          GaugeMetric(
            label: 'CPU',
            value: 75.0,
            maxValue: 100.0,
            color: Color(0xFFFF0000),
            unit: '%',
          ),
          GaugeMetric(label: 'RAM', value: 8.0, maxValue: 16.0, unit: 'GB'),
        ],
      );
      final map = data.toMap();
      final metrics = map.childList('metrics');

      expect(metrics.length, 2);
      expect(metrics[0]['label'], 'CPU');
      expect(metrics[0]['value'], 75.0);
      expect(metrics[0]['maxValue'], 100.0);
      expect(metrics[0]['color'], 0xFFFF0000);
      expect(metrics[0]['unit'], '%');
      expect(metrics[1]['label'], 'RAM');
      expect(metrics[1]['color'], isNull);
    });

    test('default gaugeType is radial', () {
      const data = GaugeWidgetData(
        title: 'T',
        metrics: [GaugeMetric(label: 'X', value: 1.0, maxValue: 10.0)],
      );
      expect(data.gaugeType, GaugeType.radial);
    });

    test('GaugeMetric toMap includes all fields', () {
      const metric = GaugeMetric(
        label: 'Speed',
        value: 120.0,
        maxValue: 200.0,
        color: Color(0xFF00FF00),
        unit: 'km/h',
      );
      final map = metric.toMap();

      expect(map['label'], 'Speed');
      expect(map['value'], 120.0);
      expect(map['maxValue'], 200.0);
      expect(map['color'], 0xFF00FF00);
      expect(map['unit'], 'km/h');
    });

    test('GaugeMetric toMap has null optional fields when not set', () {
      const metric = GaugeMetric(label: 'X', value: 1.0, maxValue: 10.0);
      final map = metric.toMap();

      expect(map['color'], isNull);
      expect(map['unit'], isNull);
    });
  });
}

class _InvalidImplementation implements GlanceWidgetPlatform {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
