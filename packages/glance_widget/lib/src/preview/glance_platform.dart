import 'package:flutter/foundation.dart';

/// Which platform's widget rendering a preview should imitate.
///
/// The two hosts do not draw the same thing. Android widgets are built with
/// Jetpack Glance, whose templates centre their content; iOS widgets are built
/// with WidgetKit and SwiftUI, and lay the same fields out differently. A
/// preview that split the difference would be wrong on both, so it commits to
/// one.
enum GlancePlatform {
  /// Jetpack Glance, as `glance_widget_android` draws it.
  android,

  /// WidgetKit, as the `glance_widget_ios` templates draw it.
  ios;

  /// The platform whose widgets this app would actually place.
  ///
  /// Falls back to [GlancePlatform.android] on hosts without home screen
  /// widgets, so a preview still renders in a desktop or web debug session
  /// rather than throwing.
  static GlancePlatform get current => switch (defaultTargetPlatform) {
    TargetPlatform.iOS => GlancePlatform.ios,
    _ => GlancePlatform.android,
  };
}
