import 'package:flutter/material.dart';
import 'package:glance_widget/glance_widget.dart';

/// Shows every template on both hosts, side by side.
///
/// The point of putting the two next to each other is that they do not match.
/// Scroll through the templates and the differences are the interesting part:
/// the icon that only iOS draws, the gauge that Android reduces to one metric,
/// the calendar header laid out two different ways.
class PreviewPage extends StatefulWidget {
  /// Creates the preview gallery.
  const PreviewPage({super.key});

  @override
  State<PreviewPage> createState() => _PreviewPageState();
}

class _PreviewPageState extends State<PreviewPage> {
  GlanceWidgetSize _size = GlanceWidgetSize.medium;
  bool _dark = true;

  GlanceTheme get _theme => _dark ? GlanceTheme.dark() : GlanceTheme.light();

  static final Map<String, WidgetData> _samples = {
    'Simple': const SimpleWidgetData(
      title: 'Steps',
      value: '8,241',
      subtitle: 'Goal 10,000',
      iconName: 'figure.walk',
    ),
    'Progress (circular)': const ProgressWidgetData(
      title: 'Download',
      progress: 0.68,
      subtitle: '340 MB of 500 MB',
    ),
    'Progress (linear)': const ProgressWidgetData(
      title: 'Download',
      progress: 0.68,
      subtitle: '340 MB of 500 MB',
      progressType: ProgressType.linear,
    ),
    'List': const ListWidgetData(
      title: 'Todo',
      items: [
        GlanceListItem(text: 'Buy groceries', checked: true),
        GlanceListItem(text: 'Call mom', secondaryText: 'before 6pm'),
        GlanceListItem(text: 'Finish report'),
      ],
      showCheckboxes: true,
    ),
    'Image': const ImageWidgetData(
      title: 'Yesterday',
      imageUrl: 'https://example.com/photo.jpg',
      subtitle: 'Kadikoy, Istanbul',
    ),
    'Chart (line)': const ChartWidgetData(
      title: 'Traffic',
      dataPoints: [12, 19, 15, 25, 22, 30, 28],
      subtitle: 'Last 7 days',
    ),
    'Chart (bar)': const ChartWidgetData(
      title: 'Traffic',
      dataPoints: [12, 19, 15, 25, 22, 30, 28],
      chartType: ChartType.bar,
      subtitle: 'Last 7 days',
    ),
    'Chart (sparkline)': const ChartWidgetData(
      title: 'Traffic',
      dataPoints: [12, 19, 15, 25, 22, 30, 28],
      chartType: ChartType.sparkline,
    ),
    'Calendar': CalendarWidgetData(
      title: 'Today',
      date: DateTime(2026, 8, 31),
      events: const [
        CalendarEvent(time: '09:00', title: 'Team Standup'),
        CalendarEvent(time: '11:00', title: 'Design Review'),
        CalendarEvent(time: 'All Day', title: 'Deadline', isAllDay: true),
      ],
    ),
    'Gauge (radial)': const GaugeWidgetData(
      title: 'Server',
      metrics: [
        GaugeMetric(label: 'CPU', value: 45, maxValue: 100, unit: '%'),
        GaugeMetric(label: 'Memory', value: 72, maxValue: 100, unit: '%'),
      ],
    ),
    'Gauge (dashboard)': const GaugeWidgetData(
      title: 'Server',
      metrics: [
        GaugeMetric(label: 'CPU', value: 45, maxValue: 100, unit: '%'),
        GaugeMetric(label: 'Memory', value: 72, maxValue: 100, unit: '%'),
        GaugeMetric(label: 'Disk', value: 58, maxValue: 100, unit: '%'),
        GaugeMetric(label: 'Net', value: 12, maxValue: 100, unit: '%'),
      ],
      gaugeType: GaugeType.dashboard,
    ),
  };

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF12121C),
    appBar: AppBar(
      title: const Text('Preview'),
      backgroundColor: const Color(0xFF1A1A2E),
      elevation: 0,
    ),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: SegmentedButton<GlanceWidgetSize>(
                  segments: [
                    for (final size in GlanceWidgetSize.values)
                      ButtonSegment(value: size, label: Text(size.name)),
                  ],
                  selected: {_size},
                  onSelectionChanged: (selection) =>
                      setState(() => _size = selection.first),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                tooltip: _dark ? 'Dark theme' : 'Light theme',
                icon: Icon(
                  _dark ? Icons.dark_mode : Icons.light_mode,
                  color: Colors.white,
                ),
                onPressed: () => setState(() => _dark = !_dark),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            children: [
              for (final entry in _samples.entries) ...[
                Text(
                  entry.key,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final platform in GlancePlatform.values)
                        Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GlancePreview(
                                data: entry.value,
                                theme: _theme,
                                platform: platform,
                                size: _size,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                platform.name,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}
