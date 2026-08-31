## What this changes

<!-- One paragraph: the behaviour before, and the behaviour after. -->

## Why

<!-- The defect or the gap. Link the issue if there is one. -->

## Evidence

<!-- Paste the output, do not summarise it. A change is not done until it is shown to work. -->

```
$ flutter analyze
$ flutter test
```

## Checklist

- [ ] `flutter analyze --fatal-infos --fatal-warnings` is clean on every package I touched
- [ ] `dart format` leaves no diff
- [ ] Tests cover the change, and a bug fix has a test that fails without the fix
- [ ] `flutter pub publish --dry-run` still reports a clean archive, if a published package changed
- [ ] `CHANGELOG.md` updated for any user-visible change
- [ ] Public members I added are documented
