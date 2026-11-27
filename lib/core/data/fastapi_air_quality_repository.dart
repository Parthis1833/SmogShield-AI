import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/air_quality.dart';
import 'air_quality_repository.dart';

/// Compatibility adapter for the retired city-based AQI repository contract.
class FastApiAirQualityRepository implements AirQualityRepository {
  final String baseUrl;
  final http.Client _client;

  FastApiAirQualityRepository({
    String? baseUrl,
    http.Client? client,
  })  : baseUrl = baseUrl ?? AppConfig.apiBaseUrl,
        _client = client ?? http.Client();

  @override
  Future<AirQuality> load() => loadCity('New Delhi');

  @override
  Future<AirQuality> loadCity(String city) async {
    throw AirQualityRepositoryException(
      'City-name AQI snapshots are not supported. Select a location to load '
      'nearby pollutant observations.',
    );
  }

  @override
  List<String> getAvailableCities() => const [
        'New Delhi',
        'Lahore',
        'Beijing',
        'Mumbai',
        'New York',
        'London',
      ];

  @override
  Future<List<HourlyAqi>> getHourlyForecast(String city) async {
    final quality = await loadCity(city);
    return quality.hourlyForecast;
  }

  @override
  Future<bool> checkHealth() async {
    try {
      final uri = Uri.parse('$baseUrl/health');
      final response =
          await _client.get(uri).timeout(const Duration(seconds: 4));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
