import 'package:flutter_test/flutter_test.dart';

import 'package:glance_widget_example/main.dart';

void main() {
  testWidgets('App renders correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that app title is shown
    expect(find.text('Glance Widget Demo'), findsOneWidget);

    // Verify that the three widget sections are present
    expect(find.text('Simple Widget'), findsOneWidget);
    expect(find.text('Progress Widget'), findsOneWidget);
    expect(find.text('List Widget'), findsOneWidget);

    // Verify that How to Use section is present
    expect(find.text('How to Use'), findsOneWidget);
  });

  testWidgets('Simple widget section has update button', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Update Widget'), findsOneWidget);
  });

  testWidgets('Progress widget section has start button', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Start Download'), findsOneWidget);
  });

  testWidgets('List widget section has sync button', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Sync to Widget'), findsOneWidget);
  });

  testWidgets('Todo items are displayed', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Buy groceries'), findsOneWidget);
    expect(find.text('Call mom'), findsOneWidget);
    expect(find.text('Finish report'), findsOneWidget);
    expect(find.text('Go to gym'), findsOneWidget);
  });
}
