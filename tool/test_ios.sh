#!/usr/bin/env bash
# Runs the iOS unit tests on a simulator, the way CI does.
#
# Two steps here are easy to skip by hand and both fail confusingly:
#
#   1. `flutter build ios --config-only` is what propagates the Xcode project's
#      IPHONEOS_DEPLOYMENT_TARGET into FlutterGeneratedPluginSwiftPackage.
#      `flutter pub get` rewrites that manifest at Flutter's own 15.0 default,
#      so running xcodebuild straight after a pub get fails with
#      "requires minimum platform version 17.0 ... but this target supports 15.0"
#      even though the project is configured correctly.
#
#   2. The set of installed simulators differs per machine and per Xcode
#      release, so the destination is discovered rather than hardcoded.
set -euo pipefail

cd "$(dirname "$0")/.."
example="packages/glance_widget/example"

echo "==> Resolving the workspace"
flutter pub get >/dev/null

echo "==> Generating the Xcode configuration"
(cd "$example" && flutter build ios --config-only --simulator >/dev/null)

# A Swift test file that is not referenced by the Xcode project is simply not
# compiled: the suite passes, the new tests never run, and nothing says so.
# Silence has to be distinguishable from success, so check the reference before
# trusting the result.
echo "==> Checking every test file is in the Xcode project"
missing=""
for file in "$example"/ios/RunnerTests/*.swift; do
  name=$(basename "$file")
  if ! grep -q "$name" "$example/ios/Runner.xcodeproj/project.pbxproj"; then
    missing="$missing $name"
  fi
done
if [ -n "$missing" ]; then
  echo "error: these test files are not in the Runner.xcodeproj test target," >&2
  echo "       so they would not be compiled and their tests would not run:" >&2
  for name in $missing; do echo "         $name" >&2; done
  echo "       Add each to the RunnerTests target (PBXBuildFile, PBXFileReference," >&2
  echo "       the RunnerTests group, and the Sources build phase)." >&2
  exit 1
fi

echo "==> Picking a simulator"
udid=$(xcrun simctl list devices available --json | python3 -c '
import json, sys
devices = json.load(sys.stdin)["devices"]
for runtime in sorted(devices, reverse=True):
    for device in devices[runtime]:
        if device["name"].startswith("iPhone"):
            print(device["udid"])
            raise SystemExit
raise SystemExit("no iPhone simulator is available")
')
echo "    using $udid"

echo "==> Running tests"
(cd "$example/ios" && xcodebuild test \
  -workspace Runner.xcworkspace \
  -scheme Runner \
  -destination "platform=iOS Simulator,id=$udid" \
  -quiet \
  CODE_SIGNING_ALLOWED=NO)
