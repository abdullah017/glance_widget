import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:glance_widget/glance_widget.dart';
import 'support/payload.dart';

void main() {
  group('GlanceTheme', () {
    test('dark theme has correct values', () {
      final theme = GlanceTheme.dark();
      expect(theme.isDark, true);
      expect(theme.borderRadius, 16.0);
    });

    test('light theme has correct values', () {
      final theme = GlanceTheme.light();
      expect(theme.isDark, false);
      expect(theme.borderRadius, 16.0);
    });

    test('copyWith creates new instance with updated values', () {
      final theme = GlanceTheme.dark();
      final updated = theme.copyWith(borderRadius: 24.0);
      expect(updated.borderRadius, 24.0);
      expect(updated.isDark, true);
    });

    test('copyWith preserves original values when not specified', () {
      final theme = GlanceTheme.dark();
      final updated = theme.copyWith();
      expect(updated.backgroundColor, theme.backgroundColor);
      expect(updated.textColor, theme.textColor);
      expect(updated.secondaryTextColor, theme.secondaryTextColor);
      expect(updated.accentColor, theme.accentColor);
      expect(updated.borderRadius, theme.borderRadius);
      expect(updated.isDark, theme.isDark);
    });

    test('toMap serializes all fields', () {
      final theme = GlanceTheme.dark();
      final map = theme.toMap();

      expect(map.containsKey('backgroundColor'), true);
      expect(map.containsKey('textColor'), true);
      expect(map.containsKey('secondaryTextColor'), true);
      expect(map.containsKey('accentColor'), true);
      expect(map.containsKey('borderRadius'), true);
      expect(map.containsKey('isDark'), true);
    });

    test('toMap color values are integers', () {
      const theme = GlanceTheme(
        backgroundColor: Color(0xFF1A1A2E),
        textColor: Color(0xFFFFFFFF),
        secondaryTextColor: Color(0xFFB0B0B0),
        accentColor: Color(0xFF00D9FF),
        borderRadius: 16.0,
        isDark: true,
      );
      final map = theme.toMap();

      expect(map['backgroundColor'], isA<int>());
      expect(map['textColor'], isA<int>());
      expect(map['backgroundColor'], 0xFF1A1A2E);
    });

    test('custom theme preserves all values', () {
      const customTheme = GlanceTheme(
        backgroundColor: Color(0xFF123456),
        textColor: Color(0xFF654321),
        secondaryTextColor: Color(0xFFABCDEF),
        accentColor: Color(0xFFFEDCBA),
        borderRadius: 20.0,
        isDark: true,
      );

      expect(customTheme.backgroundColor, const Color(0xFF123456));
      expect(customTheme.borderRadius, 20.0);
    });
  });

  group('SimpleWidgetData', () {
    test('creates data with required fields', () {
      const data = SimpleWidgetData(title: 'Bitcoin', value: '\$94,532');
      expect(data.title, 'Bitcoin');
      expect(data.value, '\$94,532');
      expect(data.subtitle, null);
    });

    test('creates data with all optional fields', () {
      const data = SimpleWidgetData(
        title: 'Bitcoin',
        value: '\$94,532',
        subtitle: '+2.34%',
        subtitleColor: Color(0xFF00FF00),
        iconName: 'bitcoin',
      );
      expect(data.subtitle, '+2.34%');
      expect(data.subtitleColor, const Color(0xFF00FF00));
      expect(data.iconName, 'bitcoin');
    });

    test('toMap includes all fields', () {
      const data = SimpleWidgetData(
        title: 'Bitcoin',
        value: '\$94,532',
        subtitle: '+2.34%',
      );
      final map = data.toMap();
      expect(map['title'], 'Bitcoin');
      expect(map['value'], '\$94,532');
      expect(map['subtitle'], '+2.34%');
    });

    test('toMap includes null optional fields', () {
      const data = SimpleWidgetData(title: 'Test', value: '100');
      final map = data.toMap();
      // Note: toMap includes keys even when null
      expect(map.containsKey('subtitle'), true);
      expect(map['subtitle'], isNull);
      expect(map['subtitleColor'], isNull);
      expect(map['iconName'], isNull);
    });

    test('toMap converts color to integer', () {
      const data = SimpleWidgetData(
        title: 'Test',
        value: '100',
        subtitleColor: Color(0xFF00FF00),
      );
      final map = data.toMap();
      expect(map['subtitleColor'], 0xFF00FF00);
    });
  });

  group('ProgressWidgetData', () {
    test('validates progress range', () {
      const data = ProgressWidgetData(title: 'Loading', progress: 0.5);
      expect(data.progress, 0.5);
    });

    test('default progress type is circular', () {
      const data = ProgressWidgetData(title: 'Loading', progress: 0.5);
      expect(data.progressType, ProgressType.circular);
    });

    test('linear progress type', () {
      const data = ProgressWidgetData(
        title: 'Downloading',
        progress: 0.75,
        progressType: ProgressType.linear,
      );
      expect(data.progressType, ProgressType.linear);
    });

    test('toMap serializes progress type correctly', () {
      const circularData = ProgressWidgetData(
        title: 'Test',
        progress: 0.5,
        progressType: ProgressType.circular,
      );
      expect(circularData.toMap()['progressType'], 'circular');

      const linearData = ProgressWidgetData(
        title: 'Test',
        progress: 0.5,
        progressType: ProgressType.linear,
      );
      expect(linearData.toMap()['progressType'], 'linear');
    });

    test('progress at boundary values', () {
      const zeroProgress = ProgressWidgetData(title: 'Test', progress: 0.0);
      const fullProgress = ProgressWidgetData(title: 'Test', progress: 1.0);

      expect(zeroProgress.progress, 0.0);
      expect(fullProgress.progress, 1.0);
    });

    test('toMap includes optional fields when present', () {
      const data = ProgressWidgetData(
        title: 'Download',
        progress: 0.5,
        subtitle: '50%',
        progressColor: Color(0xFF0000FF),
        trackColor: Color(0xFFCCCCCC),
      );
      final map = data.toMap();

      expect(map['subtitle'], '50%');
      expect(map['progressColor'], 0xFF0000FF);
      expect(map['trackColor'], 0xFFCCCCCC);
    });
  });

  group('ListWidgetData', () {
    test('creates list with items', () {
      const data = ListWidgetData(
        title: 'Tasks',
        items: [
          GlanceListItem(text: 'Item 1'),
          GlanceListItem(text: 'Item 2', checked: true),
        ],
      );
      expect(data.items.length, 2);
      expect(data.items[1].checked, true);
    });

    test('creates empty list', () {
      const data = ListWidgetData(title: 'Empty List', items: []);
      expect(data.items.isEmpty, true);
    });

    test('default showCheckboxes is false', () {
      const data = ListWidgetData(title: 'Test', items: []);
      expect(data.showCheckboxes, false);
    });

    test('showCheckboxes can be enabled', () {
      const data = ListWidgetData(
        title: 'Tasks',
        items: [],
        showCheckboxes: true,
      );
      expect(data.showCheckboxes, true);
    });

    test('toMap serializes items correctly', () {
      const data = ListWidgetData(
        title: 'Tasks',
        items: [
          GlanceListItem(text: 'Task 1', checked: false),
          GlanceListItem(
            text: 'Task 2',
            checked: true,
            secondaryText: 'Due today',
          ),
        ],
        showCheckboxes: true,
      );
      final map = data.toMap();

      expect(map['title'], 'Tasks');
      expect(map['showCheckboxes'], true);
      expect(map['items'], isA<List<Object?>>());

      final items = map.childList('items');
      expect(items.length, 2);
      expect(items[0]['text'], 'Task 1');
      expect(items[1]['checked'], true);
      expect(items[1]['secondaryText'], 'Due today');
    });
  });

  group('GlanceListItem', () {
    test('creates item with text only', () {
      const item = GlanceListItem(text: 'Test item');
      expect(item.text, 'Test item');
      expect(item.checked, false);
      expect(item.secondaryText, null);
    });

    test('creates item with all fields', () {
      const item = GlanceListItem(
        text: 'Main text',
        checked: true,
        secondaryText: 'Secondary text',
      );
      expect(item.text, 'Main text');
      expect(item.checked, true);
      expect(item.secondaryText, 'Secondary text');
    });

    test('toMap serializes correctly', () {
      const item = GlanceListItem(
        text: 'Test',
        checked: true,
        secondaryText: 'Details',
      );
      final map = item.toMap();

      expect(map['text'], 'Test');
      expect(map['checked'], true);
      expect(map['secondaryText'], 'Details');
    });
  });

  group('GlanceWidgetAction', () {
    test('fromMap creates action correctly', () {
      final action = GlanceWidgetAction.fromMap({
        'widgetId': 'test_widget',
        'type': 'tap',
        'timestamp': 1234567890,
      });
      expect(action.widgetId, 'test_widget');
      expect(action.type, GlanceActionType.tap);
      // timestamp is converted to DateTime
      expect(action.timestamp, isA<DateTime>());
      expect(action.timestamp.millisecondsSinceEpoch, 1234567890);
    });

    test('fromMap handles itemTap type', () {
      final action = GlanceWidgetAction.fromMap({
        'widgetId': 'list_widget',
        'type': 'itemTap',
        'timestamp': 1234567890,
        'payload': {'index': 2},
      });
      expect(action.type, GlanceActionType.itemTap);
      expect(action.payload?['index'], 2);
    });

    test('fromMap handles configure type', () {
      final action = GlanceWidgetAction.fromMap({
        'widgetId': 'new_widget',
        'type': 'configure',
        'timestamp': 1234567890,
      });
      expect(action.type, GlanceActionType.configure);
      expect(action.widgetId, 'new_widget');
    });

    test('fromMap handles unknown type as tap', () {
      final action = GlanceWidgetAction.fromMap({
        'widgetId': 'test',
        'type': 'unknownType',
        'timestamp': 0,
      });
      expect(action.type, GlanceActionType.tap);
    });

    test('fromMap handles missing payload', () {
      final action = GlanceWidgetAction.fromMap({
        'widgetId': 'test',
        'type': 'tap',
        'timestamp': 0,
      });
      expect(action.payload, null);
    });

    test('fromMap handles payload as Map', () {
      final action = GlanceWidgetAction.fromMap({
        'widgetId': 'test',
        'type': 'tap',
        'timestamp': 0,
        'payload': {'key1': 'value1', 'key2': 123},
      });
      expect(action.payload, isA<Map<String, dynamic>>());
      expect(action.payload?['key1'], 'value1');
      expect(action.payload?['key2'], 123);
    });

    test('fromMap handles checkboxToggle type with value and itemIndex', () {
      final action = GlanceWidgetAction.fromMap({
        'widgetId': 'todo_list',
        'type': 'checkboxToggle',
        'timestamp': 1234567890,
        'payload': {'itemIndex': 2, 'value': true},
      });
      expect(action.type, GlanceActionType.checkboxToggle);
      expect(action.itemIndex, 2);
      expect(action.value, true);
      expect(action.widgetId, 'todo_list');
    });

    test('fromMap handles toggle type', () {
      final action = GlanceWidgetAction.fromMap({
        'widgetId': 'settings_widget',
        'type': 'toggle',
        'timestamp': 1234567890,
        'itemId': 'dark_mode',
        'value': false,
      });
      expect(action.type, GlanceActionType.toggle);
      expect(action.itemId, 'dark_mode');
      expect(action.value, false);
    });

    test('fromMap reads itemId from top-level map', () {
      final action = GlanceWidgetAction.fromMap({
        'widgetId': 'test',
        'type': 'toggle',
        'timestamp': 0,
        'itemId': 'my_item',
      });
      expect(action.itemId, 'my_item');
    });

    test('fromMap reads itemId from payload when not top-level', () {
      final action = GlanceWidgetAction.fromMap({
        'widgetId': 'test',
        'type': 'toggle',
        'timestamp': 0,
        'payload': {'itemId': 'payload_item'},
      });
      expect(action.itemId, 'payload_item');
    });

    test('fromMap reads itemIndex from top-level map', () {
      final action = GlanceWidgetAction.fromMap({
        'widgetId': 'test',
        'type': 'checkboxToggle',
        'timestamp': 0,
        'itemIndex': 5,
      });
      expect(action.itemIndex, 5);
    });

    test('fromMap reads itemIndex from payload index field', () {
      final action = GlanceWidgetAction.fromMap({
        'widgetId': 'test',
        'type': 'itemTap',
        'timestamp': 0,
        'payload': {'index': 3},
      });
      expect(action.itemIndex, 3);
    });

    test('fromMap parses string itemIndex', () {
      final action = GlanceWidgetAction.fromMap({
        'widgetId': 'test',
        'type': 'checkboxToggle',
        'timestamp': 0,
        'itemIndex': '7',
      });
      expect(action.itemIndex, 7);
    });

    test('toMap includes new fields when present', () {
      final action = GlanceWidgetAction(
        widgetId: 'test',
        type: GlanceActionType.checkboxToggle,
        timestamp: DateTime.fromMillisecondsSinceEpoch(0),
        itemId: 'task_1',
        value: true,
        itemIndex: 0,
      );
      final map = action.toMap();
      expect(map['itemId'], 'task_1');
      expect(map['value'], true);
      expect(map['itemIndex'], 0);
    });

    test('toMap excludes new fields when null', () {
      final action = GlanceWidgetAction(
        widgetId: 'test',
        type: GlanceActionType.tap,
        timestamp: DateTime.fromMillisecondsSinceEpoch(0),
      );
      final map = action.toMap();
      expect(map.containsKey('itemId'), false);
      expect(map.containsKey('value'), false);
      expect(map.containsKey('itemIndex'), false);
    });

    test('toString includes new fields when present', () {
      final action = GlanceWidgetAction(
        widgetId: 'test',
        type: GlanceActionType.checkboxToggle,
        timestamp: DateTime.fromMillisecondsSinceEpoch(0),
        itemId: 'task_1',
        value: true,
        itemIndex: 2,
      );
      final str = action.toString();
      expect(str, contains('itemId: task_1'));
      expect(str, contains('value: true'));
      expect(str, contains('itemIndex: 2'));
    });
  });

  group('GlanceActionType', () {
    test('has tap value', () {
      expect(GlanceActionType.tap.name, 'tap');
    });

    test('has itemTap value', () {
      expect(GlanceActionType.itemTap.name, 'itemTap');
    });

    test('has checkboxToggle value', () {
      expect(GlanceActionType.checkboxToggle.name, 'checkboxToggle');
    });

    test('has toggle value', () {
      expect(GlanceActionType.toggle.name, 'toggle');
    });

    test('has refresh value', () {
      expect(GlanceActionType.refresh.name, 'refresh');
    });

    test('has configure value', () {
      expect(GlanceActionType.configure.name, 'configure');
    });

    test('contains all 6 values', () {
      expect(GlanceActionType.values.length, 6);
    });
  });

  group('GlanceTemplate', () {
    test('has simple value', () {
      expect(GlanceTemplate.simple.name, 'simple');
    });

    test('has progress value', () {
      expect(GlanceTemplate.progress.name, 'progress');
    });

    test('has list value', () {
      expect(GlanceTemplate.list.name, 'list');
    });

    test('has image value', () {
      expect(GlanceTemplate.image.name, 'image');
    });

    test('has chart value', () {
      expect(GlanceTemplate.chart.name, 'chart');
    });

    test('has calendar value', () {
      expect(GlanceTemplate.calendar.name, 'calendar');
    });

    test('has gauge value', () {
      expect(GlanceTemplate.gauge.name, 'gauge');
    });

    test('contains all 7 values', () {
      expect(GlanceTemplate.values.length, 7);
    });
  });

  group('ImageWidgetData', () {
    test('creates data with required fields', () {
      const data = ImageWidgetData(title: 'Photo');
      expect(data.title, 'Photo');
      expect(data.imageUrl, null);
      expect(data.imageBase64, null);
      expect(data.subtitle, null);
    });

    test('creates data with all optional fields', () {
      const data = ImageWidgetData(
        title: 'Photo',
        imageUrl: 'https://example.com/photo.jpg',
        imageBase64: 'base64data',
        subtitle: 'A nice photo',
        fit: ImageFit.contain,
      );
      expect(data.imageUrl, 'https://example.com/photo.jpg');
      expect(data.imageBase64, 'base64data');
      expect(data.subtitle, 'A nice photo');
      expect(data.fit, ImageFit.contain);
    });

    test('default fit is cover', () {
      const data = ImageWidgetData(title: 'Photo');
      expect(data.fit, ImageFit.cover);
    });

    test('toMap includes all fields', () {
      const data = ImageWidgetData(
        title: 'Photo',
        imageUrl: 'https://example.com/photo.jpg',
        subtitle: 'Caption',
        fit: ImageFit.fill,
      );
      final map = data.toMap();
      expect(map['title'], 'Photo');
      expect(map['imageUrl'], 'https://example.com/photo.jpg');
      expect(map['subtitle'], 'Caption');
      expect(map['fit'], 'fill');
    });

    test('toMap includes null optional fields', () {
      const data = ImageWidgetData(title: 'Photo');
      final map = data.toMap();
      expect(map.containsKey('imageUrl'), true);
      expect(map['imageUrl'], isNull);
      expect(map.containsKey('imageBase64'), true);
      expect(map['imageBase64'], isNull);
      expect(map.containsKey('subtitle'), true);
      expect(map['subtitle'], isNull);
    });

    test('toMap serializes fit correctly for all values', () {
      const coverData = ImageWidgetData(title: 'T', fit: ImageFit.cover);
      expect(coverData.toMap()['fit'], 'cover');

      const containData = ImageWidgetData(title: 'T', fit: ImageFit.contain);
      expect(containData.toMap()['fit'], 'contain');

      const fillData = ImageWidgetData(title: 'T', fit: ImageFit.fill);
      expect(fillData.toMap()['fit'], 'fill');
    });

    test('creates data with imageUrl only', () {
      const data = ImageWidgetData(
        title: 'Photo',
        imageUrl: 'https://example.com/img.png',
      );
      expect(data.imageUrl, 'https://example.com/img.png');
      expect(data.imageBase64, isNull);
    });

    test('creates data with imageBase64 only', () {
      const data = ImageWidgetData(
        title: 'Photo',
        imageBase64: 'iVBORw0KGgoAAAANSUhEUg==',
      );
      expect(data.imageUrl, isNull);
      expect(data.imageBase64, 'iVBORw0KGgoAAAANSUhEUg==');
    });

    test('toMap with imageBase64', () {
      const data = ImageWidgetData(
        title: 'Photo',
        imageBase64: 'base64content',
      );
      final map = data.toMap();
      expect(map['imageBase64'], 'base64content');
      expect(map['imageUrl'], isNull);
    });
  });

  group('ImageFit', () {
    test('has cover value', () {
      expect(ImageFit.cover.name, 'cover');
    });

    test('has contain value', () {
      expect(ImageFit.contain.name, 'contain');
    });

    test('has fill value', () {
      expect(ImageFit.fill.name, 'fill');
    });

    test('contains all 3 values', () {
      expect(ImageFit.values.length, 3);
    });
  });

  group('ChartWidgetData', () {
    test('creates data with required fields', () {
      const data = ChartWidgetData(
        title: 'Sales',
        dataPoints: [10.0, 20.0, 30.0],
      );
      expect(data.title, 'Sales');
      expect(data.dataPoints, [10.0, 20.0, 30.0]);
      expect(data.color, null);
      expect(data.subtitle, null);
    });

    test('creates data with all optional fields', () {
      const data = ChartWidgetData(
        title: 'Sales',
        dataPoints: [1.0, 2.0],
        chartType: ChartType.bar,
        color: Color(0xFF0000FF),
        subtitle: 'Monthly',
      );
      expect(data.chartType, ChartType.bar);
      expect(data.color, const Color(0xFF0000FF));
      expect(data.subtitle, 'Monthly');
    });

    test('default chartType is line', () {
      const data = ChartWidgetData(title: 'Test', dataPoints: [1.0]);
      expect(data.chartType, ChartType.line);
    });

    test('toMap includes all fields', () {
      const data = ChartWidgetData(
        title: 'Revenue',
        dataPoints: [100.0, 200.0, 150.0],
        chartType: ChartType.sparkline,
        color: Color(0xFFFF0000),
        subtitle: 'Q1 2026',
      );
      final map = data.toMap();
      expect(map['title'], 'Revenue');
      expect(map['dataPoints'], [100.0, 200.0, 150.0]);
      expect(map['chartType'], 'sparkline');
      expect(map['color'], 0xFFFF0000);
      expect(map['subtitle'], 'Q1 2026');
    });

    test('toMap includes null optional fields', () {
      const data = ChartWidgetData(title: 'Test', dataPoints: [1.0]);
      final map = data.toMap();
      expect(map.containsKey('color'), true);
      expect(map['color'], isNull);
      expect(map.containsKey('subtitle'), true);
      expect(map['subtitle'], isNull);
    });

    test('toMap serializes chartType correctly for all values', () {
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

    test('toMap converts color to integer', () {
      const data = ChartWidgetData(
        title: 'Test',
        dataPoints: [1.0],
        color: Color(0xFF00FF00),
      );
      final map = data.toMap();
      expect(map['color'], 0xFF00FF00);
    });

    test('handles single data point', () {
      const data = ChartWidgetData(title: 'Test', dataPoints: [42.0]);
      expect(data.dataPoints.length, 1);
      expect(data.dataPoints[0], 42.0);
    });

    test('handles many data points', () {
      final points = List<double>.generate(100, (i) => i.toDouble());
      final data = ChartWidgetData(title: 'Test', dataPoints: points);
      expect(data.dataPoints.length, 100);
    });

    test('handles negative data points', () {
      const data = ChartWidgetData(
        title: 'Test',
        dataPoints: [-10.0, 0.0, 10.0],
      );
      final map = data.toMap();
      expect(map['dataPoints'], [-10.0, 0.0, 10.0]);
    });
  });

  group('ChartType', () {
    test('has line value', () {
      expect(ChartType.line.name, 'line');
    });

    test('has bar value', () {
      expect(ChartType.bar.name, 'bar');
    });

    test('has sparkline value', () {
      expect(ChartType.sparkline.name, 'sparkline');
    });

    test('contains all 3 values', () {
      expect(ChartType.values.length, 3);
    });
  });

  group('CalendarWidgetData', () {
    test('creates data with required fields', () {
      final date = DateTime(2026, 3, 10);
      final data = CalendarWidgetData(
        title: 'Today',
        date: date,
        events: const [],
      );
      expect(data.title, 'Today');
      expect(data.date, date);
      expect(data.events, isEmpty);
    });

    test('creates data with events', () {
      final data = CalendarWidgetData(
        title: 'Today',
        date: DateTime(2026, 3, 10),
        events: const [
          CalendarEvent(time: '09:00', title: 'Standup'),
          CalendarEvent(time: '14:00', title: 'Review'),
        ],
      );
      expect(data.events.length, 2);
      expect(data.events[0].title, 'Standup');
      expect(data.events[1].title, 'Review');
    });

    test('default maxEvents is 5', () {
      final data = CalendarWidgetData(
        title: 'Today',
        date: DateTime(2026, 3, 10),
        events: const [],
      );
      expect(data.maxEvents, 5);
    });

    test('custom maxEvents value', () {
      final data = CalendarWidgetData(
        title: 'Today',
        date: DateTime(2026, 3, 10),
        events: const [],
        maxEvents: 3,
      );
      expect(data.maxEvents, 3);
    });

    test('maxEvents boundary values', () {
      final dataMin = CalendarWidgetData(
        title: 'Today',
        date: DateTime(2026, 3, 10),
        events: const [],
        maxEvents: 1,
      );
      expect(dataMin.maxEvents, 1);

      final dataMax = CalendarWidgetData(
        title: 'Today',
        date: DateTime(2026, 3, 10),
        events: const [],
        maxEvents: 10,
      );
      expect(dataMax.maxEvents, 10);
    });

    test('toMap includes all fields', () {
      final date = DateTime(2026, 3, 10);
      final data = CalendarWidgetData(
        title: 'Schedule',
        date: date,
        events: const [CalendarEvent(time: '09:00', title: 'Meeting')],
        maxEvents: 8,
      );
      final map = data.toMap();
      expect(map['title'], 'Schedule');
      expect(map['date'], date.toIso8601String());
      expect(map['maxEvents'], 8);
      expect(map['events'], isA<List<Object?>>());
      expect((map['events'] as List).length, 1);
    });

    test('toMap serializes date as ISO8601', () {
      final date = DateTime(2026, 12, 25, 10, 30, 0);
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
      expect(events[0]['time'], '09:00');
      expect(events[0]['title'], 'Standup');
      expect(events[1]['isAllDay'], true);
      expect(events[1]['color'], 0xFFFF0000);
    });

    test('toMap with empty events list', () {
      final data = CalendarWidgetData(
        title: 'Today',
        date: DateTime(2026, 3, 10),
        events: const [],
      );
      final map = data.toMap();
      expect(map['events'] as List, isEmpty);
    });
  });

  group('CalendarEvent', () {
    test('creates event with required fields', () {
      const event = CalendarEvent(time: '09:00', title: 'Meeting');
      expect(event.time, '09:00');
      expect(event.title, 'Meeting');
      expect(event.color, null);
      expect(event.isAllDay, false);
    });

    test('creates event with all optional fields', () {
      const event = CalendarEvent(
        time: 'All Day',
        title: 'Holiday',
        color: Color(0xFF00FF00),
        isAllDay: true,
      );
      expect(event.time, 'All Day');
      expect(event.title, 'Holiday');
      expect(event.color, const Color(0xFF00FF00));
      expect(event.isAllDay, true);
    });

    test('default isAllDay is false', () {
      const event = CalendarEvent(time: '10:00', title: 'Call');
      expect(event.isAllDay, false);
    });

    test('toMap includes all fields', () {
      const event = CalendarEvent(
        time: '14:30',
        title: 'Review',
        color: Color(0xFF0000FF),
        isAllDay: false,
      );
      final map = event.toMap();
      expect(map['time'], '14:30');
      expect(map['title'], 'Review');
      expect(map['color'], 0xFF0000FF);
      expect(map['isAllDay'], false);
    });

    test('toMap includes null color when not provided', () {
      const event = CalendarEvent(time: '10:00', title: 'Call');
      final map = event.toMap();
      expect(map.containsKey('color'), true);
      expect(map['color'], isNull);
    });

    test('toMap converts color to integer', () {
      const event = CalendarEvent(
        time: '10:00',
        title: 'Call',
        color: Color(0xFFABCDEF),
      );
      final map = event.toMap();
      expect(map['color'], 0xFFABCDEF);
    });

    test('toMap serializes isAllDay correctly', () {
      const allDayEvent = CalendarEvent(
        time: 'All Day',
        title: 'Holiday',
        isAllDay: true,
      );
      expect(allDayEvent.toMap()['isAllDay'], true);

      const timedEvent = CalendarEvent(time: '09:00', title: 'Meeting');
      expect(timedEvent.toMap()['isAllDay'], false);
    });
  });

  group('GaugeWidgetData', () {
    test('creates data with required fields', () {
      const data = GaugeWidgetData(
        title: 'Performance',
        metrics: [
          GaugeMetric(label: 'CPU', value: 65.0, maxValue: 100.0),
        ],
      );
      expect(data.title, 'Performance');
      expect(data.metrics.length, 1);
    });

    test('creates data with multiple metrics', () {
      const data = GaugeWidgetData(
        title: 'System',
        metrics: [
          GaugeMetric(label: 'CPU', value: 65.0, maxValue: 100.0),
          GaugeMetric(label: 'RAM', value: 8.0, maxValue: 16.0),
          GaugeMetric(label: 'Disk', value: 250.0, maxValue: 500.0),
        ],
      );
      expect(data.metrics.length, 3);
      expect(data.metrics[1].label, 'RAM');
    });

    test('default gaugeType is radial', () {
      const data = GaugeWidgetData(
        title: 'Test',
        metrics: [GaugeMetric(label: 'X', value: 1.0, maxValue: 10.0)],
      );
      expect(data.gaugeType, GaugeType.radial);
    });

    test('dashboard gauge type', () {
      const data = GaugeWidgetData(
        title: 'Test',
        metrics: [GaugeMetric(label: 'X', value: 1.0, maxValue: 10.0)],
        gaugeType: GaugeType.dashboard,
      );
      expect(data.gaugeType, GaugeType.dashboard);
    });

    test('toMap includes all fields', () {
      const data = GaugeWidgetData(
        title: 'Performance',
        metrics: [
          GaugeMetric(label: 'CPU', value: 65.0, maxValue: 100.0),
        ],
        gaugeType: GaugeType.dashboard,
      );
      final map = data.toMap();
      expect(map['title'], 'Performance');
      expect(map['gaugeType'], 'dashboard');
      expect(map['metrics'], isA<List<Object?>>());
      expect((map['metrics'] as List).length, 1);
    });

    test('toMap serializes gaugeType correctly for all values', () {
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
        ],
      );
      final map = data.toMap();
      final metrics = map.childList('metrics');
      expect(metrics[0]['label'], 'CPU');
      expect(metrics[0]['value'], 75.0);
      expect(metrics[0]['maxValue'], 100.0);
      expect(metrics[0]['color'], 0xFFFF0000);
      expect(metrics[0]['unit'], '%');
    });
  });

  group('GaugeMetric', () {
    test('creates metric with required fields', () {
      const metric = GaugeMetric(label: 'Speed', value: 80.0, maxValue: 200.0);
      expect(metric.label, 'Speed');
      expect(metric.value, 80.0);
      expect(metric.maxValue, 200.0);
      expect(metric.color, null);
      expect(metric.unit, null);
    });

    test('creates metric with all optional fields', () {
      const metric = GaugeMetric(
        label: 'Temperature',
        value: 72.5,
        maxValue: 120.0,
        color: Color(0xFFFF6600),
        unit: '\u00B0F',
      );
      expect(metric.color, const Color(0xFFFF6600));
      expect(metric.unit, '\u00B0F');
    });

    test('toMap includes all fields', () {
      const metric = GaugeMetric(
        label: 'CPU',
        value: 65.0,
        maxValue: 100.0,
        color: Color(0xFF0000FF),
        unit: '%',
      );
      final map = metric.toMap();
      expect(map['label'], 'CPU');
      expect(map['value'], 65.0);
      expect(map['maxValue'], 100.0);
      expect(map['color'], 0xFF0000FF);
      expect(map['unit'], '%');
    });

    test('toMap includes null optional fields', () {
      const metric = GaugeMetric(label: 'X', value: 1.0, maxValue: 10.0);
      final map = metric.toMap();
      expect(map.containsKey('color'), true);
      expect(map['color'], isNull);
      expect(map.containsKey('unit'), true);
      expect(map['unit'], isNull);
    });

    test('toMap converts color to integer', () {
      const metric = GaugeMetric(
        label: 'X',
        value: 1.0,
        maxValue: 10.0,
        color: Color(0xFFABCDEF),
      );
      final map = metric.toMap();
      expect(map['color'], 0xFFABCDEF);
    });

    test('handles zero value', () {
      const metric = GaugeMetric(label: 'Empty', value: 0.0, maxValue: 100.0);
      expect(metric.value, 0.0);
      final map = metric.toMap();
      expect(map['value'], 0.0);
    });

    test('handles value equal to maxValue', () {
      const metric = GaugeMetric(label: 'Full', value: 100.0, maxValue: 100.0);
      expect(metric.value, 100.0);
      expect(metric.maxValue, 100.0);
    });

    test('handles decimal values', () {
      const metric = GaugeMetric(
        label: 'Precise',
        value: 33.333,
        maxValue: 99.999,
      );
      final map = metric.toMap();
      expect(map['value'], 33.333);
      expect(map['maxValue'], 99.999);
    });
  });

  group('GaugeType', () {
    test('has radial value', () {
      expect(GaugeType.radial.name, 'radial');
    });

    test('has dashboard value', () {
      expect(GaugeType.dashboard.name, 'dashboard');
    });

    test('contains all 2 values', () {
      expect(GaugeType.values.length, 2);
    });
  });

  group('GlanceWidgetException', () {
    test('creates exception with message', () {
      const exception = GlanceWidgetException('Test error');
      expect(exception.message, 'Test error');
      expect(exception.code, null);
      expect(exception.originalException, null);
    });

    test('creates exception with code', () {
      const exception = GlanceWidgetException(
        'Widget not found',
        code: 'WIDGET_NOT_FOUND',
      );
      expect(exception.code, 'WIDGET_NOT_FOUND');
    });

    test('toString includes message', () {
      const exception = GlanceWidgetException('Test error');
      expect(exception.toString(), contains('Test error'));
    });

    test('toString includes code when present', () {
      const exception = GlanceWidgetException('Error', code: 'ERROR_CODE');
      expect(exception.toString(), contains('ERROR_CODE'));
    });
  });

  group('GlanceWidgetValidationException', () {
    test('creates validation exception with field', () {
      const exception = GlanceWidgetValidationException(
        'Invalid progress value',
        field: 'progress',
        invalidValue: 1.5,
      );
      expect(exception.field, 'progress');
      expect(exception.invalidValue, 1.5);
      expect(exception.code, 'VALIDATION_ERROR');
    });

    test('toString includes field when present', () {
      const exception = GlanceWidgetValidationException(
        'Invalid value',
        field: 'testField',
      );
      expect(exception.toString(), contains('testField'));
    });
  });
}
