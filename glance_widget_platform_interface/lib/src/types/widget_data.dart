import 'dart:ui';

/// Widget template types.
enum GlanceTemplate {
  /// Simple widget with title, value, and optional subtitle.
  simple,

  /// Progress widget with circular or linear progress indicator.
  progress,

  /// List widget with scrollable items.
  list,

  /// Image widget with title, image, and optional subtitle.
  image,

  /// Chart/graph widget with data points visualization.
  chart,

  /// Calendar/event widget with date and event list.
  calendar,

  /// Gauge/metric widget with radial or dashboard display.
  gauge,
}

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

  /// Optional deep link URI to open when the widget is tapped.
  final String? deepLinkUri;

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
    this.deepLinkUri,
  })  : assert(title.length > 0, 'title cannot be empty'),
        assert(value.length > 0, 'value cannot be empty');

  Map<String, dynamic> toMap() => {
    'title': title,
    'value': value,
    'subtitle': subtitle,
    'subtitleColor': subtitleColor?.toARGB32(),
    'iconName': iconName,
    'iconBase64': iconBase64,
    'deepLinkUri': deepLinkUri,
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

  /// Optional deep link URI to open when the widget is tapped.
  final String? deepLinkUri;

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
    this.deepLinkUri,
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
    'deepLinkUri': deepLinkUri,
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

  /// Optional deep link URI to open when the widget is tapped.
  final String? deepLinkUri;

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
    this.deepLinkUri,
  })  : assert(title.length > 0, 'title cannot be empty'),
        assert(maxItems >= 1 && maxItems <= 20,
            'maxItems must be between 1 and 20');

  Map<String, dynamic> toMap() => {
    'title': title,
    'items': items.map((e) => e.toMap()).toList(),
    'showCheckboxes': showCheckboxes,
    'maxItems': maxItems,
    'deepLinkUri': deepLinkUri,
  };
}

/// Image fit mode for Image Widget.
enum ImageFit {
  /// Scale the image to cover the entire widget area, cropping if needed.
  cover,

  /// Scale the image to fit within the widget area, maintaining aspect ratio.
  contain,

  /// Stretch the image to fill the widget area exactly.
  fill,
}

/// Data model for Image Widget template.
class ImageWidgetData {
  /// The title of the widget.
  final String title;

  /// Optional URL to load the image from.
  final String? imageUrl;

  /// Optional base64 encoded image data.
  final String? imageBase64;

  /// Optional subtitle text.
  final String? subtitle;

  /// How the image should be fitted in the widget.
  final ImageFit fit;

  /// Optional deep link URI to open when the widget is tapped.
  final String? deepLinkUri;

  /// Creates an ImageWidgetData with required title.
  ///
  /// At least one of [imageUrl] or [imageBase64] should be provided.
  ///
  /// Throws [AssertionError] if [title] is empty.
  const ImageWidgetData({
    required this.title,
    this.imageUrl,
    this.imageBase64,
    this.subtitle,
    this.fit = ImageFit.cover,
    this.deepLinkUri,
  }) : assert(title.length > 0, 'title cannot be empty');

  Map<String, dynamic> toMap() => {
    'title': title,
    'imageUrl': imageUrl,
    'imageBase64': imageBase64,
    'subtitle': subtitle,
    'fit': fit.name,
    'deepLinkUri': deepLinkUri,
  };
}

/// Chart type for Chart Widget.
enum ChartType {
  /// Line chart connecting data points.
  line,

  /// Bar chart with vertical bars.
  bar,

  /// Sparkline (minimal line chart without axes).
  sparkline,
}

/// Data model for Chart Widget template.
class ChartWidgetData {
  /// The title of the widget.
  final String title;

  /// Data points to visualize.
  final List<double> dataPoints;

  /// The type of chart to display.
  final ChartType chartType;

  /// Optional color for the chart.
  final Color? color;

  /// Optional subtitle text.
  final String? subtitle;

  /// Optional deep link URI to open when the widget is tapped.
  final String? deepLinkUri;

  /// Creates a ChartWidgetData with required title and data points.
  ///
  /// Throws [AssertionError] if:
  /// - [title] is empty
  /// - [dataPoints] is empty
  const ChartWidgetData({
    required this.title,
    required this.dataPoints,
    this.chartType = ChartType.line,
    this.color,
    this.subtitle,
    this.deepLinkUri,
  })  : assert(title.length > 0, 'title cannot be empty'),
        assert(dataPoints.length > 0, 'dataPoints cannot be empty');

  Map<String, dynamic> toMap() => {
    'title': title,
    'dataPoints': dataPoints,
    'chartType': chartType.name,
    'color': color?.toARGB32(),
    'subtitle': subtitle,
    'deepLinkUri': deepLinkUri,
  };
}

/// Data model for a single calendar event.
class CalendarEvent {
  /// Time string (e.g. "09:00" or "All Day").
  final String time;

  /// Event title.
  final String title;

  /// Optional color for the event indicator.
  final Color? color;

  /// Whether this is an all-day event.
  final bool isAllDay;

  const CalendarEvent({
    required this.time,
    required this.title,
    this.color,
    this.isAllDay = false,
  });

  Map<String, dynamic> toMap() => {
    'time': time,
    'title': title,
    'color': color?.toARGB32(),
    'isAllDay': isAllDay,
  };
}

/// Data model for Calendar Widget template.
class CalendarWidgetData {
  /// The title of the widget (e.g. "Today's Events").
  final String title;

  /// The date to display.
  final DateTime date;

  /// List of events for the date.
  final List<CalendarEvent> events;

  /// Maximum number of events to show (default: 5).
  final int maxEvents;

  /// Optional deep link URI to open when the widget is tapped.
  final String? deepLinkUri;

  /// Creates a CalendarWidgetData with required title, date, and events.
  ///
  /// Throws [AssertionError] if:
  /// - [title] is empty
  /// - [maxEvents] is not between 1 and 10
  const CalendarWidgetData({
    required this.title,
    required this.date,
    required this.events,
    this.maxEvents = 5,
    this.deepLinkUri,
  })  : assert(title.length > 0, 'title cannot be empty'),
        assert(maxEvents >= 1 && maxEvents <= 10,
            'maxEvents must be between 1 and 10');

  Map<String, dynamic> toMap() => {
    'title': title,
    'date': date.toIso8601String(),
    'events': events.map((e) => e.toMap()).toList(),
    'maxEvents': maxEvents,
    'deepLinkUri': deepLinkUri,
  };
}

/// Gauge display type.
enum GaugeType {
  /// Radial/circular gauge.
  radial,

  /// Dashboard-style metric cards.
  dashboard,
}

/// Data model for a single gauge metric.
class GaugeMetric {
  /// Label for the metric.
  final String label;

  /// Current value.
  final double value;

  /// Maximum value for the gauge.
  final double maxValue;

  /// Optional color for the metric.
  final Color? color;

  /// Optional unit string (e.g. "%", "km/h").
  final String? unit;

  /// Creates a GaugeMetric with required label, value, and maxValue.
  ///
  /// Throws [AssertionError] if [maxValue] is <= 0.
  const GaugeMetric({
    required this.label,
    required this.value,
    required this.maxValue,
    this.color,
    this.unit,
  }) : assert(maxValue > 0, 'maxValue must be greater than 0');

  Map<String, dynamic> toMap() => {
    'label': label,
    'value': value,
    'maxValue': maxValue,
    'color': color?.toARGB32(),
    'unit': unit,
  };
}

/// Data model for Gauge Widget template.
class GaugeWidgetData {
  /// The title of the widget.
  final String title;

  /// Metrics to display.
  final List<GaugeMetric> metrics;

  /// The type of gauge display.
  final GaugeType gaugeType;

  /// Optional deep link URI to open when the widget is tapped.
  final String? deepLinkUri;

  /// Creates a GaugeWidgetData with required title and metrics.
  ///
  /// Throws [AssertionError] if:
  /// - [title] is empty
  /// - [metrics] is empty
  const GaugeWidgetData({
    required this.title,
    required this.metrics,
    this.gaugeType = GaugeType.radial,
    this.deepLinkUri,
  })  : assert(title.length > 0, 'title cannot be empty'),
        assert(metrics.length > 0, 'metrics cannot be empty');

  Map<String, dynamic> toMap() => {
    'title': title,
    'metrics': metrics.map((e) => e.toMap()).toList(),
    'gaugeType': gaugeType.name,
    'deepLinkUri': deepLinkUri,
  };
}
