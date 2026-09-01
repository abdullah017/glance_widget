# Example

This package is the iOS implementation of
[`glance_widget`](https://pub.dev/packages/glance_widget), and it is
[endorsed](https://flutter.dev/docs/development/packages-and-plugins/developing-packages#endorsed-federated-plugin):
depending on `glance_widget` pulls it in, and there is no separate API to call.
The runnable example is the one in the app-facing package —
[`glance_widget/example`](https://github.com/abdullahtas0/glance_widget/tree/master/packages/glance_widget/example).

```dart
// Nothing here mentions this package. That is the point of endorsement.
import 'package:glance_widget/glance_widget.dart';

await GlanceWidget.updateSimpleWidget(
  const SimpleWidgetData(
    widgetId: 'crypto_btc',
    title: 'Bitcoin',
    value: r'$67,432',
    subtitle: '+2.4%',
  ),
);
```

## The Swift half of the example lives here

Unlike Android, iOS cannot render a widget from a package: a widget extension is
a target in *your* Xcode project, so its SwiftUI has to be a file you own. The
templates you copy into it are in [`ios/GlanceWidgets/`](ios/GlanceWidgets)
next to this file — one Swift file per template, plus the shared models, the
widget-family helpers and the interactive-action plumbing they read.

Those files are not documentation that drifts. The example app's widget
extension target compiles exactly these files, and so does its test target, so a
renamed field breaks the build here before it reaches anybody's home screen.

Two things decide whether a copied template works at all, and both fail
silently:

- **`GlanceWidgetAppGroup`** must name the same App Group in the app's
  `Info.plist` and the extension's. Two plists naming different groups gives you
  two working stores that are not the same store, and every update lands in the
  one nobody is reading.
- **iOS 17.0** is the minimum. The templates use `AppIntentConfiguration`,
  which is the only widget configuration that carries a per-instance parameter
  — and therefore the only way a placed widget can know which `widgetId` it is
  showing.

`dart run glance_widget:doctor` checks both without needing Xcode.
