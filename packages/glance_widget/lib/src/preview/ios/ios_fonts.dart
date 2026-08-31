import 'package:flutter/widgets.dart';
import 'package:glance_widget/src/preview/glance_widget_size.dart';

/// The SwiftUI text styles the iOS templates ask for, at their default sizes.
///
/// The templates name semantic styles -- `.caption`, `.title2`, `.headline` --
/// rather than point sizes. These are the sizes those styles resolve to at the
/// default Dynamic Type setting, which is what a screenshot of an unmodified
/// device shows. A user who has enlarged text sees larger widgets; the preview
/// draws the default, and the templates use `minimumScaleFactor` and
/// `lineLimit` to survive the rest.
enum IosTextStyle {
  /// `.caption2` -- 11pt.
  caption2(11),

  /// `.caption` -- 12pt.
  caption(12),

  /// `.footnote` -- 13pt.
  footnote(13),

  /// `.subheadline` -- 15pt.
  subheadline(15),

  /// `.body` -- 17pt.
  body(17),

  /// `.headline` -- 17pt semibold.
  headline(17, FontWeight.w600),

  /// `.title3` -- 20pt.
  title3(20),

  /// `.title2` -- 22pt.
  title2(22),

  /// `.title` -- 28pt.
  title(28),

  /// `.largeTitle` -- 34pt.
  largeTitle(34);

  const IosTextStyle(this.size, [this.weight]);

  /// The point size the style resolves to.
  final double size;

  /// The weight the style carries on its own, before any `fontWeight` call.
  final FontWeight? weight;

  /// This style in [color], with [weight] overriding the style's own.
  TextStyle style(Color color, {FontWeight? weight}) => TextStyle(
    color: color,
    fontSize: size,
    fontWeight: weight ?? this.weight,
  );
}

/// Picks the value for the slot being drawn.
///
/// Every sizing helper in the iOS templates is a `switch` over `WidgetFamily`
/// with one arm per family, so this reads the same way at the call site.
T forFamily<T>(
  GlanceWidgetSize size, {
  required T small,
  required T medium,
  required T large,
}) => switch (size) {
  GlanceWidgetSize.small => small,
  GlanceWidgetSize.medium => medium,
  GlanceWidgetSize.large => large,
};
