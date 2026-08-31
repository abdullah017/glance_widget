# Does ActivityKit match an activity across a module boundary?

Issue #23 said this could not be answered without a physical device and
sequenced the whole feature behind it. It can be answered in the simulator, and
this is the measurement.

## The question

ActivityKit matches a running activity to the presentation that draws it by its
`ActivityAttributes` type. The plugin is a Swift package; a widget extension
cannot import it, so the extension has to declare its own copy of the type --
the same duplication `SharedModels.swift` already lives with.

Two identically named, identically shaped types in two different modules. If
ActivityKit matches by module-qualified identity, nothing renders and the
attributes have to move into the developer's own app target, with a
registration call to reach them. If it matches by name and shape, the plugin
can own the type and the developer copies a template like every other one.

## The experiment

- `glance_widget_ios` (the plugin's module) declared
  `GlanceActivityAttributes` and called `Activity.request` from inside itself.
- `GlanceWidgets` (the extension's module) declared its own
  `GlanceActivityAttributes` and an `ActivityConfiguration(for:)` whose
  `compactLeading` draws the first character of the title and whose
  `compactTrailing` draws the status.
- The app was launched on an iPhone 17 Pro simulator, then backgrounded so the
  Dynamic Island would render.

Nothing was shared between the two declarations: no shared file, no framework,
no bridging header.

```
Runner[93594] [dev.glance.widget:GlanceWidget] SPIKE: areActivitiesEnabled=true
Runner[93594] [dev.glance.widget:GlanceWidget] SPIKE: requested id=4F5D6B91-...
```

## The answer: it matches

The Dynamic Island drew `S` on the leading side and `12 min away` on the
trailing side -- the extension's own closures, rendering a state the plugin's
module constructed. The match survives the module boundary.

So:

- The plugin owns `GlanceActivityAttributes` and requests activities itself.
- The developer copies `GlanceLiveActivityWidget.swift` into their extension
  alongside the seven widget templates, and the copy in it must keep the type
  **name** and the **shape** of `ContentState` -- that, not the module, is what
  ActivityKit matches on.

## What this does not prove

The Dynamic Island and the Lock Screen presentation are the same
`ActivityConfiguration`; only the compact Dynamic Island was photographed. And
a simulator does not prove push-updated activities (`pushType: .token`), which
need APNs and a real device. Neither is in scope for the type-matching
question.

## What it costs to keep true

Renaming `GlanceActivityAttributes` or changing `ContentState` on one side only
breaks the match at runtime with no compile error, on both sides at once. That
is the same failure mode as the App Group key layout, and it is guarded the
same way: `GlanceActivityAttributesTests` pins the type name and the encoded
shape, so a rename fails a test instead of a delivery.
