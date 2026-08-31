import 'package:flutter_test/flutter_test.dart';
import 'package:glance_widget/src/doctor/doctor_finding.dart';
import 'package:glance_widget/src/doctor/ios_app_group_check.dart';

/// A plist declaring [group], or one with no such key when [group] is null.
String plistWith(String? group) {
  final entry = group == null
      ? ''
      : '\t<key>GlanceWidgetAppGroup</key>\n\t<string>$group</string>\n';
  return '<?xml version="1.0" encoding="UTF-8"?>\n'
      '<plist version="1.0">\n<dict>\n'
      '\t<key>CFBundleName</key>\n\t<string>Runner</string>\n'
      '$entry'
      '</dict>\n</plist>\n';
}

/// An entitlements file granting [groups].
String entitlementsWith(List<String> groups) {
  if (groups.isEmpty) {
    return '<?xml version="1.0" encoding="UTF-8"?>\n'
        '<plist version="1.0">\n<dict/>\n</plist>\n';
  }
  final items = groups.map((g) => '\t\t<string>$g</string>').join('\n');
  return '<?xml version="1.0" encoding="UTF-8"?>\n'
      '<plist version="1.0">\n<dict>\n'
      '\t<key>com.apple.security.application-groups</key>\n'
      '\t<array>\n$items\n\t</array>\n'
      '</dict>\n</plist>\n';
}

/// A target that is set up correctly, for tests that break exactly one thing.
IosTarget healthy(String name, {String group = 'group.com.acme.app'}) =>
    IosTarget(
      name: name,
      declaredGroup: readPlistString(plistWith(group), 'GlanceWidgetAppGroup'),
      entitledGroups: readEntitlementAppGroups(entitlementsWith([group])),
    );

void main() {
  group('readPlistString', () {
    test('reads the value that follows the key', () {
      expect(
        readPlistString(
          plistWith('group.com.acme.app'),
          'GlanceWidgetAppGroup',
        ),
        'group.com.acme.app',
      );
    });

    test('returns null when the key is absent', () {
      expect(readPlistString(plistWith(null), 'GlanceWidgetAppGroup'), isNull);
    });

    test('does not read a value out of a commented-out key', () {
      const plist =
          '<dict>\n'
          '<!-- <key>GlanceWidgetAppGroup</key><string>group.old</string> -->\n'
          '</dict>';
      expect(readPlistString(plist, 'GlanceWidgetAppGroup'), isNull);
    });

    test('reads the right key when another key precedes it', () {
      const plist =
          '<dict>\n'
          '<key>Other</key><string>nope</string>\n'
          '<key>GlanceWidgetAppGroup</key><string>group.com.acme.app</string>\n'
          '</dict>';
      expect(
        readPlistString(plist, 'GlanceWidgetAppGroup'),
        'group.com.acme.app',
      );
    });
  });

  group('readEntitlementAppGroups', () {
    test('reads every group in the array', () {
      final groups = readEntitlementAppGroups(
        entitlementsWith(['group.a', 'group.b']),
      );
      expect(groups, {'group.a', 'group.b'});
    });

    test('returns nothing when the entitlement is absent', () {
      expect(readEntitlementAppGroups(entitlementsWith([])), isEmpty);
    });
  });

  group('checkIosAppGroup', () {
    test('says nothing when both targets agree and are entitled', () {
      final findings = checkIosAppGroup(
        app: healthy('Runner'),
        widgetExtension: healthy('GlanceWidgets'),
      );
      expect(findings, isEmpty);
    });

    test('flags a missing key, naming the target', () {
      final findings = checkIosAppGroup(
        app: const IosTarget(
          name: 'Runner',
          declaredGroup: null,
          entitledGroups: {'group.com.acme.app'},
        ),
        widgetExtension: healthy('GlanceWidgets'),
      );
      expect(findings, hasLength(1));
      expect(findings.single.severity, DoctorSeverity.error);
      expect(findings.single.title, contains('Runner'));
      expect(findings.single.detail, contains('GlanceWidgetAppGroup'));
    });

    test('flags the two targets naming different groups', () {
      final findings = checkIosAppGroup(
        app: healthy('Runner', group: 'group.com.acme.app'),
        widgetExtension: healthy('GlanceWidgets', group: 'group.com.acme.old'),
      );
      expect(findings, hasLength(1));
      expect(findings.single.severity, DoctorSeverity.error);
      expect(findings.single.detail, contains('group.com.acme.app'));
      expect(findings.single.detail, contains('group.com.acme.old'));
    });

    test('flags a group the target is not entitled to', () {
      final findings = checkIosAppGroup(
        app: const IosTarget(
          name: 'Runner',
          declaredGroup: 'group.com.acme.app',
          entitledGroups: {'group.com.acme.other'},
        ),
        widgetExtension: healthy('GlanceWidgets'),
      );
      expect(findings, hasLength(1));
      expect(findings.single.severity, DoctorSeverity.error);
      expect(findings.single.detail, contains('nil'));
    });

    test('flags a value that could never open a suite', () {
      final findings = checkIosAppGroup(
        app: const IosTarget(
          name: 'Runner',
          declaredGroup: r'$(APP_GROUP)',
          entitledGroups: {'group.com.acme.app'},
        ),
        widgetExtension: healthy('GlanceWidgets'),
      );
      expect(findings, hasLength(1));
      expect(findings.single.severity, DoctorSeverity.error);
      expect(findings.single.title, contains('Runner'));
    });

    test('flags a bundle id pasted in where a group belongs', () {
      final findings = checkIosAppGroup(
        app: const IosTarget(
          name: 'Runner',
          declaredGroup: 'com.acme.app',
          entitledGroups: {'group.com.acme.app'},
        ),
        widgetExtension: healthy('GlanceWidgets'),
      );
      expect(findings, hasLength(1));
      expect(findings.single.detail, contains('group.'));
    });

    test('reports each target separately when both are wrong', () {
      final findings = checkIosAppGroup(
        app: const IosTarget(
          name: 'Runner',
          declaredGroup: null,
          entitledGroups: {},
        ),
        widgetExtension: const IosTarget(
          name: 'GlanceWidgets',
          declaredGroup: null,
          entitledGroups: {},
        ),
      );
      expect(findings, hasLength(2));
      expect(findings.map((f) => f.title).join(), contains('Runner'));
      expect(findings.map((f) => f.title).join(), contains('GlanceWidgets'));
    });

    test('does not also report a mismatch it cannot know about', () {
      // One target has no key at all. Whether the two "disagree" is not
      // knowable, and saying so would send the reader chasing a second
      // problem that does not exist.
      final findings = checkIosAppGroup(
        app: const IosTarget(
          name: 'Runner',
          declaredGroup: null,
          entitledGroups: {'group.com.acme.app'},
        ),
        widgetExtension: healthy('GlanceWidgets'),
      );
      expect(findings, hasLength(1));
    });

    test('trims whitespace before judging, as the plugin does', () {
      final findings = checkIosAppGroup(
        app: const IosTarget(
          name: 'Runner',
          declaredGroup: '  group.com.acme.app  ',
          entitledGroups: {'group.com.acme.app'},
        ),
        widgetExtension: healthy('GlanceWidgets'),
      );
      expect(findings, isEmpty);
    });
  });
}
