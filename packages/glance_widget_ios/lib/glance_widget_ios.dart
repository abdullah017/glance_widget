/// iOS implementation of the glance_widget plugin.
library;

import 'package:glance_widget_platform_interface/glance_widget_platform_interface.dart';

/// The iOS implementation of [GlanceWidgetPlatform].
///
/// iOS speaks the shared `dev.glance.widget/methods` channel that
/// [MethodChannelGlanceWidget] already implements, so this class inherits the
/// whole surface rather than restating it. Overriding a member here is how an
/// iOS-only difference would be expressed; there are none today — the
/// WidgetKit-specific calls (push token, timeline refresh) are already part of
/// the shared interface and are no-ops on Android.
class GlanceWidgetIos extends MethodChannelGlanceWidget {
  /// Registers this class as the default instance of [GlanceWidgetPlatform].
  static void registerWith() {
    GlanceWidgetPlatform.instance = GlanceWidgetIos();
  }
}
