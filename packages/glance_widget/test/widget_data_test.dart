import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:glance_widget/glance_widget.dart';

void main() {
  group('WidgetData sealed hierarchy', () {
    test('SimpleWidgetData rejects empty title', () {
      expect(
        () => SimpleWidgetData(title: '', value: 'x'),
        throwsA(isA<AssertionError>()),
      );
    });

    test('SimpleWidgetData rejects empty value', () {
      expect(
        () => SimpleWidgetData(title: 'x', value: ''),
        throwsA(isA<AssertionError>()),
      );
    });

    test('ProgressWidgetData rejects out-of-range progress', () {
      expect(
        () => ProgressWidgetData(title: 'x', progress: -0.1),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => ProgressWidgetData(title: 'x', progress: 1.1),
        throwsA(isA<AssertionError>()),
      );
    });

    test('each subclass returns correct template', () {
      expect(
        const SimpleWidgetData(title: 't', value: 'v').template,
        GlanceTemplate.simple,
      );
      expect(
        const ProgressWidgetData(title: 't', progress: 0.5).template,
        GlanceTemplate.progress,
      );
      expect(
        const ListWidgetData(title: 't', items: []).template,
        GlanceTemplate.list,
      );
      expect(const ImageWidgetData(title: 't').template, GlanceTemplate.image);
      expect(
        const ChartWidgetData(title: 't', dataPoints: [1.0]).template,
        GlanceTemplate.chart,
      );
      expect(
        CalendarWidgetData(
          title: 't',
          date: DateTime(2026),
          events: [],
        ).template,
        GlanceTemplate.calendar,
      );
      expect(
        const GaugeWidgetData(
          title: 't',
          metrics: [GaugeMetric(label: 'x', value: 1, maxValue: 10)],
        ).template,
        GlanceTemplate.gauge,
      );
    });

    test('SimpleWidgetData toMap serializes all fields', () {
      const data = SimpleWidgetData(
        title: 'BTC',
        value: '\$94k',
        subtitle: 'Price',
        subtitleColor: Color(0xFF00FF00),
        iconName: 'bitcoin',
        deepLinkUri: 'myapp://crypto',
      );
      final map = data.toMap();
      expect(map['title'], 'BTC');
      expect(map['value'], '\$94k');
      expect(map['subtitle'], 'Price');
      expect(map['subtitleColor'], const Color(0xFF00FF00).toARGB32());
      expect(map['iconName'], 'bitcoin');
      expect(map['deepLinkUri'], 'myapp://crypto');
    });

    test('exhaustive switch on WidgetData covers all types', () {
      final List<WidgetData> allTypes = [
        const SimpleWidgetData(title: 't', value: 'v'),
        const ProgressWidgetData(title: 't', progress: 0.5),
        const ListWidgetData(title: 't', items: []),
        const ImageWidgetData(title: 't'),
        const ChartWidgetData(title: 't', dataPoints: [1.0]),
        CalendarWidgetData(title: 't', date: DateTime(2026), events: []),
        const GaugeWidgetData(
          title: 't',
          metrics: [GaugeMetric(label: 'x', value: 1, maxValue: 10)],
        ),
      ];
      for (final data in allTypes) {
        final name = switch (data) {
          SimpleWidgetData() => 'simple',
          ProgressWidgetData() => 'progress',
          ListWidgetData() => 'list',
          ImageWidgetData() => 'image',
          ChartWidgetData() => 'chart',
          CalendarWidgetData() => 'calendar',
          GaugeWidgetData() => 'gauge',
        };
        expect(name, isNotEmpty);
        expect(data.toMap(), isA<Map<String, dynamic>>());
      }
    });
  });
}
