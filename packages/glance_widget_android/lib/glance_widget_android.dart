/// Android implementation of the glance_widget plugin.
library;

import 'package:glance_widget_platform_interface/glance_widget_platform_interface.dart';

/// The Android implementation of [GlanceWidgetPlatform].
///
/// Android speaks the shared `dev.glance.widget/methods` channel that
/// [MethodChannelGlanceWidget] already implements, so this class inherits the
/// whole surface rather than restating it. Overriding a member here is how an
/// Android-only difference would be expressed; there are none today.
class GlanceWidgetAndroid extends MethodChannelGlanceWidget {
  /// Registers this class as the default instance of [GlanceWidgetPlatform].
  static void registerWith() {
    GlanceWidgetPlatform.instance = GlanceWidgetAndroid();
  }
}
