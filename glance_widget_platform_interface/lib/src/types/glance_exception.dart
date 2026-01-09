import 'package:flutter/services.dart';

/// Exception thrown when a Glance widget operation fails.
///
/// This exception provides detailed information about what went wrong
/// during widget operations, including the original platform exception
/// if one occurred.
class GlanceWidgetException implements Exception {
  /// Creates a new [GlanceWidgetException].
  ///
  /// - [message]: A human-readable description of the error
  /// - [code]: An optional error code for programmatic handling
  /// - [originalException]: The underlying exception that caused this error
  const GlanceWidgetException(
    this.message, {
    this.code,
    this.originalException,
  });

  /// Creates a [GlanceWidgetException] from a [PlatformException].
  factory GlanceWidgetException.fromPlatformException(
    PlatformException exception, {
    String? context,
  }) {
    final contextPrefix = context != null ? '$context: ' : '';
    return GlanceWidgetException(
      '$contextPrefix${exception.message ?? 'Unknown platform error'}',
      code: exception.code,
      originalException: exception,
    );
  }

  /// A human-readable description of the error.
  final String message;

  /// An optional error code for programmatic handling.
  ///
  /// Common codes:
  /// - `WIDGET_NOT_FOUND`: The specified widget ID doesn't exist
  /// - `INVALID_DATA`: The widget data is malformed
  /// - `PLATFORM_ERROR`: A native platform error occurred
  /// - `THEME_ERROR`: Failed to apply theme
  final String? code;

  /// The underlying exception that caused this error, if any.
  final Exception? originalException;

  @override
  String toString() {
    final buffer = StringBuffer('GlanceWidgetException: $message');
    if (code != null) {
      buffer.write(' (code: $code)');
    }
    return buffer.toString();
  }
}

/// Exception thrown when a widget operation times out.
class GlanceWidgetTimeoutException extends GlanceWidgetException {
  /// Creates a new [GlanceWidgetTimeoutException].
  const GlanceWidgetTimeoutException(
    super.message, {
    this.timeoutDuration,
  }) : super(code: 'TIMEOUT');

  /// The duration that was exceeded.
  final Duration? timeoutDuration;
}

/// Exception thrown when widget data validation fails.
class GlanceWidgetValidationException extends GlanceWidgetException {
  /// Creates a new [GlanceWidgetValidationException].
  const GlanceWidgetValidationException(
    super.message, {
    this.field,
    this.invalidValue,
  }) : super(code: 'VALIDATION_ERROR');

  /// The field that failed validation.
  final String? field;

  /// The invalid value that was provided.
  final Object? invalidValue;

  @override
  String toString() {
    final buffer = StringBuffer('GlanceWidgetValidationException: $message');
    if (field != null) {
      buffer.write(' (field: $field)');
    }
    return buffer.toString();
  }
}
