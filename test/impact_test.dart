import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smogshield_ai/core/data/mock_repository.dart';

void main() {
  group('Impact Notifier Tests', () {
    test('Default impact actions have zero logged savings initially', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(impactProvider.notifier);
      expect(notifier.totalSavings, equals(0.0));
      expect(notifier.loggedCount, equals(0));
    });

    test('Logging an action calculates accurate CO2e savings and increments count', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final actions = container.read(impactProvider);
      final metroAction = actions.firstWhere((a) => a.id == 'metro_transit');

      container.read(impactProvider.notifier).toggleAction('metro_transit');
      expect(container.read(impactProvider.notifier).loggedCount, equals(1));
      expect(container.read(impactProvider.notifier).totalSavings, closeTo(metroAction.co2eSavingsKg, 0.01));

      // Toggle off
      container.read(impactProvider.notifier).toggleAction('metro_transit');
      expect(container.read(impactProvider.notifier).loggedCount, equals(0));
      expect(container.read(impactProvider.notifier).totalSavings, equals(0.0));
    });

    test('Impact actions carry explicit calculations, assumptions, and exposure notes', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      for (final a in container.read(impactProvider)) {
        expect(a.calculationFormula, isNotEmpty);
        expect(a.assumptions, isNotEmpty);
        expect(a.exposureNote, isNotEmpty);
      }
    });
  });
}
