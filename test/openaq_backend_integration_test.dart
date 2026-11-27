import 'package:flutter_test/flutter_test.dart';
import 'package:smogshield_ai/core/data/nearby_air_quality_repository.dart';

const backendBaseUrl =
    String.fromEnvironment('SMOGSHIELD_INTEGRATION_API_BASE_URL');

void main() {
  test(
    'Flutter repository reaches the FastAPI nearby-air endpoint',
    () async {
      final repository = NearbyAirQualityRepository(baseUrl: backendBaseUrl);
      try {
        final response = await repository.loadNearby(
          latitude: 28.6,
          longitude: 77.2,
        );
        expect(response.found, isA<bool>());
      } on NearbyAirQualityRepositoryException catch (error) {
        expect(error.statusCode, 503);
        expect(error.message, contains('not configured'));
      }
    },
    skip: backendBaseUrl.isEmpty
        ? 'Set SMOGSHIELD_INTEGRATION_API_BASE_URL to run against FastAPI.'
        : null,
  );
}
