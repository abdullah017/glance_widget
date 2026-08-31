import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:glance_widget/src/doctor/doctor.dart';
import 'package:glance_widget/src/doctor/doctor_finding.dart';

/// Builds a throwaway Flutter project tree to point the doctor at.
class _Project {
  _Project() : root = Directory.systemTemp.createTempSync('glance_doctor');

  final Directory root;

  void write(String relativePath, String contents) {
    final file = File('${root.path}/$relativePath');
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(contents);
  }

  void dispose() => root.deleteSync(recursive: true);

  /// A project with nothing wrong with it.
  void writeHealthy() {
    write('android/app/build.gradle.kts', 'android {\n  minSdk = 26\n}\n');
    write('android/app/src/main/AndroidManifest.xml', _manifest);
    write(
      'android/app/src/main/res/xml/simple_widget_info.xml',
      '<appwidget/>',
    );
    write('ios/Runner/Info.plist', _plist('group.com.acme.app'));
    write(
      'ios/Runner/Runner.entitlements',
      _entitlements('group.com.acme.app'),
    );
    write('ios/GlanceWidgets/Info.plist', _plist('group.com.acme.app'));
    write(
      'ios/GlanceWidgets/GlanceWidgets.entitlements',
      _entitlements('group.com.acme.app'),
    );
  }
}

const _manifest = '''
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
  <application>
    <receiver
        android:name="dev.glance.widget.android.templates.SimpleWidgetReceiver"
        android:exported="true">
      <intent-filter>
        <action android:name="android.appwidget.action.APPWIDGET_UPDATE" />
      </intent-filter>
      <meta-data
          android:name="android.appwidget.provider"
          android:resource="@xml/simple_widget_info" />
    </receiver>
  </application>
</manifest>
''';

String _plist(String group) =>
    '<?xml version="1.0" encoding="UTF-8"?>\n'
    '<plist version="1.0"><dict>\n'
    '<key>GlanceWidgetAppGroup</key><string>$group</string>\n'
    '</dict></plist>\n';

String _entitlements(String group) =>
    '<?xml version="1.0" encoding="UTF-8"?>\n'
    '<plist version="1.0"><dict>\n'
    '<key>com.apple.security.application-groups</key>\n'
    '<array><string>$group</string></array>\n'
    '</dict></plist>\n';

void main() {
  late _Project project;

  setUp(() => project = _Project());
  tearDown(() => project.dispose());

  test('a correctly configured project produces no findings', () {
    project.writeHealthy();
    expect(runDoctor(project.root).findings, isEmpty);
  });

  test('reports the Android manifest', () {
    project.writeHealthy();
    project.write(
      'android/app/src/main/AndroidManifest.xml',
      _manifest.replaceAll(
        'android:exported="true"',
        'android:exported="false"',
      ),
    );
    final findings = runDoctor(project.root).findings;
    expect(findings, isNotEmpty);
    expect(findings.first.severity, DoctorSeverity.error);
  });

  test('reports a minSdk below what Glance needs', () {
    project.writeHealthy();
    project.write(
      'android/app/build.gradle.kts',
      'android {\n  minSdk = 21\n}\n',
    );
    final findings = runDoctor(project.root).findings;
    expect(findings.map((f) => f.title).join(), contains('minSdk'));
  });

  test('reports two Info.plists that disagree', () {
    project.writeHealthy();
    // Move the extension wholesale to another group, entitlement included.
    // Changing only the plist would be a different, more specific fault -- the
    // extension not being entitled to what it names -- and the doctor rightly
    // reports that one instead.
    project.write('ios/GlanceWidgets/Info.plist', _plist('group.com.acme.old'));
    project.write(
      'ios/GlanceWidgets/GlanceWidgets.entitlements',
      _entitlements('group.com.acme.old'),
    );
    final findings = runDoctor(project.root).findings;
    expect(findings, hasLength(1));
    expect(findings.single.title, contains('different'));
    expect(findings.single.detail, contains('group.com.acme.old'));
  });

  test('reports an extension not entitled to the group it names', () {
    project.writeHealthy();
    project.write('ios/GlanceWidgets/Info.plist', _plist('group.com.acme.old'));
    final findings = runDoctor(project.root).findings;
    expect(findings, hasLength(1));
    expect(findings.single.title, contains('not entitled'));
  });

  test('finds a widget extension whatever it is named', () {
    project.writeHealthy();
    // Users rename the extension target; discovery must not depend on ours.
    File(
      '${project.root.path}/ios/GlanceWidgets/Info.plist',
    ).parent.renameSync('${project.root.path}/ios/MyWidgets');
    project.write('ios/MyWidgets/Info.plist', _plist('group.com.acme.app'));
    expect(runDoctor(project.root).findings, isEmpty);
  });

  test(
    'says which platforms it could not inspect rather than passing them',
    () {
      // An android/ directory that is not there is not an android/ directory
      // that is fine. Reporting "no findings" would read as a clean bill.
      project.write('ios/Runner/Info.plist', _plist('group.com.acme.app'));
      project.write(
        'ios/Runner/Runner.entitlements',
        _entitlements('group.com.acme.app'),
      );
      project.write(
        'ios/GlanceWidgets/Info.plist',
        _plist('group.com.acme.app'),
      );
      project.write(
        'ios/GlanceWidgets/GlanceWidgets.entitlements',
        _entitlements('group.com.acme.app'),
      );

      final report = runDoctor(project.root);
      expect(report.skipped.join(), contains('Android'));
      expect(report.findings, isEmpty);
    },
  );

  test('skips iOS when there is no widget extension to compare against', () {
    project.writeHealthy();
    Directory(
      '${project.root.path}/ios/GlanceWidgets',
    ).deleteSync(recursive: true);
    final report = runDoctor(project.root);
    expect(report.skipped.join(), contains('iOS'));
    expect(report.findings, isEmpty);
  });

  test('hasErrors is false when only warnings were found', () {
    project.writeHealthy();
    project.write(
      'android/app/src/main/res/xml/orphan_widget_info.xml',
      '<x/>',
    );
    final report = runDoctor(project.root);
    expect(report.findings.single.severity, DoctorSeverity.warning);
    expect(report.hasErrors, isFalse);
  });

  test('hasErrors is true when anything is an error', () {
    project.writeHealthy();
    project.write(
      'android/app/build.gradle.kts',
      'android {\n  minSdk = 21\n}\n',
    );
    expect(runDoctor(project.root).hasErrors, isTrue);
  });
}
