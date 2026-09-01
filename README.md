# glance_widget

Home screen widgets for Flutter, on **Android** (Jetpack Glance) and **iOS**
(WidgetKit). Seven typed templates, interactive checkboxes, Live Activities,
and a widget you can read back.

**The package documentation lives in
[`packages/glance_widget/README.md`](packages/glance_widget/README.md)** —
installation, native setup for both platforms, and every template with its
code. This file is about the repository.

## The four packages

This is a federated plugin. An app depends on one of them; the other three come
along.

| Package | What it is |
|---------|------------|
| [`glance_widget`](packages/glance_widget) | The package you depend on. The public API, the controllers, `GlancePreview`, and `GlanceDoctor`. |
| [`glance_widget_platform_interface`](packages/glance_widget_platform_interface) | The contract the two implementations answer, and every data type that crosses the channel. |
| [`glance_widget_android`](packages/glance_widget_android) | Jetpack Glance implementation: seven composable templates, WorkManager background updates, Material You. |
| [`glance_widget_ios`](packages/glance_widget_ios) | WidgetKit implementation, plus the SwiftUI widget templates a developer copies into their own extension. |

The Dart packages resolve against each other through a
[workspace](pubspec.yaml), so a sibling dependency is the local source and
there are no `pubspec_overrides.yaml` files to keep in sync.

## Running the checks

```bash
./tool/verify.sh
```

Formats, analyses and tests all five Dart packages, runs the Kotlin unit tests
through the example app's Gradle wrapper, runs the Swift tests in a simulator,
and does a publish dry-run for each of the four published packages. It is what
CI runs, so a green run here is a green run there.

The two native gates are worth knowing about separately:

```bash
./tool/test_ios.sh    # boots a simulator; the slowest gate, and the only one
                      # that compiles the widget templates the way they ship
cd packages/glance_widget/example/android && \
  ./gradlew :glance_widget_android:testDebugUnitTest
```

`test_ios.sh` starts by checking that every Swift file under the test and
template directories is actually a member of the target that needs it. An
unregistered file still reports `** TEST SUCCEEDED **` while testing nothing,
which is why that check runs before a simulator is booted.

## Layout

```
packages/                  the four published packages
  glance_widget/example/   the demo app, and the host for the native test suites
tool/verify.sh             every gate, in the order CI runs them
docs/task_plan.md          the phases of the v2 work
```

The iOS widget templates live in
[`packages/glance_widget_ios/example/ios/GlanceWidgets/`](packages/glance_widget_ios/example/ios/GlanceWidgets)
and are compiled by a real app-extension target in the example, not
type-checked as loose files — so a template that stops building fails the
build rather than shipping broken.

## Contributing

Issues and pull requests are welcome. A change that alters behaviour is
expected to come with the test that would have caught the old behaviour, and
`./tool/verify.sh` green.

## License

MIT. See [LICENSE](LICENSE); each package carries its own copy.
