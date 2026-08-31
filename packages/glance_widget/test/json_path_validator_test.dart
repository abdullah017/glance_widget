import 'package:flutter_test/flutter_test.dart';
import 'package:glance_widget/src/json_path_validator.dart';
import 'package:glance_widget/src/glance_config.dart';
import 'package:glance_widget_platform_interface/glance_widget_platform_interface.dart';

void main() {
  tearDown(() {
    GlanceConfig.strictMode = false;
  });

  group('JsonPathValidator', () {
    test('empty path always throws', () {
      expect(
        () => JsonPathValidator.validate(''),
        throwsA(isA<GlanceWidgetValidationException>()),
      );
    });

    test('path not starting with \$ always throws', () {
      expect(
        () => JsonPathValidator.validate('bitcoin.usd'),
        throwsA(isA<GlanceWidgetValidationException>()),
      );
    });

    test('valid simple paths pass', () {
      expect(() => JsonPathValidator.validate(r'$.bitcoin'), returnsNormally);
      expect(
        () => JsonPathValidator.validate(r'$.bitcoin.usd'),
        returnsNormally,
      );
      expect(() => JsonPathValidator.validate(r'$.data[0]'), returnsNormally);
      expect(() => JsonPathValidator.validate(r'$.store.*'), returnsNormally);
      expect(() => JsonPathValidator.validate(r'$.items[*]'), returnsNormally);
    });

    test(
      'non-standard path with strictMode=false logs warning but does not throw',
      () {
        GlanceConfig.strictMode = false;
        expect(
          () => JsonPathValidator.validate(r'$.store.book[?(@.price < 10)]'),
          returnsNormally,
        );
      },
    );

    test('non-standard path with strictMode=true throws', () {
      GlanceConfig.strictMode = true;
      expect(
        () => JsonPathValidator.validate(r'$.store.book[?(@.price < 10)]'),
        throwsA(isA<GlanceWidgetValidationException>()),
      );
    });
  });
}
