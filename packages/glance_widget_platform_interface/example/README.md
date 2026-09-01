# Example

This package is the interface that
[`glance_widget`](https://pub.dev/packages/glance_widget) and its two platform
implementations agree on. An app never depends on it directly, so the runnable
example is the one in the app-facing package —
[`glance_widget/example`](https://github.com/abdullahtas0/glance_widget/tree/master/packages/glance_widget/example).

You depend on this package when you are writing a *new* implementation of
`glance_widget` for another platform. That means extending
`GlanceWidgetPlatform` and registering the result:

```dart
import 'package:glance_widget_platform_interface/glance_widget_platform_interface.dart';

class GlanceWidgetLinux extends GlanceWidgetPlatform {
  static void registerWith() {
    GlanceWidgetPlatform.instance = GlanceWidgetLinux();
  }

  @override
  Future<void> updateSimpleWidget({
    required String widgetId,
    required SimpleWidgetData data,
    GlanceTheme? theme,
  }) async {
    // ...render
  }

  // One override per template, plus `updateBatch`. Every method on
  // `GlanceWidgetPlatform` throws `UnimplementedError` by default, so a
  // template you have not written yet fails loudly at the call rather than
  // silently rendering nothing.
}
```

The types are also useful on their own. `WidgetData.fromMap` and
`GlanceWidgetSnapshot.decode` parse a stored record back into the sealed
classes, and every failure names the field it failed on:

```dart
try {
  final snapshot = GlanceWidgetSnapshot.decode(storedJson);
  print('${snapshot.widgetId} was written at ${snapshot.updatedAt}');
} on GlanceWidgetFormatException catch (e) {
  // e.field is the dotted path, e.g. `simple.theme.backgroundColor`.
  print('unreadable record: ${e.field}');
}
```
