import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glance_widget_example/main.dart';

/// Taps the tab labelled [label] and settles the resulting animation.
Future<void> openTab(WidgetTester tester, String label) async {
  await tester.tap(find.widgetWithText(Tab, label));
  await tester.pumpAndSettle();
}

void main() {
  group('shell', () {
    testWidgets('renders the app bar and every tab', (tester) async {
      await tester.pumpWidget(const MyApp());

      expect(find.widgetWithText(AppBar, 'Glance Widget Demo'), findsOneWidget);
      for (final label in const [
        'Widgets',
        'Charts & Data',
        'Platform',
        'Info',
      ]) {
        expect(
          find.widgetWithText(Tab, label),
          findsOneWidget,
          reason: 'tab "$label" should exist',
        );
      }
    });

    testWidgets('opens on the Widgets tab', (tester) async {
      await tester.pumpWidget(const MyApp());

      expect(find.text('Simple Widget'), findsOneWidget);
      // A section from another tab must not be mounted yet.
      expect(find.text('Chart Widget'), findsNothing);
    });
  });

  group('Widgets tab', () {
    testWidgets('shows all four widget sections', (tester) async {
      await tester.pumpWidget(const MyApp());

      for (final section in const [
        'Simple Widget',
        'Progress Widget',
        'List Widget',
        'Image Widget',
      ]) {
        expect(
          find.text(section),
          findsOneWidget,
          reason: '"$section" section should be on the Widgets tab',
        );
      }
    });

    testWidgets('every section exposes its action button', (tester) async {
      await tester.pumpWidget(const MyApp());

      // 'Update' is shared by the Simple section here and by other tabs'
      // sections, so scope the assertion to at least one on this tab.
      expect(find.widgetWithText(ElevatedButton, 'Update'), findsWidgets);
      expect(
        find.widgetWithText(ElevatedButton, 'Start Download'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(ElevatedButton, 'Sync to Widget'),
        findsOneWidget,
      );
    });

    testWidgets('renders the seeded todo items', (tester) async {
      await tester.pumpWidget(const MyApp());

      for (final todo in const [
        'Buy groceries',
        'Call mom',
        'Finish report',
        'Go to gym',
      ]) {
        expect(find.text(todo), findsOneWidget, reason: 'todo "$todo"');
      }
    });

    testWidgets('Start Download is disabled while a download runs', (
      tester,
    ) async {
      await tester.pumpWidget(const MyApp());

      final button = find.widgetWithText(ElevatedButton, 'Start Download');
      expect(
        tester.widget<ElevatedButton>(button).onPressed,
        isNotNull,
        reason: 'enabled before the download starts',
      );

      // The Widgets tab scrolls; the Progress section sits below the fold and
      // an off-screen tap would not be delivered.
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();

      await tester.tap(button);
      // The guard is `progress > 0 && progress < 1`, and the tap only seeds
      // progress at 0.0 — it takes the first timer tick to cross above zero.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      expect(
        tester.widget<ElevatedButton>(button).onPressed,
        isNull,
        reason: 'disabled while progress is between 0 and 1',
      );

      // Let the periodic timer finish so the test does not leak it.
      await tester.pump(const Duration(seconds: 6));
    });
  });

  group('other tabs', () {
    testWidgets('Charts & Data tab shows chart and calendar sections', (
      tester,
    ) async {
      await tester.pumpWidget(const MyApp());
      await openTab(tester, 'Charts & Data');

      expect(find.text('Chart Widget'), findsOneWidget);
      expect(find.text('Calendar Widget'), findsOneWidget);
    });

    testWidgets('Platform tab shows the platform-independent sections', (
      tester,
    ) async {
      await tester.pumpWidget(const MyApp());
      await openTab(tester, 'Platform');

      // The Background Updates / Timeline Refresh / Lock Screen sections are
      // gated on `dart:io` Platform.isAndroid|isIOS, so under a host-machine
      // widget test only the ungated sections are mounted.
      expect(find.text('Deep Links'), findsOneWidget);
      expect(find.text('Widget Actions'), findsOneWidget);
    });

    testWidgets('Info tab shows the How to Use section', (tester) async {
      await tester.pumpWidget(const MyApp());
      await openTab(tester, 'Info');

      expect(find.text('How to Use'), findsOneWidget);
    });
  });
}
