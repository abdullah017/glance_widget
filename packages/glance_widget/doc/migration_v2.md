# Migrating to glance_widget 2.0

2.0 replaces the package's error handling. In 1.x an update answered
`Future<bool>`, and two unrelated global switches decided what a failure meant.
That design had a defect the tests now pin down: **a failed update was reported
as a success**. The native plugins never sent back `false` — they replied with a
platform error, which the Dart layer caught, logged, and converted into `false`
only for the caller who thought to check it. Callers who did not check saw
nothing at all, and `DebouncedWidgetController` counted the failure as a
completed update.

Every change below follows from fixing that.

## 1. Update methods return `Future<void>` and throw on failure

```dart
// 1.x
final ok = await GlanceWidget.simple(id: 'btc', title: 'Bitcoin', value: r'$94,532');
if (!ok) showError();

// 2.0
try {
  await GlanceWidget.simple(id: 'btc', title: 'Bitcoin', value: r'$94,532');
} on GlanceWidgetException catch (e) {
  showError('${e.code}: ${e.message}');
}
```

`GlanceWidgetException` carries the platform's own `code` and `message`, plus
`originalException` holding the underlying `PlatformException`. In 1.x that
detail was written to a log and discarded.

The affected members, all of which used to return `Future<bool>`:

| Type | Members |
|---|---|
| `GlanceWidget` | `simple`, `progress`, `list`, `image`, `chart`, `calendar`, `gauge`, `setTheme`, `refreshAll`, `completeWidgetConfiguration` |
| `GlanceWidgetController` | `update`, `setTheme` |
| `DebouncedWidgetController` | `setTheme` |
| `GlanceBackground` | `configureUpdate`, `cancelUpdate`, `testUpdate`, `configureTimelineRefresh`, `cancelTimelineRefresh` |
| `GlanceWidgetPlatform` | the 15 corresponding platform methods |

`isWidgetPushSupported` still returns `Future<bool>` — it is a genuine question
about the platform, not a disguised error code. `getWidgetPushToken`,
`getActiveWidgetIds` and `getBackgroundUpdateStatus` keep their return types but
now throw on a platform failure instead of quietly answering `null` / `[]` /
`{isConfigured: false}`. A `null` from `getWidgetPushToken` once again means
only what it says: no token yet.

Because the return type changed rather than the name, the analyzer flags every
affected call site. There is no silent behaviour change to discover at runtime.

## 2. `MethodChannelGlanceWidget.throwOnError` is gone

Failures always throw. Delete any assignment to it; if you had set it to `true`,
you already have the 2.0 behaviour.

## 3. `GlanceConfig.strictMode` is gone

One flag was doing two unrelated jobs. Both are now explicit:

**Unsupported platforms** (Web, macOS, Windows, Linux) are always a silent
no-op, never an exception. A desktop build that shares code with the mobile
build should not crash, and `strictMode = true` made it crash. Query support
instead of configuring a failure mode:

```dart
// 1.x
GlanceConfig.strictMode = kDebugMode;

// 2.0 — branch where the user would notice, nowhere else
if (GlanceWidget.isSupported) const AddWidgetButton(),
```

**JSONPath validation** no longer consults the flag. An empty path, or one that
does not start with `$`, is still rejected outright. Anything else is checked
against a heuristic that covers the common shapes but not the whole grammar, so
an unrecognised expression is logged and passed to the native parser, which is
the authority on what it accepts. In 1.x, `strictMode = true` rejected valid
expressions such as `$..author` and `$.book[?(@.price < 10)]`.

## 4. Debounced updates report failures on a stream

`scheduleUpdate` returns before its dispatch happens, so it cannot throw to its
caller. In 1.x that meant a timer-driven failure reached nobody. In 2.0:

```dart
final controller = DebouncedWidgetController<SimpleWidgetData>(widgetId: 'btc');
controller.errors.listen((e) => debugPrint('widget update failed: $e'));

controller.scheduleUpdate(data);   // failures go to `errors`
await controller.flush();          // failures throw to you
```

New members: `errors`, `failedCount`, `lastError`. A failed dispatch no longer
increments `updateCount` and no longer advances `timeSinceLastUpdate`, so
`isStale` now tells the truth when the platform has been rejecting updates.

## 5. `GlanceWidget.onAction` is guarded

On an unsupported platform it now yields an empty stream instead of reaching for
an unregistered event channel. `listen` still works and simply never fires.
`GlanceWidgetController.update`, `setTheme` and `onAction` are guarded the same
way; in 1.x the controllers bypassed the guard entirely and threw
`MissingPluginException` on desktop.

## 6. iOS requires a deployment target of 17.0

Up from 16.0. Set it in `ios/Podfile`:

```ruby
platform :ios, '17.0'
```

Set it there even if your project has no pods left. Flutter generates
`FlutterGeneratedPluginSwiftPackage` from that line, and a commented-out one
pins the generated package to Flutter's default whatever the Xcode target says,
so the build stops with `requires minimum platform version 17.0 for the iOS
platform`.

The reason is the fix below: `AppIntentConfiguration` is the only widget
configuration that carries a per-instance parameter, and it needs iOS 17.

## 7. iOS widget templates take a `widgetId` from their configuration

In 1.x every placed instance of a template rendered the same data. `widgetId`
was honoured when the plugin wrote a payload and ignored when the extension read
one back — each widget called `load...Widget()` with no id and got whichever
payload was written last — so two `SimpleWidget`s could not show `'btc'` and
`'eth'`.

If you copied the templates into your app, take the new versions. The change is
mechanical, and there is no way to point a `StaticConfiguration` widget at an
id:

```swift
// Before
struct SimpleWidgetProvider: TimelineProvider {
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        let data = WidgetStorage.shared.loadSimpleWidget() ?? .placeholder
        ...
    }
}

StaticConfiguration(kind: kind, provider: SimpleWidgetProvider()) { entry in ... }

// After
struct SimpleWidgetProvider: AppIntentTimelineProvider {
    func timeline(for configuration: SimpleWidgetIntent, in context: Context) async -> Timeline<Entry> {
        let data = WidgetStorage.shared.loadSimpleWidget(widgetId: configuration.widgetId)
            ?? .placeholder
        ...
    }
}

AppIntentConfiguration(
    kind: kind,
    intent: SimpleWidgetIntent.self,
    provider: SimpleWidgetProvider()
) { entry in ... }
```

Nothing changes in your Dart code, and nothing changes on Android, where updates
are routed to the instance holding the id automatically.

There is one behaviour change for the people using your app: with two widgets
from the same template on the home screen, they choose which is which by
long-pressing a widget and tapping **Edit Widget**. The picker offers the ids
your app has sent data for. An instance nobody has configured keeps the 1.x
behaviour and shows the most recently updated id, so a freshly placed widget is
never blank.
