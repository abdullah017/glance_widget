import 'package:flutter_test/flutter_test.dart';
import 'package:glance_widget_platform_interface/glance_widget_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GlanceWidgetPlatform', () {
    test('default instance is MethodChannelGlanceWidget', () {
      expect(
        GlanceWidgetPlatform.instance,
        isA<MethodChannelGlanceWidget>(),
      );
    });

    test('cannot be implemented with `implements`', () {
      expect(
        () {
          GlanceWidgetPlatform.instance = _InvalidImplementation();
        },
        throwsA(isA<AssertionError>()),
      );
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
      expect((map['items'] as List).length, 1);
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
}

class _InvalidImplementation implements GlanceWidgetPlatform {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
