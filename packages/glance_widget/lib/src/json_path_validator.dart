import 'package:glance_widget_platform_interface/glance_widget_platform_interface.dart';
import 'package:logging/logging.dart';

/// Validates JSONPath expressions used in background update configuration.
class JsonPathValidator {
  JsonPathValidator._();

  static final _log = Logger('GlanceWidget.JsonPathValidator');

  /// Basic JSONPath pattern, covering `\$.field`, `\$.field[0]`,
  /// `\$.a.b.c`, `\$.*` and `\$[*]`.
  static final _basicPattern = RegExp(
    r'^\$(\.[a-zA-Z_][a-zA-Z0-9_]*|\[\d+\]|\[\*\]|\.\*)*$',
  );

  /// Validates a JSONPath expression, throwing
  /// [GlanceWidgetValidationException] when it cannot be one.
  ///
  /// An empty path, or one that does not start with `$`, is rejected outright:
  /// no JSONPath parser accepts either. Anything else is only *checked against
  /// a heuristic* -- [_basicPattern] covers the common shapes, not the whole
  /// grammar, so an expression it does not recognise is logged as a warning and
  /// passed through. The native parser is the authority on what it accepts, and
  /// rejecting here would break valid expressions this pattern never learned.
  static void validate(String path) {
    if (path.isEmpty) {
      throw GlanceWidgetValidationException(
        'valuePath cannot be empty',
        field: 'valuePath',
        invalidValue: path,
      );
    }

    if (!path.startsWith(r'$')) {
      throw GlanceWidgetValidationException(
        r'JSONPath must start with $',
        field: 'valuePath',
        invalidValue: path,
      );
    }

    if (!_basicPattern.hasMatch(path)) {
      _log.warning(
        'JSONPath "$path" is not one of the shapes this package recognises '
        r'($.field, $.field[0], $.a.b.c, $.field[*]); passing it to the '
        'native parser unchanged.',
      );
    }
  }
}
