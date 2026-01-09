import 'dart:ui';

/// Theme configuration for Glance Widgets.
class GlanceTheme {
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

  const GlanceTheme({
    required this.backgroundColor,
    required this.textColor,
    this.secondaryTextColor = const Color(0xFF9E9E9E),
    this.accentColor = const Color(0xFF2196F3),
    this.borderRadius = 16.0,
    this.isDark = false,
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

  Map<String, dynamic> toMap() => {
        'backgroundColor': backgroundColor.toARGB32(),
        'textColor': textColor.toARGB32(),
        'secondaryTextColor': secondaryTextColor.toARGB32(),
        'accentColor': accentColor.toARGB32(),
        'borderRadius': borderRadius,
        'isDark': isDark,
      };

  GlanceTheme copyWith({
    Color? backgroundColor,
    Color? textColor,
    Color? secondaryTextColor,
    Color? accentColor,
    double? borderRadius,
    bool? isDark,
  }) {
    return GlanceTheme(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textColor: textColor ?? this.textColor,
      secondaryTextColor: secondaryTextColor ?? this.secondaryTextColor,
      accentColor: accentColor ?? this.accentColor,
      borderRadius: borderRadius ?? this.borderRadius,
      isDark: isDark ?? this.isDark,
    );
  }
}
