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
  const GlanceWidgetTimeoutException(super.message, {this.timeoutDuration})
    : super(code: 'TIMEOUT');

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

/// The outcome of one widget's update inside a batch that partly failed.
class GlanceWidgetBatchFailure {
  /// Records that [widgetId] could not be updated, and why.
  const GlanceWidgetBatchFailure({
    required this.widgetId,
    required this.message,
    this.code,
  });

  /// The widget that was not updated.
  final String widgetId;

  /// Why it was not updated, in the native side's words.
  final String message;

  /// The error code the native side reported, if any.
  final String? code;

  @override
  String toString() => code == null
      ? '$widgetId: $message'
      : '$widgetId: $message (code: $code)';
}

/// Thrown when some widgets in a batch could not be updated.
///
/// A batch does not stop at the first failure. One widget missing from the
/// home screen is not a reason to leave the other nineteen showing stale data,
/// so every update is attempted and the ones that failed are reported together
/// here. [failures] names them; every other widget in the batch was updated.
class GlanceWidgetBatchException extends GlanceWidgetException {
  /// Creates a batch failure carrying one entry per widget that failed.
  GlanceWidgetBatchException(this.failures, {required this.attempted})
    : super(
        '${failures.length} of $attempted widget updates failed: '
        '${failures.map((f) => f.widgetId).join(', ')}',
        code: 'BATCH_PARTIAL_FAILURE',
      );

  /// One entry per widget that could not be updated.
  final List<GlanceWidgetBatchFailure> failures;

  /// How many updates the batch carried in total.
  final int attempted;

  @override
  String toString() {
    final buffer = StringBuffer('GlanceWidgetBatchException: $message')
      ..writeln();
    for (final failure in failures) {
      buffer.writeln('  $failure');
    }
    return buffer.toString().trimRight();
  }
}
