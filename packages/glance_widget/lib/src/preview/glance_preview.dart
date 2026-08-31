import 'package:flutter/widgets.dart';
import 'package:glance_widget/src/preview/android/android_preview.dart';
import 'package:glance_widget/src/preview/glance_platform.dart';
import 'package:glance_widget/src/preview/glance_widget_size.dart';
import 'package:glance_widget/src/preview/ios/ios_preview.dart';
import 'package:glance_widget/src/preview/preview_context.dart';
import 'package:glance_widget_platform_interface/glance_widget_platform_interface.dart';

/// Shows what a home screen widget built from [data] will look like.
///
/// The point of this is to close the loop that otherwise runs through a build,
/// an install, a long-press on the home screen and a widget picker. Change the
/// data, hot reload, see the widget.
///
/// ```dart
/// GlancePreview(
///   data: const SimpleWidgetData(title: 'Steps', value: '8,241'),
///   theme: GlanceTheme.dark(),
///   size: GlanceWidgetSize.medium,
/// )
/// ```
///
/// ## It renders per platform, not an average of the two
///
/// Android draws with Jetpack Glance and iOS with WidgetKit, and they do not
/// draw the same thing from the same data. Some of that is cosmetic -- fonts,
/// spacing -- and some of it is not: the Android simple template ignores
/// `iconName`, the Android radial gauge draws only the first metric where iOS
/// draws all of them, and Android's charts are rasterised bitmaps stretched to
/// fit while iOS lays its charts out as views.
///
/// So [platform] picks a host, defaulting to the one the app is running on.
/// Put two side by side to compare them:
///
/// ```dart
/// Row(
///   children: [
///     GlancePreview(data: data, platform: GlancePlatform.android),
///     GlancePreview(data: data, platform: GlancePlatform.ios),
///   ],
/// )
/// ```
///
/// ## What it cannot show
///
/// * **Pictures.** The plugin downloads and downsamples an image on the device.
///   Nothing here fetches it, so an image widget draws its placeholder.
/// * **SF Symbols.** `iconName` names a symbol that only resolves on an Apple
///   platform; the preview holds its space with a plain shape.
/// * **Dates.** Both hosts format dates with the device's locale. The preview
///   writes English names rather than depending on a localisation package.
/// * **The launcher's own decoration.** Android tints and clips widgets to the
///   system's radius, which changes between launchers and OS versions.
///
/// Everything else -- layout, colours, type scale, what each template does with
/// the numbers, which fields it quietly drops -- is transcribed from the native
/// templates.
class GlancePreview extends StatelessWidget {
  /// Draws [data] as [platform] would at [size].
  const GlancePreview({
    required this.data,
    super.key,
    this.theme,
    this.platform,
    this.size = GlanceWidgetSize.medium,
    this.androidApiLevel = PreviewContext.defaultAndroidApiLevel,
  });

  /// The widget content to draw.
  final WidgetData data;

  /// The theme to draw it with.
  ///
  /// When null, the host's own default is used: Android's templates fall back
  /// to their dark palette whenever no theme has been stored, and iOS follows
  /// the device's colour scheme. That divergence is real, and a preview showing
  /// one palette for both would hide it.
  final GlanceTheme? theme;

  /// Which host to imitate, defaulting to the one this app is running on.
  final GlancePlatform? platform;

  /// The home screen slot to draw at.
  final GlanceWidgetSize size;

  /// The Android version to imitate, as an SDK level. Ignored on iOS.
  ///
  /// Defaults to 31 -- Android 12, where rounded widget corners arrive. The
  /// plugin supports back to 8.0, and a widget does not look the same there:
  /// `GlanceModifier.cornerRadius` is refused below 12, so a theme asking for
  /// 4dp corners gets the launcher's own rounding instead. Pass 30 to see
  /// that.
  final int androidApiLevel;

  @override
  Widget build(BuildContext context) {
    final host = platform ?? GlancePlatform.current;
    final previewContext = PreviewContext(
      theme: theme ?? _defaultTheme(context, host),
      platform: host,
      size: size,
      androidApiLevel: androidApiLevel,
    );
    final logicalSize = previewContext.logicalSize;

    return SizedBox(
      width: logicalSize.width,
      height: logicalSize.height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(previewContext.cornerRadius),
        child: ColoredBox(
          color: previewContext.background,
          child: switch (host) {
            GlancePlatform.android => buildAndroidPreview(previewContext, data),
            GlancePlatform.ios => buildIosPreview(previewContext, data),
          },
        ),
      ),
    );
  }

  GlanceTheme _defaultTheme(BuildContext context, GlancePlatform host) =>
      switch (host) {
        // `prefs[isDarkKey] ?: true` in every Android template.
        GlancePlatform.android => GlanceTheme.dark(),
        // `colorScheme == .dark ? .defaultDark : .defaultLight` in every iOS
        // template.
        GlancePlatform.ios =>
          MediaQuery.platformBrightnessOf(context) == Brightness.dark
              ? GlanceTheme.dark()
              : GlanceTheme.light(),
      };
}
