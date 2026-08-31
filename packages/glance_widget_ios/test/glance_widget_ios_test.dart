import 'package:flutter_test/flutter_test.dart';
import 'package:glance_widget_ios/glance_widget_ios.dart';
import 'package:glance_widget_platform_interface/glance_widget_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GlanceWidgetIos', () {
    test('can be instantiated', () {
      expect(GlanceWidgetIos(), isA<GlanceWidgetIos>());
    });

    test('extends GlanceWidgetPlatform', () {
      expect(GlanceWidgetIos(), isA<GlanceWidgetPlatform>());
    });

    test('registerWith registers instance', () {
      GlanceWidgetIos.registerWith();
      expect(GlanceWidgetPlatform.instance, isA<GlanceWidgetIos>());
    });
  });
}
