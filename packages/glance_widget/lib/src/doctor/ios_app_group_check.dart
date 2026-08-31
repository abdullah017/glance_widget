import 'package:glance_widget/src/doctor/doctor_finding.dart';

/// One iOS target's side of the App Group agreement.
class IosTarget {
  /// Describes a target by what it declares and what it is allowed to open.
  const IosTarget({
    required this.name,
    required this.declaredGroup,
    required this.entitledGroups,
  });

  /// How the target is named in Xcode, e.g. `Runner` or `GlanceWidgets`.
  final String name;

  /// The `GlanceWidgetAppGroup` value in this target's `Info.plist`, or null
  /// when the key is absent.
  final String? declaredGroup;

  /// Every identifier in this target's `com.apple.security.application-groups`
  /// entitlement.
  final Set<String> entitledGroups;
}

/// Reports what will stop the app and its widget extension sharing data.
///
/// This is the failure the plugin used to ship with, and it is worth checking
/// because none of its forms produces an error at runtime. `UserDefaults(
/// suiteName:)` returns nil for a group the target is not entitled to -- it
/// does not throw -- so every write is dropped and every read comes back nil.
/// Two targets naming *different* groups is quieter still: both calls succeed,
/// both stores work, and they are simply not the same store. In each case the
/// only symptom is a widget that never leaves its placeholder.
///
/// Findings are per target, because that is the granularity of the fix.
List<DoctorFinding> checkIosAppGroup({
  required IosTarget app,
  required IosTarget widgetExtension,
}) {
  final findings = <DoctorFinding>[];
  final targets = [app, widgetExtension];

  for (final target in targets) {
    findings.addAll(_checkTarget(target));
  }

  // Only compare once both sides said something valid. If either is missing or
  // malformed, "they disagree" is not a separate problem to fix -- it is the
  // same problem, and reporting it twice sends the reader chasing a phantom.
  if (findings.isEmpty) {
    final appGroup = _normalized(app.declaredGroup);
    final extensionGroup = _normalized(widgetExtension.declaredGroup);
    if (appGroup != extensionGroup) {
      findings.add(
        DoctorFinding(
          severity: DoctorSeverity.error,
          title:
              '${app.name} and ${widgetExtension.name} name different '
              'App Groups',
          detail:
              '${app.name} declares $appGroup and ${widgetExtension.name} '
              'declares $extensionGroup. Both stores open, so nothing fails -- '
              'they are just not the same store, and the widget never sees what '
              'the app writes. Set GlanceWidgetAppGroup to one identifier in '
              'both Info.plists.',
        ),
      );
    }
  }

  return findings;
}

List<DoctorFinding> _checkTarget(IosTarget target) {
  final declared = target.declaredGroup;

  if (declared == null) {
    return [
      DoctorFinding(
        severity: DoctorSeverity.error,
        title: '${target.name} does not declare GlanceWidgetAppGroup',
        detail:
            "Add <key>GlanceWidgetAppGroup</key> to ${target.name}'s Info.plist "
            'with your App Group identifier. Without it the plugin falls back to '
            "the example's group, which your app is not entitled to, so every "
            'widget update is silently dropped.',
      ),
    ];
  }

  final group = _normalized(declared);

  if (group.isEmpty || !group.startsWith('group.') || group == 'group.') {
    return [
      DoctorFinding(
        severity: DoctorSeverity.error,
        title: '${target.name} declares an App Group that cannot open a store',
        detail:
            'GlanceWidgetAppGroup is "$declared". An App Group identifier has '
            'to begin with "group." and have something after it. A blank value, '
            'an unsubstituted build setting like \$(APP_GROUP), or a bundle id '
            'pasted in by mistake all leave UserDefaults returning nil with no '
            'error raised.',
      ),
    ];
  }

  // An empty entitlement list means we could not find or read the file. Saying
  // "you are not entitled" on that evidence would be a guess, and a diagnostic
  // that cries wolf costs more than no diagnostic.
  if (target.entitledGroups.isNotEmpty &&
      !target.entitledGroups.contains(group)) {
    return [
      DoctorFinding(
        severity: DoctorSeverity.error,
        title: '${target.name} is not entitled to $group',
        detail:
            '${target.name} declares $group but its App Groups entitlement '
            'lists ${target.entitledGroups.join(', ')}. UserDefaults(suiteName:) '
            'returns nil for a group the target cannot open, and returning nil '
            'is not an error -- writes are dropped and reads come back empty. '
            "Add $group to the target's App Groups capability in Xcode.",
      ),
    ];
  }

  return const [];
}

String _normalized(String? value) => value?.trim() ?? '';

/// Reads the string value of [key] from a plist, or null when it is absent.
///
/// Scans text rather than parsing XML so the package does not drag an XML
/// parser into every app that depends on it. It is written to stay silent when
/// it cannot tell, never to guess.
String? readPlistString(String plist, String key) {
  final source = _withoutComments(plist);
  final pattern = RegExp(
    '<key>\\s*${RegExp.escape(key)}\\s*</key>\\s*<string>([^<]*)</string>',
    multiLine: true,
  );
  final match = pattern.firstMatch(source);
  return match?.group(1);
}

/// Reads every identifier in an entitlements file's App Groups array.
Set<String> readEntitlementAppGroups(String entitlements) {
  final source = _withoutComments(entitlements);
  final array = RegExp(
    r'<key>\s*com\.apple\.security\.application-groups\s*</key>\s*<array>'
    r'([\s\S]*?)</array>',
    multiLine: true,
  ).firstMatch(source);
  if (array == null) return const {};

  return RegExp(r'<string>([^<]*)</string>')
      .allMatches(array.group(1)!)
      .map((m) => m.group(1)!.trim())
      .where((value) => value.isNotEmpty)
      .toSet();
}

/// Strips XML comments, so a commented-out key does not read as configuration.
String _withoutComments(String source) =>
    source.replaceAll(RegExp(r'<!--[\s\S]*?-->'), '');
