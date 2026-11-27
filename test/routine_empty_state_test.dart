import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smogshield_ai/core/data/mock_repository.dart';
import 'package:smogshield_ai/features/routine/routine_screen.dart';

class _EmptyRoutineNotifier extends RoutineNotifier {
  @override
  List<RoutineItem> build() => const [];
}

void main() {
  testWidgets('Empty routine state does not imply a personalized schedule',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          routineProvider.overrideWith(_EmptyRoutineNotifier.new),
        ],
        child: const MaterialApp(
          home: Scaffold(body: RoutineScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No routine steps are available yet'), findsOneWidget);
    expect(
      find.text(
        'No personalized schedule is shown until routine data is available.',
      ),
      findsOneWidget,
    );
    expect(find.byType(Checkbox), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
