/// How much a finding matters.
enum DoctorSeverity {
  /// The widget will not work. Something is missing or contradictory.
  error,

  /// Works, but something is untidy or probably not what was meant.
  warning,
}

/// One thing the doctor noticed about a project's native setup.
class DoctorFinding {
  /// Creates a finding.
  const DoctorFinding({
    required this.severity,
    required this.title,
    required this.detail,
  });

  /// How much this matters.
  final DoctorSeverity severity;

  /// One line naming what is wrong.
  final String title;

  /// What to do about it, and what the symptom looks like if it is left.
  final String detail;

  @override
  String toString() => '${severity.name}: $title\n$detail';
}
