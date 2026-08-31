import 'package:glance_widget_platform_interface/glance_widget_platform_interface.dart';
import 'package:logging/logging.dart';

import 'glance_config.dart';

/// Validates JSONPath expressions used in background update configuration.
class JsonPathValidator {
  JsonPathValidator._();

  static final _log = Logger('GlanceWidget.JsonPathValidator');

  /// Basic JSONPath pattern: $.field, $.field[0], $.a.b.c, $.*, $[*]
  static final _basicPattern = RegExp(
    r'^\$(\.[a-zA-Z_][a-zA-Z0-9_]*|\[\d+\]|\[\*\]|\.\*)*$',
  );

  /// Validates a JSONPath expression.
  ///
  /// - Empty path always throws [GlanceWidgetValidationException].
  /// - Path not starting with `$` always throws.
  /// - Non-standard expressions: throw if [GlanceConfig.strictMode] is true,
  ///   otherwise log a warning and proceed (native parser may support them).
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
      if (GlanceConfig.strictMode) {
        throw GlanceWidgetValidationException(
          'JSONPath expression may not be valid: $path. '
              r'Supported: $.field, $.field[0], $.a.b.c, $.field[*]',
          field: 'valuePath',
          invalidValue: path,
        );
      }
      _log.warning(
        'JSONPath validation: expression may not be valid: $path. '
        'Proceeding because strictMode is disabled.',
      );
    }
  }
}
