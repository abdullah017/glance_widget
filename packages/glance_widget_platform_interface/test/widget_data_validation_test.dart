import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glance_widget_platform_interface/glance_widget_platform_interface.dart';

const MethodChannel _channel = MethodChannel('dev.glance.widget/methods');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MethodChannelGlanceWidget platform;
  late List<MethodCall> log;

  setUp(() {
    platform = MethodChannelGlanceWidget();
    log = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (MethodCall call) async {
          log.add(call);
          return true;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
  });

  group('const-ability', () {
    // These two classes silently lost `const` to a `List.length` assert, which
    // the analyzer reports as `const_eval_property_access` at the call site
    // rather than at the constructor. That the literals below compile is the
    // assertion.
    test('ChartWidgetData is a const constructor', () {
      const a = ChartWidgetData(title: 'T', dataPoints: [1, 2, 3]);
      const b = ChartWidgetData(title: 'T', dataPoints: [1, 2, 3]);
      expect(identical(a, b), isTrue, reason: 'canonicalised, so truly const');
    });

    test('GaugeWidgetData is a const constructor', () {
      const a = GaugeWidgetData(
        title: 'T',
        metrics: [GaugeMetric(label: 'L', value: 1, maxValue: 2)],
      );
      const b = GaugeWidgetData(
        title: 'T',
        metrics: [GaugeMetric(label: 'L', value: 1, maxValue: 2)],
      );
      expect(identical(a, b), isTrue, reason: 'canonicalised, so truly const');
    });
  });

  group('validation at the channel boundary', () {
    /// Data built the way a server response would build it: not a literal, so
    /// no compile-time const evaluation can catch anything here.
    List<double> emptyFromRuntime() => <double>[];

    /// Same, for the gauge template.
    List<GaugeMetric> noMetrics() => <GaugeMetric>[];

    test('an empty chart is refused before the channel is touched', () async {
      await expectLater(
        platform.updateChartWidget(
          widgetId: 'w',
          data: ChartWidgetData(title: 'T', dataPoints: emptyFromRuntime()),
        ),
        throwsA(
          isA<GlanceWidgetValidationException>()
              .having((e) => e.field, 'field', 'dataPoints'),
        ),
      );
      expect(log, isEmpty);
    });

    test('an empty gauge is refused before the channel is touched', () async {
      await expectLater(
        platform.updateGaugeWidget(
          widgetId: 'w',
          data: GaugeWidgetData(title: 'T', metrics: noMetrics()),
        ),
        throwsA(
          isA<GlanceWidgetValidationException>()
              .having((e) => e.field, 'field', 'metrics'),
        ),
      );
      expect(log, isEmpty);
    });

    test('an empty widget id is refused', () async {
      await expectLater(
        platform.updateSimpleWidget(
          widgetId: '',
          data: const SimpleWidgetData(title: 'T', value: 'V'),
        ),
        throwsA(
          isA<GlanceWidgetValidationException>()
              .having((e) => e.field, 'field', 'widgetId'),
        ),
      );
      expect(log, isEmpty);
    });

    test('a synchronous rejection still arrives as a failed future', () async {
      // `catchError` only sees a rejection the future carries. If validation
      // threw before the future existed, this would escape uncaught.
      Object? caught;
      await platform
          .updateChartWidget(
            widgetId: 'w',
            data: ChartWidgetData(title: 'T', dataPoints: emptyFromRuntime()),
          )
          .catchError((Object e) => caught = e);

      expect(caught, isA<GlanceWidgetValidationException>());
    });

    test('valid data reaches the channel unchanged', () async {
      await platform.updateChartWidget(
        widgetId: 'w',
        data: const ChartWidgetData(title: 'T', dataPoints: [1, 2, 3]),
      );

      expect(log, hasLength(1));
      expect(log.single.method, 'updateChartWidget');
    });
  });
}
