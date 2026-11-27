import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/family_profile.dart';
import '../models/routine_item.dart';
import '../services/firebase_service.dart';
import 'family_profile_provider.dart';
import 'location_search_repository.dart';

abstract class RoutineRepository {
  Future<List<RoutineItem>> loadRoutines({
    required String city,
    required FamilyProfile profile,
  });
}

class RoutineRepositoryException implements Exception {
  const RoutineRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}

class FastApiRoutineRepository implements RoutineRepository {
  FastApiRoutineRepository({
    String? baseUrl,
    http.Client? client,
    Future<String> Function()? idTokenProvider,
  })  : baseUrl = baseUrl ?? AppConfig.apiBaseUrl,
        _client = client ?? http.Client(),
        _idTokenProvider =
            idTokenProvider ?? FirebaseAuthService().getIdToken;

  final String baseUrl;
  final http.Client _client;
  final Future<String> Function() _idTokenProvider;

  @override
  Future<List<RoutineItem>> loadRoutines({
    required String city,
    required FamilyProfile profile,
  }) async {
    try {
      final token = await _idTokenProvider();
      final uri = Uri.parse('$baseUrl/api/v1/routines').replace(
        queryParameters: {
          'city': city,
          'has_children': '${profile.childrenCount > 0}',
          'has_respiratory_condition': '${profile.hasVulnerableMember}',
          if (profile.primaryCommuteMode.isNotEmpty)
            'primary_commute_mode': profile.primaryCommuteMode,
          if (profile.airPurificationSetup.isNotEmpty)
            'air_purification_setup': profile.airPurificationSetup,
        },
      );
      final response = await _client.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 30));

      final body = jsonDecode(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final detail =
            body is Map<String, dynamic> ? body['detail']?.toString() : null;
        throw RoutineRepositoryException(
          detail ?? 'Routine service returned HTTP ${response.statusCode}.',
        );
      }
      if (body is! Map<String, dynamic>) {
        throw const FormatException('Routine service returned invalid data.');
      }
      return RoutineListResponse.fromJson(body).routines;
    } on RoutineRepositoryException {
      rethrow;
    } on TimeoutException {
      throw const RoutineRepositoryException(
        'Routine generation timed out. Try again.',
      );
    } on http.ClientException catch (error) {
      throw RoutineRepositoryException(
        'Could not connect to the routine service: ${error.message}',
      );
    } on FormatException catch (error) {
      throw RoutineRepositoryException(
        'Could not read routine response: ${error.message}',
      );
    } on StateError catch (error) {
      throw RoutineRepositoryException(error.message.toString());
    }
  }
}

final routineRepositoryProvider = Provider<RoutineRepository>(
  (ref) => FastApiRoutineRepository(
    idTokenProvider: () => ref.read(authServiceProvider).getIdToken(),
  ),
);

class RoutineNotifier extends AsyncNotifier<List<RoutineItem>> {
  @override
  Future<List<RoutineItem>> build() {
    final profile = ref.watch(familyProfileProvider);
    final location = ref.watch(selectedLocationProvider);
    final city = location?.city.isNotEmpty == true
        ? location!.city
        : profile.city;
    return ref
        .watch(routineRepositoryProvider)
        .loadRoutines(city: city, profile: profile);
  }

  void toggleCompleted(String id) {
    final routines = state.value;
    if (routines == null) return;
    state = AsyncData([
      for (final item in routines)
        if (item.id == id)
          item.copyWith(isCompleted: !item.isCompleted)
        else
          item,
    ]);
  }
}

final routineProvider =
    AsyncNotifierProvider<RoutineNotifier, List<RoutineItem>>(
  RoutineNotifier.new,
);
