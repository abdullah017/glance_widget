import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:glance_widget/glance_widget.dart';

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
      final theme = GlanceTheme(
        backgroundColor: const Color(0xFF1A1A2E),
        textColor: const Color(0xFFFFFFFF),
        secondaryTextColor: const Color(0xFFB0B0B0),
        accentColor: const Color(0xFF00D9FF),
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
      expect(map['items'], isA<List>());

      final items = map['items'] as List;
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
  });

  group('GlanceActionType', () {
    test('has tap value', () {
      expect(GlanceActionType.tap.name, 'tap');
    });

    test('has itemTap value', () {
      expect(GlanceActionType.itemTap.name, 'itemTap');
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
