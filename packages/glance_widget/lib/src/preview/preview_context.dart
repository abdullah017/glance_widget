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
    this.androidApiLevel = defaultAndroidApiLevel,
  });

  /// The theme the widget was given.
  final GlanceTheme theme;

  /// The host being imitated.
  final GlancePlatform platform;

  /// The home screen slot being imitated.
  final GlanceWidgetSize size;

  /// The Android version being imitated, as an SDK level.
  ///
  /// Ignored on iOS. It exists because two of the things a widget does depend
  /// on it, and a preview that ignored the difference would be right for one
  /// group of devices and wrong for the other. See [cornerRadius].
  final int androidApiLevel;

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
  /// `RoundedRectangle(cornerRadius: theme.borderRadius)`.
  ///
  /// Android honours it from 12 onwards, and cannot before. Glance's
  /// `applyRoundedCorners` checks `SDK_INT >= 31` and otherwise logs
  /// "Cannot set the rounded corner of views before Api 31" and returns, so on
  /// Android 8 to 11 the request never reaches the view. Rounded widget
  /// corners are themselves an Android 12 feature, so nothing else rounds it
  /// either and the widget is square. From 12 the modifier reaches
  /// `RemoteViews.setViewOutlinePreferredRadius`, which installs an outline
  /// provider at exactly the radius asked for; the framework does not clamp
  /// it.
  ///
  /// What this draws is the radius the *plugin* applies, which is the part the
  /// theme controls. Android 12 also clips the widget at the launcher, at
  /// [androidSystemCornerRadius] and subject to whatever launcher is
  /// installed, and the preview does not draw that -- see the note on
  /// `GlancePreview` about what it cannot show. A theme asking for corners
  /// squarer than the system's will look squarer here than on a device.
  double get cornerRadius => switch (platform) {
    GlancePlatform.android when androidApiLevel < _androidRoundedCornerApi => 0,
    GlancePlatform.android => theme.borderRadius,
    GlancePlatform.ios => theme.borderRadius,
  };

  /// The logical size of the slot.
  Size get logicalSize => size.logicalSize(platform);

  /// `system_app_widget_background_radius` on Android 12 and up.
  ///
  /// Documented here because it is what the launcher's own clip uses, and so
  /// what a theme asking for squarer corners is up against on a device. The
  /// preview does not draw it.
  static const double androidSystemCornerRadius = 16;

  /// The SDK level this preview assumes when it is not told one.
  ///
  /// Android 12, which is where rounded corners, Material You and the current
  /// widget picker all arrive. The plugin supports back to 8.0, so a preview
  /// aimed at those devices should say so.
  static const int defaultAndroidApiLevel = 31;

  /// `GlanceModifier.cornerRadius(Dp)` does nothing below this.
  static const int _androidRoundedCornerApi = 31;
}
