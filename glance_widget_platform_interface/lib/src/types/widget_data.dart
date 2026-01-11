import 'dart:ui';

/// Data model for Simple Widget template.
class SimpleWidgetData {
  /// The main title of the widget.
  final String title;

  /// The primary value to display (large text).
  final String value;

  /// Optional subtitle text (smaller, below value).
  final String? subtitle;

  /// Optional color for the subtitle text.
  final Color? subtitleColor;

  /// Optional icon name (predefined icons like 'bitcoin', 'ethereum', etc.)
  final String? iconName;

  /// Optional custom icon as base64 encoded image.
  final String? iconBase64;

  /// Creates a SimpleWidgetData with required title and value.
  ///
  /// Throws [AssertionError] if:
  /// - [title] is empty
  /// - [value] is empty
  const SimpleWidgetData({
    required this.title,
    required this.value,
    this.subtitle,
    this.subtitleColor,
    this.iconName,
    this.iconBase64,
  })  : assert(title.length > 0, 'title cannot be empty'),
        assert(value.length > 0, 'value cannot be empty');

  Map<String, dynamic> toMap() => {
    'title': title,
    'value': value,
    'subtitle': subtitle,
    'subtitleColor': subtitleColor?.toARGB32(),
    'iconName': iconName,
    'iconBase64': iconBase64,
  };
}

/// Progress type enum for Progress Widget.
enum ProgressType {
  /// Circular progress indicator.
  circular,

  /// Linear/horizontal progress bar.
  linear,
}

/// Data model for Progress Widget template.
class ProgressWidgetData {
  /// The title of the widget.
  final String title;

  /// Progress value between 0.0 and 1.0.
  final double progress;

  /// Optional subtitle text.
  final String? subtitle;

  /// The type of progress indicator.
  final ProgressType progressType;

  /// Optional color for the progress indicator.
  final Color? progressColor;

  /// Optional background color for the progress track.
  final Color? trackColor;

  /// Creates a ProgressWidgetData with required title and progress.
  ///
  /// Throws [AssertionError] if:
  /// - [title] is empty
  /// - [progress] is not between 0.0 and 1.0
  const ProgressWidgetData({
    required this.title,
    required this.progress,
    this.subtitle,
    this.progressType = ProgressType.circular,
    this.progressColor,
    this.trackColor,
  })  : assert(title.length > 0, 'title cannot be empty'),
        assert(progress >= 0.0 && progress <= 1.0,
            'progress must be between 0.0 and 1.0');

  Map<String, dynamic> toMap() => {
    'title': title,
    'progress': progress,
    'subtitle': subtitle,
    'progressType': progressType.name,
    'progressColor': progressColor?.toARGB32(),
    'trackColor': trackColor?.toARGB32(),
  };
}

/// Data model for a single list item.
class GlanceListItem {
  /// The text content of the item.
  final String text;

  /// Whether the item is checked (for checkbox lists).
  final bool checked;

  /// Optional secondary text.
  final String? secondaryText;

  /// Optional icon name.
  final String? iconName;

  const GlanceListItem({
    required this.text,
    this.checked = false,
    this.secondaryText,
    this.iconName,
  });

  Map<String, dynamic> toMap() => {
    'text': text,
    'checked': checked,
    'secondaryText': secondaryText,
    'iconName': iconName,
  };
}

/// Data model for List Widget template.
class ListWidgetData {
  /// The title of the widget.
  final String title;

  /// List of items to display.
  final List<GlanceListItem> items;

  /// Whether to show checkboxes for items.
  final bool showCheckboxes;

  /// Maximum number of items to display (default: 5).
  final int maxItems;

  /// Creates a ListWidgetData with required title and items.
  ///
  /// Throws [AssertionError] if:
  /// - [title] is empty
  /// - [maxItems] is not between 1 and 20
  const ListWidgetData({
    required this.title,
    required this.items,
    this.showCheckboxes = false,
    this.maxItems = 5,
  })  : assert(title.length > 0, 'title cannot be empty'),
        assert(maxItems >= 1 && maxItems <= 20,
            'maxItems must be between 1 and 20');

  Map<String, dynamic> toMap() => {
    'title': title,
    'items': items.map((e) => e.toMap()).toList(),
    'showCheckboxes': showCheckboxes,
    'maxItems': maxItems,
  };
}
