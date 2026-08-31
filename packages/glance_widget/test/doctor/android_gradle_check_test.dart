import 'package:flutter_test/flutter_test.dart';
import 'package:glance_widget/src/doctor/android_gradle_check.dart';
import 'package:glance_widget/src/doctor/doctor_finding.dart';

void main() {
  group('readMinSdk', () {
    test('reads the Kotlin DSL form', () {
      expect(readMinSdk('    minSdk = 26\n'), 26);
    });

    test('reads the Groovy form', () {
      expect(readMinSdk('    minSdkVersion 21\n'), 21);
    });

    test('reads the Groovy assignment form', () {
      expect(readMinSdk('    minSdkVersion = 24\n'), 24);
    });

    test('returns null for a value it cannot resolve', () {
      // flutter.minSdkVersion resolves at build time, not here. Guessing what
      // it stands for would produce a finding about a number nobody wrote.
      expect(readMinSdk('    minSdk = flutter.minSdkVersion\n'), isNull);
    });

    test('returns null when nothing declares it', () {
      expect(readMinSdk('android {\n}\n'), isNull);
    });

    test('ignores a commented-out declaration', () {
      expect(readMinSdk('    // minSdk = 21\n'), isNull);
    });
  });

  group('checkAndroidGradle', () {
    test('says nothing at the required level', () {
      expect(checkAndroidGradle(gradle: 'minSdk = 26'), isEmpty);
    });

    test('says nothing above it', () {
      expect(checkAndroidGradle(gradle: 'minSdk = 34'), isEmpty);
    });

    test('flags a minSdk below what Glance needs', () {
      final findings = checkAndroidGradle(gradle: 'minSdk = 21');
      expect(findings, hasLength(1));
      expect(findings.single.severity, DoctorSeverity.error);
      expect(findings.single.detail, contains('21'));
      expect(findings.single.detail, contains('26'));
    });

    test('stays silent when it cannot read the value', () {
      // Better to say nothing than to report a project as broken because its
      // build file is written in a way this scan does not recognise.
      expect(
        checkAndroidGradle(gradle: 'minSdk = flutter.minSdkVersion'),
        isEmpty,
      );
    });
  });
}
