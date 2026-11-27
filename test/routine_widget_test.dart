import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smogshield_ai/features/routine/routine_screen.dart';

void main() {
  Widget buildTestableWidget() {
    return const ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: RoutineScreen(),
        ),
      ),
    );
  }

  testWidgets('Routine screen renders demonstration badge, progress counter, and explanatory cards', (tester) async {
    tester.view.physicalSize = const Size(1280, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildTestableWidget());
    await tester.pumpAndSettle();

    // Verify title and demo badge
    expect(find.text('Daily Routine'), findsOneWidget);
    expect(find.text('DEMO ROUTINE • NOT PERSONALIZED'), findsOneWidget);
    expect(find.textContaining('Completed: 0 / 5'), findsOneWidget);

    // Verify Explanatory cards feature Time, Action, and "Why it matters"
    expect(find.text('7:00 AM'), findsOneWidget);
    expect(find.text('Exercise indoors'), findsOneWidget);
    expect(find.textContaining('Why it matters:'), findsWidgets);
    expect(find.textContaining('increases pulmonary particle deposition by up to 400%'), findsOneWidget);

    expect(find.text('8:30 AM'), findsOneWidget);
    expect(find.text('Protected low-emission commute'), findsOneWidget);
    expect(find.textContaining('concentrated vehicular exhaust'), findsOneWidget);

    expect(find.text('1:00 PM'), findsOneWidget);
    expect(find.text('Midday indoor air check & hygiene'), findsOneWidget);

    expect(find.text('Diurnal Inversion Shielding Cycle'), findsOneWidget);
    expect(find.textContaining('Safety Disclaimer: Routine recommendations are generalized'), findsOneWidget);
  });

  testWidgets('Filter chips filter routine cards by time period', (tester) async {
    tester.view.physicalSize = const Size(1280, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildTestableWidget());
    await tester.pumpAndSettle();

    // Tap Afternoon filter
    final afternoonChip = find.widgetWithText(FilterChip, 'Afternoon');
    await tester.tap(afternoonChip);
    await tester.pumpAndSettle();

    // Afternoon item visible, Morning item filtered out
    expect(find.text('Midday indoor air check & hygiene'), findsOneWidget);
    expect(find.text('Exercise indoors'), findsNothing);

    // Tap All to restore
    final allChip = find.widgetWithText(FilterChip, 'All');
    await tester.tap(allChip);
    await tester.pumpAndSettle();

    expect(find.text('Exercise indoors'), findsOneWidget);
    expect(find.text('Midday indoor air check & hygiene'), findsOneWidget);
  });

  testWidgets('Checking a routine item marks it complete and updates completion progress', (tester) async {
    tester.view.physicalSize = const Size(1280, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildTestableWidget());
    await tester.pumpAndSettle();

    expect(find.textContaining('Completed: 0 / 5'), findsOneWidget);

    // Tap the first checkbox
    final firstCheckbox = find.byType(Checkbox).first;
    await tester.tap(firstCheckbox);
    await tester.pumpAndSettle();

    expect(find.textContaining('Completed: 1 / 5'), findsOneWidget);

    // Tap it again to uncheck
    await tester.tap(firstCheckbox);
    await tester.pumpAndSettle();

    expect(find.textContaining('Completed: 0 / 5'), findsOneWidget);
  });
}
