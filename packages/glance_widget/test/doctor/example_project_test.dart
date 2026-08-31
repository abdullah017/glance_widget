import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:glance_widget/src/doctor/ios_app_group_check.dart';

/// Runs the doctor against the reference setup this repo actually ships.
///
/// The unit tests prove the checks judge hand-written inputs correctly. They
/// cannot prove the checks agree with a real project, and a doctor that
/// disagrees with the setup its own README describes is worse than none: it
/// teaches the reader to ignore it.
///
/// This also guards the thing the check exists to catch. The App Group is named
/// in two Info.plists, in two different packages, and nothing but this test
/// makes them agree. If someone edits one and not the other, the shipped
/// example silently stops sharing data -- which is the exact bug the plugin
/// carried until v2.0.0.
void main() {
  // Test working directory is the package root.
  const appPlist = 'example/ios/Runner/Info.plist';
  const appEntitlements =
      '../glance_widget_ios/example/ios/Runner/Runner.entitlements';
  const extensionPlist =
      '../glance_widget_ios/example/ios/GlanceWidgets/Info.plist';
  const extensionEntitlements =
      '../glance_widget_ios/example/ios/GlanceWidgets/GlanceWidgets.entitlements';

  String read(String path) {
    final file = File(path);
    // A missing file means the repo moved, not that the setup is fine. Reading
    // an empty string here would let every assertion below pass vacuously.
    expect(
      file.existsSync(),
      isTrue,
      reason:
          'Expected $path relative to ${Directory.current.path}. '
          'If the example moved, update this test rather than deleting it.',
    );
    return file.readAsStringSync();
  }

  test('the shipped example passes its own App Group check', () {
    final findings = checkIosAppGroup(
      app: IosTarget(
        name: 'Runner',
        declaredGroup: readPlistString(read(appPlist), 'GlanceWidgetAppGroup'),
        entitledGroups: readEntitlementAppGroups(read(appEntitlements)),
      ),
      widgetExtension: IosTarget(
        name: 'GlanceWidgets',
        declaredGroup: readPlistString(
          read(extensionPlist),
          'GlanceWidgetAppGroup',
        ),
        entitledGroups: readEntitlementAppGroups(read(extensionEntitlements)),
      ),
    );

    expect(
      findings,
      isEmpty,
      reason:
          'The example project should be a working reference:\n'
          '${findings.join('\n\n')}',
    );
  });

  test('both Info.plists name a group, and the same one', () {
    // Stated separately from the check above so a regression says which of the
    // two files drifted, rather than only that the pair disagrees.
    final app = readPlistString(read(appPlist), 'GlanceWidgetAppGroup');
    final extension = readPlistString(
      read(extensionPlist),
      'GlanceWidgetAppGroup',
    );

    expect(app, isNotNull, reason: '$appPlist lost GlanceWidgetAppGroup');
    expect(
      extension,
      isNotNull,
      reason: '$extensionPlist lost GlanceWidgetAppGroup',
    );
    expect(extension, app);
  });

  test('both entitlements grant the group the plists name', () {
    final declared = readPlistString(read(appPlist), 'GlanceWidgetAppGroup');
    expect(declared, isNotNull);

    for (final path in [appEntitlements, extensionEntitlements]) {
      expect(
        readEntitlementAppGroups(read(path)),
        contains(declared),
        reason:
            '$path does not grant $declared, so UserDefaults would '
            'return nil for it',
      );
    }
  });
}
