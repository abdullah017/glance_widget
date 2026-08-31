#!/usr/bin/env bash
# Runs the same gates CI runs, in the same order, with the same flags.
#
# CI failed twice on formatting alone because `flutter analyze` was the only
# thing checked locally -- the formatter is a separate gate and says nothing
# during analysis. Anything added to `.github/workflows/ci.yml` belongs here
# too, or the two drift and this script stops being worth running.
set -uo pipefail

cd "$(dirname "$0")/.."

PACKAGES=(
  packages/glance_widget
  packages/glance_widget_platform_interface
  packages/glance_widget_android
  packages/glance_widget_ios
  packages/glance_widget/example
)

FIX=0
[[ "${1:-}" == "--fix" ]] && FIX=1

failed=()

run() {
  local label="$1"; shift
  if "$@" >/tmp/glance_verify.log 2>&1; then
    printf '  ✓ %s\n' "$label"
  else
    printf '  ✗ %s\n' "$label"
    sed 's/^/      /' /tmp/glance_verify.log | tail -30
    failed+=("$label")
  fi
}

if (( FIX )); then
  echo "Formatting…"
  dart format . >/dev/null
fi

echo "Resolving workspace…"
flutter pub get >/dev/null || { echo "pub get failed"; exit 1; }

for pkg in "${PACKAGES[@]}"; do
  echo "$pkg"
  run "format"   dart format --set-exit-if-changed --output=none "$pkg"
  run "analyze"  bash -c "cd '$pkg' && flutter analyze --fatal-infos --fatal-warnings"
  run "test"     bash -c "cd '$pkg' && flutter test --reporter=compact"
done

echo
echo "Kotlin unit tests"
# The plugin has no Gradle wrapper of its own -- it builds as a module of
# whichever app includes it -- so the example app's wrapper drives it here, the
# same way CI does. Skipped rather than failed when no JDK is installed, since
# the Dart gates above are still worth running on their own.
if command -v java >/dev/null 2>&1; then
  run "android-unit-tests" bash -c \
    "cd packages/glance_widget/example/android && ./gradlew :glance_widget_android:testDebugUnitTest --console=plain"
else
  echo "  skipped: no JDK on PATH"
fi

echo
echo "iOS unit tests"
# The templates are compiled by the example's widget extension and by its test
# target, so this is what stands between a renamed field and a template that
# silently stops working. It is the slowest gate here -- it boots a simulator --
# and it is the only one that builds the thing that actually ships.
if command -v xcrun >/dev/null 2>&1; then
  run "ios-unit-tests" ./tool/test_ios.sh
else
  echo "  skipped: no Xcode toolchain on PATH"
fi

echo
echo "Publish dry-run"
for pkg in "${PACKAGES[@]}"; do
  [[ "$pkg" == */example ]] && continue
  run "$pkg" bash -c "cd '$pkg' && dart pub publish --dry-run"
done

echo
if (( ${#failed[@]} )); then
  printf 'FAILED: %s\n' "${failed[*]}"
  exit 1
fi
echo "All CI gates pass locally."
