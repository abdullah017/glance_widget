import 'package:flutter/services.dart';

/// Typed views over the untyped payloads that cross a method channel.
///
/// A `MethodCall`'s arguments arrive as `Object?`, so walking into them with
/// `args['data']['title']` is a chain of `dynamic` calls: a typo in a nested
/// key, or a payload whose shape changed, fails at runtime with a cast error
/// rather than being caught while analysing. These helpers make each step
/// explicit and typed, so the assertions read as data access instead of
/// dynamic dispatch.
extension MethodCallPayload on MethodCall {
  /// The call arguments as a string-keyed map.
  ///
  /// Throws if the call carried no arguments or carried a non-map.
  Map<String, Object?> get payload =>
      (arguments as Map<Object?, Object?>).cast<String, Object?>();
}

/// Typed navigation into a decoded channel payload.
extension PayloadMap on Map<String, Object?> {
  /// The nested map stored under [key].
  ///
  /// Throws if [key] is absent or does not hold a map.
  Map<String, Object?> child(String key) {
    final value = this[key];
    if (value is! Map) {
      throw StateError(
        'Expected a map at "$key" but found ${value.runtimeType}. '
        'Payload keys: ${keys.join(', ')}',
      );
    }
    return value.cast<String, Object?>();
  }

  /// The list of nested maps stored under [key].
  ///
  /// Throws if [key] is absent, does not hold a list, or holds a list whose
  /// elements are not maps.
  List<Map<String, Object?>> childList(String key) {
    final value = this[key];
    if (value is! List) {
      throw StateError(
        'Expected a list at "$key" but found ${value.runtimeType}. '
        'Payload keys: ${keys.join(', ')}',
      );
    }
    return value.map((element) {
      if (element is! Map) {
        throw StateError(
          'Expected "$key" to hold maps but found ${element.runtimeType}.',
        );
      }
      return element.cast<String, Object?>();
    }).toList();
  }
}
