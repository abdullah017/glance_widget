import 'dart:ui';

import 'package:glance_widget_platform_interface/src/types/map_reader.dart';

/// Theme configuration for Glance Widgets.
class GlanceTheme {
  /// Creates a theme describing how a widget should be painted natively.
  const GlanceTheme({
    required this.backgroundColor,
    required this.textColor,
    this.secondaryTextColor = const Color(0xFF9E9E9E),
    this.accentColor = const Color(0xFF2196F3),
    this.borderRadius = 16.0,
    this.isDark = false,
    this.useDynamicColor = false,
  });

  /// Creates a default light theme.
  factory GlanceTheme.light() => const GlanceTheme(
    backgroundColor: Color(0xFFFFFFFF),
    textColor: Color(0xFF212121),
    secondaryTextColor: Color(0xFF757575),
    accentColor: Color(0xFF2196F3),
    borderRadius: 16.0,
    isDark: false,
  );

  /// Creates a default dark theme.
  factory GlanceTheme.dark() => const GlanceTheme(
    backgroundColor: Color(0xFF1A1A2E),
    textColor: Color(0xFFFFFFFF),
    secondaryTextColor: Color(0xFFB0B0B0),
    accentColor: Color(0xFFFFA726),
    borderRadius: 16.0,
    isDark: true,
  );

  /// Rebuilds a theme from a map [toMap] produced.
  factory GlanceTheme.fromReader(MapReader reader) => GlanceTheme(
    backgroundColor: reader.color('backgroundColor') ?? const Color(0xFFFFFFFF),
    textColor: reader.color('textColor') ?? const Color(0xFF212121),
    secondaryTextColor:
        reader.color('secondaryTextColor') ?? const Color(0xFF9E9E9E),
    accentColor: reader.color('accentColor') ?? const Color(0xFF2196F3),
    borderRadius: reader.requireDouble('borderRadius'),
    isDark: reader.boolOr('isDark', false),
    useDynamicColor: reader.boolOr('useDynamicColor', false),
  );

  /// Background color of the widget.
  final Color backgroundColor;

  /// Primary text color.
  final Color textColor;

  /// Secondary/muted text color.
  final Color secondaryTextColor;

  /// Accent color for highlights and interactive elements.
  final Color accentColor;

  /// Border radius in logical pixels.
  final double borderRadius;

  /// Whether to use dark theme.
  final bool isDark;

  /// Whether the widget should take its colours from the system wallpaper
  /// (Material You) instead of the ones set on this theme.
  ///
  /// **Android 12 (API 31) and above only, and Android only.** Below that the
  /// platform exposes no wallpaper palette, and on iOS there is no equivalent
  /// at all; in both cases the colours on this theme are used instead. That is
  /// why they are still required when this is `true` -- they are the fallback,
  /// not dead weight.
  ///
  /// Off by default. Turning it on hands your widget's appearance to the
  /// user's wallpaper, which is a choice worth making deliberately.
  final bool useDynamicColor;

  /// Serialises this theme for transport over a platform channel.
  Map<String, dynamic> toMap() => {
    'backgroundColor': backgroundColor.toARGB32(),
    'textColor': textColor.toARGB32(),
    'secondaryTextColor': secondaryTextColor.toARGB32(),
    'accentColor': accentColor.toARGB32(),
    'borderRadius': borderRadius,
    'isDark': isDark,
    'useDynamicColor': useDynamicColor,
  };

  /// Returns a copy of this theme with the given fields replaced.
  GlanceTheme copyWith({
    Color? backgroundColor,
    Color? textColor,
    Color? secondaryTextColor,
    Color? accentColor,
    double? borderRadius,
    bool? isDark,
    bool? useDynamicColor,
  }) {
    return GlanceTheme(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textColor: textColor ?? this.textColor,
      secondaryTextColor: secondaryTextColor ?? this.secondaryTextColor,
      accentColor: accentColor ?? this.accentColor,
      borderRadius: borderRadius ?? this.borderRadius,
      isDark: isDark ?? this.isDark,
      useDynamicColor: useDynamicColor ?? this.useDynamicColor,
    );
  }
}
