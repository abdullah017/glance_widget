import 'package:flutter_test/flutter_test.dart';
import 'package:glance_widget/src/controllers/calendar_widget_controller.dart';
import 'package:glance_widget/src/controllers/chart_widget_controller.dart';
import 'package:glance_widget/src/controllers/gauge_widget_controller.dart';
import 'package:glance_widget/src/controllers/image_widget_controller.dart';
import 'package:glance_widget/src/controllers/list_widget_controller.dart';
import 'package:glance_widget/src/controllers/progress_widget_controller.dart';
import 'package:glance_widget/src/controllers/simple_widget_controller.dart';

void main() {
  group('Convenience controllers', () {
    test('SimpleWidgetController creates correctly', () {
      final ctrl = SimpleWidgetController(widgetId: 'test');
      expect(ctrl.widgetId, 'test');
      ctrl.dispose();
    });

    test('ProgressWidgetController creates correctly', () {
      final ctrl = ProgressWidgetController(widgetId: 'test');
      expect(ctrl.widgetId, 'test');
      ctrl.dispose();
    });

    test('ListWidgetController creates correctly', () {
      final ctrl = ListWidgetController(widgetId: 'test');
      expect(ctrl.widgetId, 'test');
      ctrl.dispose();
    });

    test('ImageWidgetController creates correctly', () {
      final ctrl = ImageWidgetController(widgetId: 'test');
      expect(ctrl.widgetId, 'test');
      ctrl.dispose();
    });

    test('ChartWidgetController creates correctly', () {
      final ctrl = ChartWidgetController(widgetId: 'test');
      expect(ctrl.widgetId, 'test');
      ctrl.dispose();
    });

    test('CalendarWidgetController creates correctly', () {
      final ctrl = CalendarWidgetController(widgetId: 'test');
      expect(ctrl.widgetId, 'test');
      ctrl.dispose();
    });

    test('GaugeWidgetController creates correctly', () {
      final ctrl = GaugeWidgetController(widgetId: 'test');
      expect(ctrl.widgetId, 'test');
      ctrl.dispose();
    });
  });
}
