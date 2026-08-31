import 'dart:io';

import 'package:glance_widget/src/doctor/android_gradle_check.dart';
import 'package:glance_widget/src/doctor/android_manifest_check.dart';
import 'package:glance_widget/src/doctor/doctor_finding.dart';
import 'package:glance_widget/src/doctor/ios_app_group_check.dart';

/// What the doctor found, and what it could not look at.
class DoctorReport {
  /// Creates a report.
  const DoctorReport({required this.findings, required this.skipped});

  /// Everything worth telling the reader about.
  final List<DoctorFinding> findings;

  /// Platforms that were not inspected, and why.
  ///
  /// Kept apart from [findings] because they mean opposite things. A platform
  /// with no findings has been looked at and is fine; a skipped one has not
  /// been looked at, and printing nothing for it would read as a clean bill.
  final List<String> skipped;

  /// Whether anything found will actually stop a widget working.
  bool get hasErrors => findings.any((f) => f.severity == DoctorSeverity.error);
}

/// Inspects a Flutter project's native setup for the mistakes that fail
/// quietly.
///
/// Every check reads files rather than building, so this runs in under a
/// second and works without an Android SDK or Xcode installed.
DoctorReport runDoctor(Directory projectRoot) {
  final findings = <DoctorFinding>[];
  final skipped = <String>[];

  final root = projectRoot.path;

  _inspectAndroid(root, findings, skipped);
  _inspectIos(root, findings, skipped);

  return DoctorReport(findings: findings, skipped: skipped);
}

void _inspectAndroid(
  String root,
  List<DoctorFinding> findings,
  List<String> skipped,
) {
  final manifest = File('$root/android/app/src/main/AndroidManifest.xml');
  if (!manifest.existsSync()) {
    skipped.add('Android: no android/app/src/main/AndroidManifest.xml');
    return;
  }

  final xmlDir = Directory('$root/android/app/src/main/res/xml');
  final widgetInfoResources = xmlDir.existsSync()
      ? xmlDir
            .listSync()
            .whereType<File>()
            .map((f) => f.uri.pathSegments.last)
            .where((name) => name.endsWith('.xml'))
            .map((name) => name.substring(0, name.length - '.xml'.length))
            .toSet()
      : <String>{};

  findings.addAll(
    checkAndroidManifest(
      manifest: manifest.readAsStringSync(),
      widgetInfoResources: widgetInfoResources,
    ),
  );

  final gradle = _firstExisting([
    '$root/android/app/build.gradle.kts',
    '$root/android/app/build.gradle',
  ]);
  if (gradle != null) {
    findings.addAll(checkAndroidGradle(gradle: gradle.readAsStringSync()));
  }
}

void _inspectIos(
  String root,
  List<DoctorFinding> findings,
  List<String> skipped,
) {
  final appPlist = File('$root/ios/Runner/Info.plist');
  if (!appPlist.existsSync()) {
    skipped.add('iOS: no ios/Runner/Info.plist');
    return;
  }

  final extensionDir = _findWidgetExtension(root);
  if (extensionDir == null) {
    // Without both sides there is nothing to compare, and half the check is
    // the half that misleads: the app's own plist can look perfect while the
    // extension names a different group.
    skipped.add(
      'iOS: no widget extension found under ios/ (a directory other than '
      'Runner holding an Info.plist)',
    );
    return;
  }

  findings.addAll(
    checkIosAppGroup(
      app: _target('Runner', '$root/ios/Runner'),
      widgetExtension: _target(
        extensionDir.uri.pathSegments.where((s) => s.isNotEmpty).last,
        extensionDir.path,
      ),
    ),
  );
}

IosTarget _target(String name, String dir) {
  final plist = File('$dir/Info.plist');
  final entitlements = Directory(dir)
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.entitlements'))
      .toList();

  return IosTarget(
    name: name,
    declaredGroup: plist.existsSync()
        ? readPlistString(plist.readAsStringSync(), 'GlanceWidgetAppGroup')
        : null,
    // Merged rather than picking one: a target can carry more than one
    // entitlements file across configurations, and being granted the group in
    // any of them is enough for the check to stay quiet.
    entitledGroups: entitlements
        .expand((f) => readEntitlementAppGroups(f.readAsStringSync()))
        .toSet(),
  );
}

/// Finds the widget extension by shape rather than by name, because the target
/// is the developer's to name and most rename it.
Directory? _findWidgetExtension(String root) {
  final ios = Directory('$root/ios');
  if (!ios.existsSync()) return null;

  for (final entry in ios.listSync().whereType<Directory>()) {
    final name = entry.uri.pathSegments.where((s) => s.isNotEmpty).last;
    if (name == 'Runner' || name == 'Flutter' || name == 'Pods') continue;
    if (name.startsWith('.') || name.endsWith('Tests')) continue;
    if (File('${entry.path}/Info.plist').existsSync()) return entry;
  }
  return null;
}

File? _firstExisting(List<String> paths) {
  for (final path in paths) {
    final file = File(path);
    if (file.existsSync()) return file;
  }
  return null;
}
