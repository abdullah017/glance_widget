import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glance_widget/glance_widget.dart';
import 'package:glance_widget/src/preview/preview_context.dart';

/// What the preview rounds its corners by.
///
/// This used to be `theme.borderRadius` on iOS and a hardcoded 16 on Android,
/// on the grounds that the Android templates read the theme's value and never
/// used it. That was true until #24 gave all seven of them
/// `.cornerRadius(CornerRadius.dpFor(...).dp)`, after which the preview was the
/// one telling the comfortable lie.
///
/// Two facts settle what it should draw now, both from the platform's own code
/// rather than from a guess:
///
/// * `ApplyModifiersKt.applyRoundedCorners` checks `SDK_INT >= 31` and
///   otherwise logs "Cannot set the rounded corner of views before Api 31" and
///   returns. Below Android 12 the requested radius does nothing.
/// * At 31 and up it reaches `RemoteViews.setViewOutlinePreferredRadius`,
///   which installs a `RemoteViewOutlineProvider` at exactly the radius given.
///   The framework does not clamp it.
///
/// So the answer depends on the API level of the device being imitated, which
/// is why the preview takes one. Below 12 nothing rounds the widget at all --
/// rounded widget corners are themselves an Android 12 feature -- so it is
/// square, not system-rounded.
///
/// One thing is deliberately not modelled: on Android 12 the launcher clips
/// the widget as well, at its own radius, and two clips on one corner leave
/// whichever rounds more. Which of the two wins for a theme asking for less
/// than 16dp has not been measured on a device, so the preview draws the part
/// the plugin controls and `GlancePreview` says it does not draw the
/// launcher's decoration.
void main() {
  const data = SimpleWidgetData(title: 'Steps', value: '8,241');

  PreviewContext contextFor(
    GlancePlatform platform, {
    double radius = 4,
    int androidApiLevel = 31,
  }) => PreviewContext(
    theme: GlanceTheme.dark().copyWith(borderRadius: radius),
    platform: platform,
    size: GlanceWidgetSize.medium,
    androidApiLevel: androidApiLevel,
  );

  group('corner radius', () {
    test('iOS rounds by the theme', () {
      expect(contextFor(GlancePlatform.ios).cornerRadius, 4);
    });

    test('Android 12 and up rounds by the theme', () {
      // Since #24 the templates apply it, so a preview showing 16 here would
      // disagree with the device.
      expect(contextFor(GlancePlatform.android).cornerRadius, 4);
    });

    test('Android 11 and below is square', () {
      // Not a choice the plugin makes: Glance refuses the modifier below 31,
      // and nothing else rounds a widget before Android 12.
      expect(
        contextFor(GlancePlatform.android, androidApiLevel: 30).cornerRadius,
        0,
      );
    });

    test('a pre-12 preview is square however large the theme asks', () {
      expect(
        contextFor(
          GlancePlatform.android,
          radius: 40,
          androidApiLevel: 30,
        ).cornerRadius,
        0,
      );
    });

    test('the theme is honoured above and below the system radius', () {
      // The framework installs the outline at exactly the radius given, so
      // there is no clamp to model on the plugin's side.
      expect(contextFor(GlancePlatform.android, radius: 40).cornerRadius, 40);
      expect(contextFor(GlancePlatform.android, radius: 0).cornerRadius, 0);
    });

    test('the API level does not reach iOS', () {
      expect(
        contextFor(GlancePlatform.ios, androidApiLevel: 30).cornerRadius,
        4,
      );
    });

    testWidgets('the preview clips by what it resolved', (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: GlancePreview(
              data: data,
              platform: GlancePlatform.android,
              androidApiLevel: 30,
            ),
          ),
        ),
      );

      final clip = tester.widget<ClipRRect>(
        find
            .descendant(
              of: find.byType(GlancePreview),
              matching: find.byType(ClipRRect),
            )
            .first,
      );
      expect(clip.borderRadius, BorderRadius.circular(0));
    });
  });
}
