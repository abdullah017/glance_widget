import 'package:flutter_test/flutter_test.dart';
import 'package:glance_widget/src/json_path_validator.dart';
import 'package:glance_widget_platform_interface/glance_widget_platform_interface.dart';

void main() {
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

    test('an expression the heuristic does not know is passed through', () {
      // A filter expression is valid JSONPath that `_basicPattern` does not
      // cover; rejecting it here would break a caller the native parser
      // would have served.
      expect(
        () => JsonPathValidator.validate(r'$.store.book[?(@.price < 10)]'),
        returnsNormally,
      );
      expect(() => JsonPathValidator.validate(r'$..author'), returnsNormally);
    });
  });
}
