import 'dart:io';

import 'package:glance_widget/src/doctor/doctor.dart';
import 'package:glance_widget/src/doctor/doctor_finding.dart';

/// Checks a Flutter project's native widget setup.
///
/// Run from a project root:
///
/// ```sh
/// dart run glance_widget:doctor
/// ```
///
/// Exits 1 when something found will actually stop a widget working, so it can
/// be dropped into CI. Warnings alone exit 0.
void main(List<String> arguments) {
  final root = Directory(arguments.isEmpty ? '.' : arguments.first);

  if (!root.existsSync()) {
    stderr.writeln('No such directory: ${root.path}');
    exit(2);
  }

  if (!File('${root.path}/pubspec.yaml').existsSync()) {
    stderr.writeln(
      'No pubspec.yaml in ${root.absolute.path}. Run this from a Flutter '
      'project root, or pass the path to one.',
    );
    exit(2);
  }

  final report = runDoctor(root);

  for (final finding in report.findings) {
    final label = finding.severity == DoctorSeverity.error ? 'error' : 'warn ';
    stdout.writeln('[$label] ${finding.title}');
    stdout.writeln('        ${_wrap(finding.detail)}');
    stdout.writeln();
  }

  // Printed after the findings, and never counted as good news: a platform
  // that was not inspected is not a platform that passed.
  for (final skipped in report.skipped) {
    stdout.writeln('[skip ] $skipped');
  }
  if (report.skipped.isNotEmpty) stdout.writeln();

  if (report.findings.isEmpty && report.skipped.isEmpty) {
    stdout.writeln('No problems found.');
  } else if (report.findings.isEmpty) {
    stdout.writeln('No problems found in what could be inspected.');
  } else {
    final errors = report.findings
        .where((f) => f.severity == DoctorSeverity.error)
        .length;
    final warnings = report.findings.length - errors;
    stdout.writeln('$errors error(s), $warnings warning(s).');
  }

  exit(report.hasErrors ? 1 : 0);
}

/// Re-wraps a detail to the terminal, indented under its title.
String _wrap(String detail, {int width = 72}) {
  final words = detail.split(RegExp(r'\s+'));
  final lines = <String>[];
  var line = StringBuffer();

  for (final word in words) {
    if (line.isEmpty) {
      line.write(word);
    } else if (line.length + 1 + word.length <= width) {
      line
        ..write(' ')
        ..write(word);
    } else {
      lines.add(line.toString());
      line = StringBuffer(word);
    }
  }
  if (line.isNotEmpty) lines.add(line.toString());

  return lines.join('\n        ');
}
