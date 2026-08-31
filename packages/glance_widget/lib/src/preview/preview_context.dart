import 'package:flutter/widgets.dart';
import 'package:glance_widget/src/preview/glance_platform.dart';
import 'package:glance_widget/src/preview/glance_widget_size.dart';
import 'package:glance_widget_platform_interface/glance_widget_platform_interface.dart';

/// The colours and the slot a preview draws with, resolved once.
///
/// Both hosts read the same [GlanceTheme] fields, so resolving them here keeps
/// the two renderers from drifting apart on anything that is genuinely shared.
/// Everything that differs -- fonts, spacing, what a template does with the
/// numbers -- stays in the renderer that owns it.
///
/// One field is deliberately not honoured: [GlanceTheme.useDynamicColor]. The
/// wallpaper palette lives behind `@android:color/system_accent1_*`, which is
/// readable from a widget's own process and not from Flutter, so a preview
/// cannot show the colours the device will actually use. It draws the theme's
/// colours instead -- which is exactly what an Android 11 device would do, and
/// what every iOS device does. On Android 12+ with dynamic colour on, treat the
/// preview as showing layout rather than colour.
@immutable
class PreviewContext {
  /// Bundles [theme] with the [platform] and [size] being drawn.
  const PreviewContext({
    required this.theme,
    required this.platform,
    required this.size,
  });

  /// The theme the widget was given.
  final GlanceTheme theme;

  /// The host being imitated.
  final GlancePlatform platform;

  /// The home screen slot being imitated.
  final GlanceWidgetSize size;

  /// The widget's background.
  Color get background => theme.backgroundColor;

  /// The colour of primary text.
  Color get text => theme.textColor;

  /// The colour of labels and secondary text.
  Color get secondaryText => theme.secondaryTextColor;

  /// The colour of progress arcs, checkboxes and date chips.
  Color get accent => theme.accentColor;

  /// The divider and empty-track colour.
  ///
  /// Android's templates hardcode a pair of greys keyed off `isDark`; iOS
  /// derives one from the secondary text colour at 30% opacity. Neither is
  /// wrong, and a preview that averaged them would be wrong on both.
  Color get track => switch (platform) {
    GlancePlatform.android => Color(theme.isDark ? 0xFF3A3A4E : 0xFFE0E0E0),
    GlancePlatform.ios => secondaryText.withValues(alpha: 0.3),
  };

  /// The corner radius the host actually applies.
  ///
  /// iOS honours [GlanceTheme.borderRadius]: every template fills a
  /// `RoundedRectangle(cornerRadius: theme.borderRadius)`. Android does not --
  /// its templates read the value and never use it, because the launcher clips
  /// the widget to the system radius whatever the app asks for. Showing the
  /// requested radius on Android would be the preview telling a comfortable
  /// lie, so it shows the system one.
  double get cornerRadius => switch (platform) {
    GlancePlatform.android => _androidSystemCornerRadius,
    GlancePlatform.ios => theme.borderRadius,
  };

  /// The logical size of the slot.
  Size get logicalSize => size.logicalSize(platform);

  /// `system_app_widget_background_radius` on Android 12 and up.
  static const double _androidSystemCornerRadius = 16;
}
