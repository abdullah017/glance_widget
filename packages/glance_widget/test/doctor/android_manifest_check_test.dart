import 'package:flutter_test/flutter_test.dart';
import 'package:glance_widget/src/doctor/android_manifest_check.dart';
import 'package:glance_widget/src/doctor/doctor_finding.dart';

/// The Android setup is three hand-edited files per template, and every way of
/// getting it wrong fails silently: the widget simply never appears in the
/// picker, or appears and never updates. Nothing throws, and there is nothing
/// in the logs to read.
///
/// The checks scan text rather than parse XML, so they are written to say
/// "could not tell" rather than invent a problem. A diagnostic that cries wolf
/// is worse than no diagnostic.
void main() {
  const goodReceiver = '''
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

  group('a correct manifest', () {
    test('produces no findings', () {
      final findings = checkAndroidManifest(
        manifest: goodReceiver,
        widgetInfoResources: {'simple_widget_info'},
      );

      expect(findings, isEmpty);
    });

    test('survives single quotes and reordered attributes', () {
      final findings = checkAndroidManifest(
        manifest: goodReceiver
            .replaceAll('"', "'")
            .replaceAll(
              "android:name='dev.glance.widget.android.templates.SimpleWidgetReceiver'\n        android:exported='true'",
              "android:exported='true'\n        android:name='dev.glance.widget.android.templates.SimpleWidgetReceiver'",
            ),
        widgetInfoResources: {'simple_widget_info'},
      );

      expect(findings, isEmpty);
    });
  });

  group('a receiver that will not install', () {
    test('flags a missing android:exported', () {
      // targetSdk 31+ refuses to install a component with an intent-filter and
      // no explicit exported. The build fails with a manifest merger error that
      // does not mention widgets.
      final findings = checkAndroidManifest(
        manifest: goodReceiver.replaceAll('\n        android:exported="true"', ''),
        widgetInfoResources: {'simple_widget_info'},
      );

      expect(findings, hasLength(1));
      expect(findings.single.severity, DoctorSeverity.error);
      expect(findings.single.title, contains('exported'));
    });

    test('flags exported set to false', () {
      // Installs, but the launcher cannot see the receiver, so the widget never
      // reaches the picker.
      final findings = checkAndroidManifest(
        manifest: goodReceiver.replaceAll('android:exported="true"', 'android:exported="false"'),
        widgetInfoResources: {'simple_widget_info'},
      );

      expect(findings.single.severity, DoctorSeverity.error);
      expect(findings.single.title, contains('exported'));
    });
  });

  test('flags a receiver with no APPWIDGET_UPDATE filter', () {
    // The widget can be placed and then never updates, which reads as the
    // plugin being broken.
    final findings = checkAndroidManifest(
      manifest: goodReceiver.replaceAll(
        '<action android:name="android.appwidget.action.APPWIDGET_UPDATE" />',
        '',
      ),
      widgetInfoResources: {'simple_widget_info'},
    );

    expect(findings.single.severity, DoctorSeverity.error);
    expect(findings.single.title, contains('APPWIDGET_UPDATE'));
  });

  test('flags a receiver pointing at an xml file that does not exist', () {
    final findings = checkAndroidManifest(
      manifest: goodReceiver,
      widgetInfoResources: <String>{},
    );

    expect(findings.single.severity, DoctorSeverity.error);
    expect(findings.single.title, contains('simple_widget_info'));
  });

  test('flags a receiver with no provider meta-data at all', () {
    final findings = checkAndroidManifest(
      manifest: goodReceiver.replaceAll(
        RegExp(r'<meta-data[\s\S]*?/>'),
        '',
      ),
      widgetInfoResources: {'simple_widget_info'},
    );

    // Only one finding: the orphaned widget info file is a symptom of this
    // receiver, and naming both would send the reader after the wrong one.
    expect(findings, hasLength(1));
    expect(findings.single.severity, DoctorSeverity.error);
    expect(findings.single.title, contains('provider'));
  });

  test('mentions an unused widget info file, but only as a warning', () {
    // Harmless, and usually means a receiver was deleted and the xml was not.
    final findings = checkAndroidManifest(
      manifest: goodReceiver,
      widgetInfoResources: {'simple_widget_info', 'list_widget_info'},
    );

    expect(findings.single.severity, DoctorSeverity.warning);
    expect(findings.single.title, contains('list_widget_info'));
  });

  test('says nothing is set up when no receiver is declared', () {
    final findings = checkAndroidManifest(
      manifest: '<manifest><application></application></manifest>',
      widgetInfoResources: <String>{},
    );

    expect(findings.single.severity, DoctorSeverity.error);
    expect(findings.single.title, contains('No widget receiver'));
  });

  test('ignores receivers that have nothing to do with this plugin', () {
    final findings = checkAndroidManifest(
      manifest: '''
<manifest>
  <application>
    <receiver android:name="com.example.SomeOtherReceiver" android:exported="false" />
    $goodReceiver
  </application>
</manifest>
''',
      widgetInfoResources: {'simple_widget_info'},
    );

    expect(findings, isEmpty);
  });

  test('a commented-out receiver does not count as configured', () {
    // Commenting a receiver out while debugging and forgetting is common; the
    // widget vanishes from the picker with no other symptom.
    final findings = checkAndroidManifest(
      manifest: '<manifest><application><!--$goodReceiver--></application></manifest>',
      widgetInfoResources: <String>{},
    );

    expect(findings.single.title, contains('No widget receiver'));
  });
}
