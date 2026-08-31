import 'package:glance_widget/src/doctor/doctor_finding.dart';

/// The API level Jetpack Glance itself requires. Below this the plugin's
/// manifest cannot merge into the app's.
const int glanceMinSdk = 26;

/// Reports build-file settings that will stop the Android widget working.
///
/// Unlike the manifest checks, this one has a loud failure mode: the Gradle
/// build stops with a manifest merger error. It is here because that error
/// names `uses-sdk` and a library coordinate, never "widget", so the reader is
/// told which two numbers disagree but not which dependency wants the higher
/// one or why.
List<DoctorFinding> checkAndroidGradle({required String gradle}) {
  final minSdk = readMinSdk(gradle);

  // Unresolvable is not the same as wrong. A project using
  // `flutter.minSdkVersion` may well be fine, and calling it broken on no
  // evidence teaches the reader to ignore the doctor.
  if (minSdk == null || minSdk >= glanceMinSdk) return const [];

  return [
    DoctorFinding(
      severity: DoctorSeverity.error,
      title: 'minSdk is $minSdk, below the $glanceMinSdk Glance requires',
      detail:
          'Set minSdk = $glanceMinSdk in android/app/build.gradle.kts. Jetpack '
          'Glance app widgets need Android 8.0. Left as $minSdk the build stops '
          'with a manifest merger error about uses-sdk that never mentions '
          'widgets, so it reads like a dependency conflict.',
    ),
  ];
}

/// Reads the app's declared `minSdk`, or null when it is absent or is an
/// expression this cannot resolve without running Gradle.
int? readMinSdk(String gradle) {
  final source = _withoutComments(gradle);
  // Covers `minSdk = 26` (Kotlin DSL), `minSdkVersion 21` (Groovy), and
  // `minSdkVersion = 24`. A non-literal such as `flutter.minSdkVersion` does
  // not match, which is the intent -- it resolves at build time, not here.
  final match = RegExp(
    r'\bminSdk(?:Version)?\s*=?\s*(\d+)\b',
  ).firstMatch(source);
  if (match == null) return null;
  return int.tryParse(match.group(1)!);
}

/// Strips line and block comments, so a commented-out setting does not read as
/// configuration.
String _withoutComments(String source) => source
    .replaceAll(RegExp(r'/\*[\s\S]*?\*/'), '')
    .replaceAll(RegExp(r'//[^\n]*'), '');
