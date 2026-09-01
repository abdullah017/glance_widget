import 'dart:ui';

import 'package:glance_widget_platform_interface/src/types/glance_exception.dart';

/// Reads a decoded JSON map strictly, naming the field that is wrong.
///
/// Every accessor here throws [GlanceWidgetFormatException] on a type it did
/// not expect rather than falling back to a default. A record the plugin wrote
/// itself is either intact or it is evidence that the writer and the reader
/// disagree, and quietly substituting a zero would turn that disagreement into
/// a wrong number on someone's home screen.
///
/// Numbers are read as [num] throughout. The same value makes the round trip as
/// `1.0` through one platform's JSON encoder and as `1` through the other's,
/// and neither is wrong.
class MapReader {
  /// Reads [_map], reporting problems under [_path].
  const MapReader(this._map, this._path);

  final Map<Object?, Object?> _map;
  final String _path;

  /// Wraps [value] as a reader, or throws if it is not a map.
  static MapReader of(Object? value, String path) {
    if (value is! Map<Object?, Object?>) {
      throw GlanceWidgetFormatException(
        'expected an object, got ${value.runtimeType}',
        field: path,
      );
    }
    return MapReader(value, path);
  }

  Never _wrong(String key, String expected, Object? value) {
    throw GlanceWidgetFormatException(
      'expected $expected, got ${value == null ? 'nothing' : value.runtimeType}',
      field: _path.isEmpty ? key : '$_path.$key',
    );
  }

  /// The underlying map, for handing to a factory that takes one.
  Map<Object?, Object?> get map => _map;

  /// The raw value at [key], or null when absent.
  Object? operator [](String key) => _map[key];

  /// A string that must be present.
  String requireString(String key) {
    final value = _map[key];
    if (value is! String) _wrong(key, 'a string', value);
    return value;
  }

  /// A string that may be absent or explicitly null, but not another type.
  String? optionalString(String key) {
    final value = _map[key];
    if (value == null) return null;
    if (value is! String) _wrong(key, 'a string or null', value);
    return value;
  }

  /// A number that must be present, widened to [double].
  double requireDouble(String key) {
    final value = _map[key];
    if (value is! num) _wrong(key, 'a number', value);
    return value.toDouble();
  }

  /// An integer that must be present.
  int requireInt(String key) {
    final value = _map[key];
    if (value is! num) _wrong(key, 'a number', value);
    return value.toInt();
  }

  /// An integer, or [fallback] when absent.
  int intOr(String key, int fallback) {
    final value = _map[key];
    if (value == null) return fallback;
    if (value is! num) _wrong(key, 'a number or null', value);
    return value.toInt();
  }

  /// A boolean, or [fallback] when absent.
  bool boolOr(String key, bool fallback) {
    final value = _map[key];
    if (value == null) return fallback;
    if (value is! bool) _wrong(key, 'a boolean or null', value);
    return value;
  }

  /// A colour stored as a packed ARGB integer, or null when absent.
  Color? color(String key) {
    final value = _map[key];
    if (value == null) return null;
    if (value is! num) _wrong(key, 'an ARGB integer or null', value);
    return Color(value.toInt());
  }

  /// An ISO-8601 timestamp.
  DateTime dateTime(String key) {
    final value = requireString(key);
    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      _wrong(key, 'an ISO-8601 date', value);
    }
    return parsed;
  }

  /// One of [values], matched on the enum case name.
  ///
  /// An unrecognised name is a hard error rather than a fallback to the first
  /// case: on the way *out* an unknown enum name means an old native template
  /// meeting a new app and drawing something is better than drawing nothing,
  /// but on the way *in* it means the caller would be handed a value the
  /// widget is not showing.
  T enumByName<T extends Enum>(String key, List<T> values) {
    final name = requireString(key);
    for (final value in values) {
      if (value.name == name) return value;
    }
    _wrong(key, 'one of ${values.map((v) => v.name).join(', ')}', name);
  }

  /// A list of objects, each wrapped as a reader.
  List<MapReader> readers(String key) {
    final value = _map[key];
    if (value is! List) _wrong(key, 'a list', value);
    return <MapReader>[
      for (var i = 0; i < value.length; i++)
        MapReader.of(value[i], '${_path.isEmpty ? key : '$_path.$key'}[$i]'),
    ];
  }

  /// A list of numbers, widened to [double].
  List<double> doubles(String key) {
    final value = _map[key];
    if (value is! List) _wrong(key, 'a list', value);
    return <double>[
      for (final entry in value)
        if (entry is num)
          entry.toDouble()
        else
          _wrong(key, 'a list of numbers', entry),
    ];
  }

  /// A nested object, or null when absent.
  MapReader? child(String key) {
    final value = _map[key];
    if (value == null) return null;
    return MapReader.of(value, _path.isEmpty ? key : '$_path.$key');
  }
}
