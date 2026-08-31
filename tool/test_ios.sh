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

# A Swift file that is not referenced by the Xcode project is simply not
# compiled: the suite passes, the new tests never run, and nothing says so.
# Silence has to be distinguishable from success, so check membership before
# trusting the result.
#
# Both lists matter for the same reason. A template that is in no target is not
# built by anything -- which is the state every template was in until #10, and
# how the `fit` key drifted apart from Dart unnoticed. It has to be in the
# extension, because that is what ships, and in RunnerTests, because that is
# what can assert about it.
echo "==> Checking every Swift file is in the Xcode project"
python3 - "$example" <<'EOF' || exit 1
import json, pathlib, subprocess, sys

example = pathlib.Path(sys.argv[1])
pbxproj = example / "ios/Runner.xcodeproj/project.pbxproj"
objects = json.loads(
    subprocess.run(
        ["plutil", "-convert", "json", "-o", "-", str(pbxproj)],
        check=True, capture_output=True,
    ).stdout
)["objects"]


def sources(target_name):
    """The basenames a target compiles."""
    target = next(
        o for o in objects.values()
        if o.get("isa") == "PBXNativeTarget" and o.get("name") == target_name
    )
    names = set()
    for phase_id in target["buildPhases"]:
        phase = objects[phase_id]
        if phase.get("isa") != "PBXSourcesBuildPhase":
            continue
        for build_file in phase["files"]:
            file_ref = objects[build_file].get("fileRef")
            if file_ref:
                names.add(pathlib.PurePath(objects[file_ref]["path"]).name)
    return names


expected = {
    # directory                                   -> targets that must compile it
    example / "ios/RunnerTests": ["RunnerTests"],
    example / "../../glance_widget_ios/example/ios/GlanceWidgets": [
        "GlanceWidgets",
        "RunnerTests",
    ],
}

compiled = {name: sources(name) for name in ("RunnerTests", "GlanceWidgets")}
missing = []
for directory, targets in expected.items():
    for swift in sorted(directory.glob("*.swift")):
        for target in targets:
            if swift.name not in compiled[target]:
                missing.append((swift.name, target))

if missing:
    print("error: these Swift files are not compiled by the target that needs", file=sys.stderr)
    print("       them, so nothing in this repository builds or tests them:", file=sys.stderr)
    for name, target in missing:
        print(f"         {name} -> {target}", file=sys.stderr)
    print("       Add each to that target (PBXBuildFile, PBXFileReference, a", file=sys.stderr)
    print("       group, and the Sources build phase), or run:", file=sys.stderr)
    print("         ruby -e 'require \"xcodeproj\"' # ships with CocoaPods", file=sys.stderr)
    raise SystemExit(1)
EOF

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
