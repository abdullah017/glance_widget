/// Typed navigation into a serialised widget payload.
///
/// `toMap()` returns `Map<String, dynamic>`, so walking into a nested list
/// with `map['events'][0]['time']` is a chain of `dynamic` calls: a renamed
/// key fails at runtime with a cast error instead of being caught while
/// analysing. These helpers make each step explicit and typed.
extension PayloadMap on Map<String, dynamic> {
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
