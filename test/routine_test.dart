import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smogshield_ai/core/data/mock_repository.dart';

void main() {
  group('Routine Notifier & Data Tests', () {
    test('Initial routine has morning, afternoon and evening plans', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final items = container.read(routineProvider);
      expect(items.length, greaterThanOrEqualTo(4));
      expect(items.any((item) => item.timePeriod == 'Morning'), isTrue);
      expect(items.any((item) => item.timePeriod == 'Afternoon'), isTrue);
      expect(items.any((item) => item.timePeriod == 'Evening'), isTrue);
    });

    test('Every routine item features concrete time, action and why it matters rationale', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final items = container.read(routineProvider);
      for (final item in items) {
        expect(item.time, isNotEmpty, reason: 'Item ${item.id} must have time');
        expect(item.title, isNotEmpty, reason: 'Item ${item.id} must have action title');
        expect(item.detail, isNotEmpty, reason: 'Item ${item.id} must have action detail');
        expect(item.reason, isNotEmpty, reason: 'Item ${item.id} must have why it matters reason');
      }
    });

    test('Toggling routine completion updates item state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final items = container.read(routineProvider);
      final firstId = items.first.id;
      expect(items.first.isCompleted, isFalse);

      container.read(routineProvider.notifier).toggleCompleted(firstId);
      expect(container.read(routineProvider).firstWhere((i) => i.id == firstId).isCompleted, isTrue);

      container.read(routineProvider.notifier).toggleCompleted(firstId);
      expect(container.read(routineProvider).firstWhere((i) => i.id == firstId).isCompleted, isFalse);
    });
  });

  group('Routine Typed Models & Serialization (FastAPI Compatibility)', () {
    test('RoutineItem.fromJson parses FastAPI RoutineItemResponse schema', () {
      final json = {
        'id': 'morning_exercise',
        'time': '7:00 AM',
        'time_period': 'Morning',
        'title': 'Exercise indoors',
        'detail': 'Avoid strenuous outdoor workouts during morning smog.',
        'reason': 'Particle dose increases with high inhalation rates.',
        'category': 'exercise',
        'target_audience': 'All Family Members',
      };

      final item = RoutineItem.fromJson(json);
      expect(item.id, 'morning_exercise');
      expect(item.time, '7:00 AM');
      expect(item.timePeriod, 'Morning');
      expect(item.title, 'Exercise indoors');
      expect(item.reason, contains('Particle dose increases'));
      expect(item.category, RoutineCategory.exercise);
      expect(item.targetAudience, 'All Family Members');
      expect(item.isCompleted, isFalse);

      final serialized = item.toJson();
      expect(serialized['id'], 'morning_exercise');
      expect(serialized['category'], 'exercise');
    });

    test('RoutineListResponse.fromJson parses FastAPI backend list response', () {
      final json = {
        'city': 'New Delhi',
        'is_mock': true,
        'routines': [
          {
            'id': 'night_shield',
            'time': '10:00 PM',
            'time_period': 'Night',
            'title': 'Bedroom air purification',
            'detail': 'Run HEPA on quiet mode.',
            'reason': 'Prevents prolonged sleep exposure.',
            'category': 'indoor',
            'target_audience': 'All',
          }
        ],
      };

      final response = RoutineListResponse.fromJson(json);
      expect(response.city, 'New Delhi');
      expect(response.isMock, isTrue);
      expect(response.routines.length, 1);
      expect(response.routines.first.title, 'Bedroom air purification');
    });

    test('MockRoutineRepository loads all items via contract interface', () async {
      final repo = MockRoutineRepository();
      final routines = await repo.loadRoutines();
      expect(routines.length, 5);
      expect(routines.any((r) => r.timePeriod == 'Night'), isTrue);
    });
  });
}
