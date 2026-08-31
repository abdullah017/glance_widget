import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glance_widget/glance_widget.dart';

/// The preview exists to tell the truth about two hosts that draw differently.
/// These tests pin the differences that matter -- if a renderer ever quietly
/// starts averaging the two, one of them fails.
void main() {
  const simple = SimpleWidgetData(
    title: 'Steps',
    value: '8,241',
    subtitle: 'Today',
    iconName: 'figure.walk',
  );

  Future<void> show(
    WidgetTester tester,
    Widget preview, {
    Brightness brightness = Brightness.light,
  }) => tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(platformBrightness: brightness),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Center(child: preview),
      ),
    ),
  );

  group('size', () {
    test('the two hosts do not use the same slot sizes', () {
      // iOS families are fixed point sizes; Android cells are launcher grid
      // cells. Treating them as one number would make every preview wrong on
      // one of the two.
      expect(
        GlanceWidgetSize.medium.logicalSize(GlancePlatform.ios),
        isNot(GlanceWidgetSize.medium.logicalSize(GlancePlatform.android)),
      );
    });

    testWidgets('the preview is laid out at the slot size', (tester) async {
      await show(
        tester,
        const GlancePreview(
          data: simple,
          platform: GlancePlatform.ios,
          size: GlanceWidgetSize.small,
        ),
      );

      expect(tester.getSize(find.byType(GlancePreview)), const Size(155, 155));
    });
  });

  group('platform selection', () {
    test('current follows the running platform', () {
      // Not a widget test: flutter_test asserts that no foundation debug
      // variable is still set when the test body ends, and the override has to
      // be cleared before that check rather than in a tear-down.
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      expect(GlancePlatform.current, GlancePlatform.ios);

      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      expect(GlancePlatform.current, GlancePlatform.android);

      // A desktop or web session has no home screen widgets at all. Throwing
      // there would make the preview unusable in exactly the place a developer
      // is most likely to open it.
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      expect(GlancePlatform.current, GlancePlatform.android);

      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('an unset platform draws the running one', (tester) async {
      await show(tester, const GlancePreview(data: simple));

      // flutter_test reports itself as Android, whose medium slot is 320 wide;
      // the iOS one is 329.
      expect(tester.getSize(find.byType(GlancePreview)).width, 320);
    });
  });

  group('simple', () {
    testWidgets('Android does not draw an icon, because its template cannot', (
      tester,
    ) async {
      await show(
        tester,
        const GlancePreview(data: simple, platform: GlancePlatform.android),
      );

      // Every drawn shape in the Android simple template is text; an icon
      // would be the only CustomPaint in the tree.
      expect(find.byType(CustomPaint), findsNothing);
      expect(find.text('Steps'), findsOneWidget);
      expect(find.text('8,241'), findsOneWidget);
    });

    testWidgets('iOS draws the icon its template renders', (tester) async {
      await show(
        tester,
        const GlancePreview(data: simple, platform: GlancePlatform.ios),
      );

      expect(find.text('Steps'), findsOneWidget);
      // The SF Symbol stand-in is a decorated box, not text.
      expect(
        find.byWidgetPredicate(
          (widget) => widget is Container && widget.decoration is BoxDecoration,
        ),
        findsWidgets,
      );
    });

    testWidgets('a subtitle colour overrides the theme on both hosts', (
      tester,
    ) async {
      const red = Color(0xFFFF0000);
      for (final platform in GlancePlatform.values) {
        await show(
          tester,
          GlancePreview(
            data: const SimpleWidgetData(
              title: 'T',
              value: 'V',
              subtitle: 'S',
              subtitleColor: red,
            ),
            platform: platform,
          ),
        );

        final subtitle = tester.widget<Text>(find.text('S'));
        expect(subtitle.style?.color, red, reason: platform.name);
      }
    });
  });

  group('gauge', () {
    const metrics = [
      GaugeMetric(label: 'CPU', value: 42, maxValue: 100, unit: '%'),
      GaugeMetric(label: 'RAM', value: 3, maxValue: 8, unit: ' GB'),
      GaugeMetric(label: 'Disk', value: 120, maxValue: 500),
    ];
    const gauge = GaugeWidgetData(title: 'Server', metrics: metrics);

    testWidgets('iOS draws one radial gauge per metric', (tester) async {
      await show(
        tester,
        const GlancePreview(
          data: gauge,
          platform: GlancePlatform.ios,
          size: GlanceWidgetSize.large,
        ),
      );

      for (final metric in metrics) {
        expect(find.text(metric.label), findsOneWidget);
      }
    });

    testWidgets('Android draws only the first, as its bitmap holds one arc', (
      tester,
    ) async {
      await show(
        tester,
        const GlancePreview(
          data: gauge,
          platform: GlancePlatform.android,
          size: GlanceWidgetSize.large,
        ),
      );

      // The value of the first metric, with its unit, is the only reading the
      // rasterised gauge carries.
      expect(find.text('42%'), findsOneWidget);
      expect(find.text('3 GB'), findsNothing);
    });

    testWidgets('a whole number loses its decimal point', (tester) async {
      await show(
        tester,
        const GlancePreview(
          data: GaugeWidgetData(
            title: 'Server',
            metrics: [GaugeMetric(label: 'CPU', value: 42.5, maxValue: 100)],
          ),
          platform: GlancePlatform.ios,
        ),
      );

      expect(find.text('42.5'), findsOneWidget);
    });
  });

  group('theme', () {
    testWidgets('Android falls back to dark, as its templates do', (
      tester,
    ) async {
      await show(
        tester,
        const GlancePreview(data: simple, platform: GlancePlatform.android),
        brightness: Brightness.light,
      );

      final background = tester.widget<ColoredBox>(
        find
            .descendant(
              of: find.byType(GlancePreview),
              matching: find.byType(ColoredBox),
            )
            .first,
      );
      expect(background.color, GlanceTheme.dark().backgroundColor);
    });

    testWidgets('iOS follows the device brightness, as its templates do', (
      tester,
    ) async {
      await show(
        tester,
        const GlancePreview(data: simple, platform: GlancePlatform.ios),
        brightness: Brightness.light,
      );

      final background = tester.widget<ColoredBox>(
        find
            .descendant(
              of: find.byType(GlancePreview),
              matching: find.byType(ColoredBox),
            )
            .first,
      );
      expect(background.color, GlanceTheme.light().backgroundColor);
    });

    testWidgets('both hosts honour borderRadius on a current OS', (
      tester,
    ) async {
      // Android used to be pinned at 16 here on the grounds that its templates
      // read the value and never used it. #24 gave all seven of them
      // `.cornerRadius(...)`, so the preview would now be the one lying. See
      // preview_corner_radius_test.dart for the API-level split.
      const theme = GlanceTheme(
        backgroundColor: Color(0xFF000000),
        textColor: Color(0xFFFFFFFF),
        borderRadius: 40,
      );

      for (final platform in GlancePlatform.values) {
        await show(
          tester,
          GlancePreview(data: simple, theme: theme, platform: platform),
        );

        final clip = tester.widget<ClipRRect>(
          find
              .descendant(
                of: find.byType(GlancePreview),
                matching: find.byType(ClipRRect),
              )
              .first,
        );

        expect(
          clip.borderRadius,
          BorderRadius.circular(40),
          reason: platform.name,
        );
      }
    });
  });

  group('list', () {
    const items = [
      GlanceListItem(text: 'One', checked: true),
      GlanceListItem(text: 'Two'),
      GlanceListItem(text: 'Three'),
      GlanceListItem(text: 'Four'),
      GlanceListItem(text: 'Five'),
    ];

    testWidgets('iOS caps rows per family; a small widget shows three', (
      tester,
    ) async {
      await show(
        tester,
        const GlancePreview(
          data: ListWidgetData(title: 'Todo', items: items),
          platform: GlancePlatform.ios,
          size: GlanceWidgetSize.small,
        ),
      );

      expect(find.text('Three'), findsOneWidget);
      expect(find.text('Four'), findsNothing);
      // The header count is of every item, not of the ones drawn.
      expect(find.text('5'), findsOneWidget);
    });
  });

  group('calendar', () {
    testWidgets('an all-day event says so on iOS', (tester) async {
      await show(
        tester,
        GlancePreview(
          data: CalendarWidgetData(
            title: 'Today',
            date: DateTime(2026, 8, 31),
            events: const [
              CalendarEvent(time: '09:00', title: 'Standup', isAllDay: true),
            ],
          ),
          platform: GlancePlatform.ios,
        ),
      );

      expect(find.text('All day'), findsOneWidget);
      expect(find.text('09:00'), findsNothing);
    });

    testWidgets('Android shows the time regardless, as its template does', (
      tester,
    ) async {
      await show(
        tester,
        GlancePreview(
          data: CalendarWidgetData(
            title: 'Today',
            date: DateTime(2026, 8, 31),
            events: const [
              CalendarEvent(time: '09:00', title: 'Standup', isAllDay: true),
            ],
          ),
          platform: GlancePlatform.android,
        ),
      );

      expect(find.text('09:00'), findsOneWidget);
      expect(find.text('All day'), findsNothing);
    });
  });

  group('empty states', () {
    testWidgets('each host writes the message its own template writes', (
      tester,
    ) async {
      const empty = ChartWidgetData(title: 'Traffic', dataPoints: []);

      await show(
        tester,
        const GlancePreview(data: empty, platform: GlancePlatform.android),
      );
      expect(find.text('No chart data'), findsOneWidget);

      await show(
        tester,
        const GlancePreview(data: empty, platform: GlancePlatform.ios),
      );
      expect(find.text('No data'), findsOneWidget);
    });
  });
}
