@Tags(['golden'])
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glance_widget/glance_widget.dart';

/// Pixel-for-pixel records of what each template looks like on each host.
///
/// The behaviour tests next door check the decisions -- which fields a template
/// drops, how many gauges it draws, what it writes when it has nothing. These
/// catch what those cannot: a spacing that quietly doubled, a colour applied to
/// the wrong run of text, a bar that stopped filling.
///
/// They are tagged `golden` and run on macOS in CI. Flutter renders the same
/// tree slightly differently on different host platforms, so a single set of
/// reference images can only be compared against on the platform that produced
/// them. Excluding them from the Linux run and giving them a job of their own
/// keeps the images meaningful instead of turning them into noise that gets
/// regenerated whenever they are inconvenient.
///
/// Regenerate with:
///
/// ```sh
/// (cd packages/glance_widget && flutter test --tags golden --update-goldens)
/// ```
void main() {
  const theme = GlanceTheme(
    backgroundColor: Color(0xFF1A1A2E),
    textColor: Color(0xFFFFFFFF),
    secondaryTextColor: Color(0xFFB0B0B0),
    accentColor: Color(0xFF2196F3),
    isDark: true,
  );

  final samples = <String, WidgetData>{
    'simple': const SimpleWidgetData(
      title: 'Steps',
      value: '8,241',
      subtitle: 'Goal 10,000',
      iconName: 'figure.walk',
    ),
    'progress_circular': const ProgressWidgetData(
      title: 'Download',
      progress: 0.68,
      subtitle: '340 MB of 500 MB',
    ),
    'progress_linear': const ProgressWidgetData(
      title: 'Download',
      progress: 0.68,
      subtitle: '340 MB of 500 MB',
      progressType: ProgressType.linear,
    ),
    'list': const ListWidgetData(
      title: 'Todo',
      items: [
        GlanceListItem(text: 'Ship the preview', checked: true),
        GlanceListItem(text: 'Write the goldens', secondaryText: 'in progress'),
        GlanceListItem(text: 'Open the PR'),
      ],
      showCheckboxes: true,
    ),
    'image': const ImageWidgetData(
      title: 'Yesterday',
      imageUrl: 'https://example.com/photo.jpg',
      subtitle: 'Kadikoy, Istanbul',
    ),
    'chart_line': const ChartWidgetData(
      title: 'Traffic',
      dataPoints: [4, 9, 6, 12, 8, 15, 11],
      subtitle: 'Last 7 days',
    ),
    'chart_bar': const ChartWidgetData(
      title: 'Traffic',
      dataPoints: [4, 9, 6, 12, 8, 15, 11],
      chartType: ChartType.bar,
      subtitle: 'Last 7 days',
    ),
    'chart_sparkline': const ChartWidgetData(
      title: 'Traffic',
      dataPoints: [4, 9, 6, 12, 8, 15, 11],
      chartType: ChartType.sparkline,
    ),
    'calendar': CalendarWidgetData(
      title: 'Today',
      date: DateTime(2026, 8, 31),
      events: const [
        CalendarEvent(time: '09:30', title: 'Standup'),
        CalendarEvent(time: '13:00', title: 'Review', isAllDay: true),
      ],
    ),
    'gauge_radial': const GaugeWidgetData(
      title: 'Server',
      metrics: [
        GaugeMetric(label: 'CPU', value: 42, maxValue: 100, unit: '%'),
        GaugeMetric(label: 'RAM', value: 3, maxValue: 8, unit: ' GB'),
      ],
    ),
    'gauge_dashboard': const GaugeWidgetData(
      title: 'Server',
      metrics: [
        GaugeMetric(label: 'CPU', value: 42, maxValue: 100, unit: '%'),
        GaugeMetric(label: 'RAM', value: 3, maxValue: 8, unit: ' GB'),
        GaugeMetric(label: 'Disk', value: 120, maxValue: 500),
        GaugeMetric(label: 'Net', value: 88, maxValue: 100, unit: '%'),
      ],
      gaugeType: GaugeType.dashboard,
    ),
  };

  for (final platform in GlancePlatform.values) {
    group(platform.name, () {
      for (final entry in samples.entries) {
        testWidgets('${entry.key} at every size', (tester) async {
          for (final size in GlanceWidgetSize.values) {
            await tester.pumpWidget(
              Directionality(
                textDirection: TextDirection.ltr,
                child: Center(
                  child: RepaintBoundary(
                    child: GlancePreview(
                      data: entry.value,
                      theme: theme,
                      platform: platform,
                      size: size,
                    ),
                  ),
                ),
              ),
            );

            await expectLater(
              find.byType(GlancePreview),
              matchesGoldenFile(
                'goldens/${platform.name}_${entry.key}_${size.name}.png',
              ),
            );
          }
        });
      }
    });
  }
}
