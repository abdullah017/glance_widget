# Example

This package is the Android implementation of
[`glance_widget`](https://pub.dev/packages/glance_widget), and it is
[endorsed](https://flutter.dev/docs/development/packages-and-plugins/developing-packages#endorsed-federated-plugin):
depending on `glance_widget` pulls it in, and there is no separate API to call.
So the runnable example is the one in the app-facing package —
[`glance_widget/example`](https://github.com/abdullahtas0/glance_widget/tree/master/packages/glance_widget/example),
which exercises all seven templates against this implementation on a device.

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

## What is worth looking at here instead

The part of this package a developer actually has to touch is the Android
manifest, not Dart. Each template needs its receiver declared with
`android:exported="true"` — a receiver registered with `false` installs
without complaint and then never appears in the widget picker, which is the
single most common way to get this wrong.

`dart run glance_widget:doctor` reads the manifest and names what is missing,
and the manifest it checks against is
[the example app's](https://github.com/abdullahtas0/glance_widget/blob/master/packages/glance_widget/example/android/app/src/main/AndroidManifest.xml).
