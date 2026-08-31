import 'package:glance_widget/src/doctor/doctor_finding.dart';

/// Reads an `AndroidManifest.xml` and reports what will stop a widget working.
///
/// Every mistake this looks for fails quietly. A receiver without
/// `android:exported` fails the build with a manifest merger error that never
/// says "widget"; one with `exported="false"` installs and never reaches the
/// picker; one without an `APPWIDGET_UPDATE` filter can be placed and then
/// never updates. None of them throws, and none appears in a log.
///
/// This scans text rather than parsing XML, so the package does not have to
/// drag an XML parser into every app that depends on it. The trade is that it
/// can be defeated by unusual formatting -- so it is written to stay silent
/// when it cannot tell, never to guess. A diagnostic that cries wolf costs more
/// than no diagnostic.
///
/// [widgetInfoResources] is the set of file names, without the `.xml`, found in
/// `android/app/src/main/res/xml/`.
List<DoctorFinding> checkAndroidManifest({
  required String manifest,
  required Set<String> widgetInfoResources,
}) {
  final source = _withoutComments(manifest);
  final receivers = _findGlanceReceivers(source);

  if (receivers.isEmpty) {
    return const [
      DoctorFinding(
        severity: DoctorSeverity.error,
        title: 'No widget receiver is declared in AndroidManifest.xml',
        detail:
            "Nothing will appear in the launcher's widget picker. Each template "
            'needs a <receiver> for its ...templates.<Name>WidgetReceiver class. '
            'See the Android Setup section of the README.',
      ),
    ];
  }

  final findings = <DoctorFinding>[];
  final referenced = <String>{};

  for (final receiver in receivers) {
    findings.addAll(_checkReceiver(receiver, widgetInfoResources));
    final resource = receiver.providerResource;
    if (resource != null) referenced.add(resource);
  }

  // A receiver that lost its meta-data leaves its widget info file looking
  // orphaned. Reporting both makes the reader chase the wrong one, so the
  // symptom stays quiet while the cause is on screen.
  final someReceiverHasNoProvider = receivers.any(
    (r) => r.providerResource == null,
  );

  for (final unused
      in someReceiverHasNoProvider
          ? const <String>[]
          : widgetInfoResources.difference(referenced)) {
    findings.add(
      DoctorFinding(
        severity: DoctorSeverity.warning,
        title: 'res/xml/$unused.xml is not referenced by any receiver',
        detail:
            'Harmless, but it usually means a receiver was removed and its '
            'widget info file was left behind. Delete the file, or add the '
            'receiver that was meant to use it.',
      ),
    );
  }

  return findings;
}

List<DoctorFinding> _checkReceiver(
  _Receiver receiver,
  Set<String> widgetInfoResources,
) {
  final findings = <DoctorFinding>[];
  final name = receiver.simpleName;

  if (receiver.exported != true) {
    findings.add(
      DoctorFinding(
        severity: DoctorSeverity.error,
        title: receiver.exported == null
            ? '$name has no android:exported'
            : '$name has android:exported="false"',
        detail: receiver.exported == null
            ? 'A component with an <intent-filter> must set android:exported '
                  'explicitly from targetSdk 31. The build fails with a manifest '
                  'merger error that does not mention widgets. Set it to true.'
            : 'The launcher cannot see a receiver it is not allowed to start, so '
                  'the widget never reaches the picker. Set it to true.',
      ),
    );
  }

  if (!receiver.hasUpdateFilter) {
    findings.add(
      DoctorFinding(
        severity: DoctorSeverity.error,
        title: '$name has no APPWIDGET_UPDATE intent filter',
        detail:
            'The widget can be placed and will then never update, which reads '
            'as the plugin being broken. Add <action android:name='
            '"android.appwidget.action.APPWIDGET_UPDATE" /> inside an '
            '<intent-filter>.',
      ),
    );
  }

  final resource = receiver.providerResource;
  if (resource == null) {
    findings.add(
      DoctorFinding(
        severity: DoctorSeverity.error,
        title: '$name declares no android.appwidget.provider meta-data',
        detail:
            'Android has no size, preview or resize rules for the widget and '
            'will not offer it. Add the <meta-data> pointing at your '
            'res/xml/..._widget_info.xml.',
      ),
    );
  } else if (!widgetInfoResources.contains(resource)) {
    findings.add(
      DoctorFinding(
        severity: DoctorSeverity.error,
        title: '$name points at @xml/$resource, which does not exist',
        detail:
            'Create android/app/src/main/res/xml/$resource.xml. The build may '
            'succeed and the widget will be missing from the picker.',
      ),
    );
  }

  return findings;
}

/// Removes `<!-- ... -->` so a commented-out receiver does not read as one that
/// is configured. Forgetting to uncomment one is a quiet way to lose a widget.
String _withoutComments(String xml) =>
    xml.replaceAll(RegExp(r'<!--[\s\S]*?-->'), '');

/// A self-closing `<receiver ... />` and a `<receiver> ... </receiver>` block
/// need different endings. Accepting `/>` as an ending for both stops at the
/// first `<action ... />` inside the block and cuts the body in half, which
/// made the meta-data look absent on a perfectly good manifest. The first
/// branch cannot cross a `>`, so it only ever matches the self-closing form.
final RegExp _receiverPattern = RegExp(
  r'<receiver\b(?:([^>]*?)/>|([\s\S]*?)</receiver>)',
  multiLine: true,
);

/// Matches the receivers this plugin ships. Someone else's receiver in the same
/// manifest is not ours to have an opinion about.
final RegExp _glanceReceiverName = RegExp(
  r'''android:name\s*=\s*["']((?:dev\.glance\.widget\.android\.templates\.)?(\w+WidgetReceiver))["']''',
);

List<_Receiver> _findGlanceReceivers(String source) {
  final receivers = <_Receiver>[];
  for (final match in _receiverPattern.allMatches(source)) {
    final body = match.group(1) ?? match.group(2)!;
    final nameMatch = _glanceReceiverName.firstMatch(body);
    if (nameMatch == null) continue;
    if (!nameMatch
        .group(1)!
        .startsWith('dev.glance.widget.android.templates.')) {
      continue;
    }
    receivers.add(_Receiver(simpleName: nameMatch.group(2)!, body: body));
  }
  return receivers;
}

class _Receiver {
  _Receiver({required this.simpleName, required this.body});

  final String simpleName;
  final String body;

  /// `null` when the attribute is absent, which is a different problem from it
  /// being present and false.
  bool? get exported {
    final match = RegExp(
      r'''android:exported\s*=\s*["'](true|false)["']''',
    ).firstMatch(body);
    if (match == null) return null;
    return match.group(1) == 'true';
  }

  bool get hasUpdateFilter =>
      body.contains('android.appwidget.action.APPWIDGET_UPDATE');

  String? get providerResource {
    if (!body.contains('android.appwidget.provider')) return null;
    return RegExp(
      r'''android:resource\s*=\s*["']@xml/(\w+)["']''',
    ).firstMatch(body)?.group(1);
  }
}
