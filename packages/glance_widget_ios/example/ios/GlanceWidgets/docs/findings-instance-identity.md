# Widget instance identity — findings

`widgetId` is documented as a "Unique identifier for this widget instance".
Both platforms broke that promise, in different places.

## Android — write path (FIXED, PR #5)

`GlanceAppWidgetManager.getGlanceIds(Class)` answers with every placed instance
of a template. All seven update paths wrote each update into all of them, so
updating `'btc'` overwrote a widget showing `'eth'`. The id was stored per
instance but only ever read back for rendering, never to pick a target.

Fixed by `WidgetInstanceResolver`, covered by 11 JVM unit tests.

## iOS — read path (FIXED, PR for issue #6)

The mirror image. Storage is correctly keyed per id:

    storage.save(widgetData, forKey: "\(simpleWidgetKeyPrefix)\(widgetId)")

but every example widget reads with no id at all:

    let data = WidgetStorage.shared.loadSimpleWidget() ?? .placeholder

which falls through to `loadMostRecent(prefix:)` — it scans every key with that
prefix and returns whichever has the newest timestamp. All 7 templates do this
(`SharedModels.swift:392`).

So on iOS two placed Simple widgets both render whichever id was updated last.
Same user-visible symptom as the Android defect, opposite cause.

The reason it could not be fixed the same way as Android: these widgets used
`StaticConfiguration`, which carries no per-instance parameter. There was
nothing for the extension to key on, so `loadMostRecent` was a symptom rather
than the cause.

Fixed by moving all seven templates to `AppIntentConfiguration` with a
`widgetId` parameter the person placing the widget selects, offered from the ids
the app has actually sent data for. `loadMostRecent` remains as the fallback for
an instance nobody has configured yet, so a freshly placed widget is not blank.

This raised the iOS floor to 17.0: `AppIntentConfiguration` is the only widget
configuration that carries a per-instance parameter, and it is iOS 17+.

## What kept both defects invisible

Neither platform had anything that could fail. The id was carried through the
whole stack and then dropped at one end, with no test anywhere in reach of the
drop.

Android is now covered by `WidgetInstanceResolver` and 11 JVM unit tests,
because the routing decision could be extracted into a type free of Android
types. iOS could not be covered the same way while the widget extension was not
built by this repository at all (issue #10), so no test could reach
`SimpleWidgetProvider`. The example app now ships one, and the templates are
compiled into its test target too.

What is covered is the contract underneath it: `GlanceStorageKeys` now owns the
App Group key layout that both halves depend on, and `GlanceStorageKeysTests`
pins the exact prefix strings the templates type out by hand. Renaming one used
to fail nothing and silently empty the configuration picker; it now turns three
tests red.
