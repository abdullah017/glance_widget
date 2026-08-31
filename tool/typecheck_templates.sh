#!/usr/bin/env bash
# Type-checks the iOS widget-extension templates.
#
# These Swift files are copied into a developer's own widget extension; nothing
# in this repository builds them, so a type error or a renamed field can sit
# there indefinitely. That is exactly how the image `fit` key drifted apart from
# what Dart sends. This compiles them against the real iOS SDK without linking.
set -euo pipefail

cd "$(dirname "$0")/.."
TEMPLATES="packages/glance_widget_ios/example/ios/GlanceWidgets"

if ! command -v xcrun >/dev/null 2>&1; then
  echo "skipped: no Xcode toolchain on PATH"
  exit 0
fi

SDK="$(xcrun --sdk iphoneos --show-sdk-path)"
echo "Type-checking $TEMPLATES against $(basename "$SDK")"

# Warnings are reported but do not fail: the templates carry a known backlog of
# non-exhaustive `WidgetFamily` switches, tracked separately. Errors do fail.
swiftc -typecheck -sdk "$SDK" -target arm64-apple-ios16.0 "$TEMPLATES"/*.swift
echo "Templates type-check clean."
