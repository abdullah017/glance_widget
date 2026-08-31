import 'dart:convert';

import 'package:glance_widget_platform_interface/src/types/glance_exception.dart';

/// What a Live Activity shows while it is running.
///
/// ## Why this is one fixed shape and not a `Map`
///
/// A widget extension has to name a concrete `ActivityAttributes` type at
/// compile time, and ActivityKit matches a running activity to the
/// presentation that draws it by that type. The plugin can therefore offer
/// exactly one shape. A caller who needs a different one edits the copy of
/// `GlanceLiveActivityWidget.swift` in their own extension -- and then also
/// stops being able to use this class, which is the honest cost.
///
/// The match is by type **name** and by the shape of its state, not by module,
/// which is what lets the plugin own the type at all. That was measured rather
/// than assumed; see `findings-live-activity-module-boundary.md`.
class LiveActivityContent {
  /// Creates the content of a Live Activity.
  ///
  /// Throws [GlanceWidgetValidationException] from [validate] when [title] is
  /// empty, [progress] is outside 0.0-1.0, or the whole thing is too large for
  /// ActivityKit to carry.
  const LiveActivityContent({
    required this.title,
    required this.status,
    this.progress,
    this.stats = const {},
  });

  /// The headline. Its first character is what the Dynamic Island shows when
  /// it is collapsed, so a leading emoji is doing real work there.
  final String title;

  /// The one line that changes as the activity runs -- "12 min away".
  ///
  /// This is what the collapsed Dynamic Island shows on the trailing side, in
  /// very little room. Keep it short enough to survive that.
  final String status;

  /// Optional completion between 0.0 and 1.0. Omitted, no bar is drawn.
  final double? progress;

  /// Extra labelled values, drawn in insertion order.
  ///
  /// A `Map` literal in Dart keeps the order it was written in, and the
  /// platform channel carries these as an ordered list of pairs, so what is
  /// written first is drawn first. They appear only in the expanded
  /// presentations -- the Lock Screen and the expanded Dynamic Island.
  final Map<String, String> stats;

  /// ActivityKit's limit on a single activity's dynamic content.
  ///
  /// Apple documents 4KB. Exceeding it makes `request` or `update` throw on the
  /// native side, which reaches Dart as a platform error naming nothing
  /// useful, so the check happens here where the offending field is known.
  static const int maxEncodedBytes = 4096;

  /// Checks the invariants that must hold before this crosses to ActivityKit,
  /// throwing [GlanceWidgetValidationException] when one does not.
  void validate() {
    if (title.isEmpty) {
      throw const GlanceWidgetValidationException(
        'title cannot be empty',
        field: 'title',
        invalidValue: '',
      );
    }
    if (status.isEmpty) {
      throw const GlanceWidgetValidationException(
        'status cannot be empty',
        field: 'status',
        invalidValue: '',
      );
    }
    final progress = this.progress;
    if (progress != null &&
        (progress.isNaN || progress < 0.0 || progress > 1.0)) {
      throw GlanceWidgetValidationException(
        'progress must be between 0.0 and 1.0',
        field: 'progress',
        invalidValue: progress,
      );
    }
    for (final entry in stats.entries) {
      if (entry.key.isEmpty) {
        throw const GlanceWidgetValidationException(
          'a stat label cannot be empty',
          field: 'stats',
          invalidValue: '',
        );
      }
    }
    final bytes = utf8.encode(jsonEncode(toMap())).length;
    if (bytes > maxEncodedBytes) {
      throw GlanceWidgetValidationException(
        'content is $bytes bytes, over the $maxEncodedBytes ActivityKit allows',
        field: 'content',
        invalidValue: bytes,
      );
    }
  }

  /// Serializes this content for platform channel communication.
  Map<String, dynamic> toMap() => <String, dynamic>{
    'title': title,
    'status': status,
    if (progress != null) 'progress': progress,
    'stats': <Map<String, String>>[
      for (final entry in stats.entries)
        <String, String>{'label': entry.key, 'value': entry.value},
    ],
  };

  @override
  String toString() =>
      'LiveActivityContent(title: $title, status: $status, '
      'progress: $progress, stats: $stats)';
}

/// How a Live Activity leaves the screen when it ends.
enum LiveActivityDismissal {
  /// Disappears at once.
  immediate,

  /// Stays visible for up to four hours, the way a finished delivery does, so
  /// the final state can be read. The system may remove it sooner.
  ///
  /// This is ActivityKit's own default and the reason `endLiveActivity` is not
  /// the same thing as the activity vanishing.
  standard;

  /// The wire value the native side switches on.
  String get wireName => name;
}
