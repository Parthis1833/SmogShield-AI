import '../models/air_quality.dart';

/// Abstract repository contract for retrieving air quality metrics and observations.
///
/// Designed to support:
/// 1. `MockAirQualityRepository`: Standalone client demonstration with realistic mock scenarios (e.g. New Delhi AQI 342).
/// 2. `FastApiAirQualityRepository`: Compatibility adapter that rejects city-only
///    AQI requests; live readings must use location coordinates and the nearby API.
abstract class AirQualityRepository {
  /// Loads default air quality observation (e.g. New Delhi demonstration snapshot with AQI 342).
  Future<AirQuality> load();

  /// Loads air quality observation for a given [city].
  Future<AirQuality> loadCity(String city);

  /// Returns the list of cities available for observation.
  List<String> getAvailableCities();

  /// Retrieves hourly AQI trend forecast for a given [city].
  Future<List<HourlyAqi>> getHourlyForecast(String city);

  /// Health check verifying connectivity with the data source / backend service.
  Future<bool> checkHealth();
}

/// Custom repository exception with context for error reporting and UI error states.
class AirQualityRepositoryException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic cause;

  const AirQualityRepositoryException(
    this.message, {
    this.statusCode,
    this.cause,
  });

  @override
  String toString() =>
      'AirQualityRepositoryException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
}
