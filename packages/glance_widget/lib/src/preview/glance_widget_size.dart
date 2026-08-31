import 'dart:ui';

import 'package:glance_widget/src/preview/glance_platform.dart';

/// The home screen slots a widget can occupy.
///
/// The names follow WidgetKit's families, which Android has no direct
/// equivalent of -- there a widget is sized in home screen cells, and the exact
/// pixel size depends on the launcher, the device and the user's grid setting.
/// The Android numbers below are the sizes a 5x5 grid on a common phone gives,
/// which is what `glance_widget_android` declares its widgets as in
/// `xml/*_widget_info.xml`.
enum GlanceWidgetSize {
  /// A square. iOS `systemSmall`; roughly a 2x2 cell on Android.
  small,

  /// A wide rectangle. iOS `systemMedium`; roughly a 4x2 cell on Android.
  medium,

  /// A tall rectangle. iOS `systemLarge`; roughly a 4x4 cell on Android.
  large;

  /// The logical size this slot has on [platform].
  ///
  /// These are the reference sizes a preview draws at. A real widget is
  /// stretched to whatever the launcher or the device gives it, which is why
  /// the templates lay out relatively rather than pinning pixels; the preview
  /// picks one concrete size so the result is reproducible, and so a golden
  /// file means something.
  Size logicalSize(GlancePlatform platform) => switch ((platform, this)) {
    // WidgetKit's families on a 390pt-wide device, which is the size Apple's
    // own documentation uses as the reference.
    (GlancePlatform.ios, GlanceWidgetSize.small) => const Size(155, 155),
    (GlancePlatform.ios, GlanceWidgetSize.medium) => const Size(329, 155),
    (GlancePlatform.ios, GlanceWidgetSize.large) => const Size(329, 345),
    // Android cells, matching the minWidth/minHeight the receivers declare.
    (GlancePlatform.android, GlanceWidgetSize.small) => const Size(150, 150),
    (GlancePlatform.android, GlanceWidgetSize.medium) => const Size(320, 150),
    (GlancePlatform.android, GlanceWidgetSize.large) => const Size(320, 320),
  };
}
