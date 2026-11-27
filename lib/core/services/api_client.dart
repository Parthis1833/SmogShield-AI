import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/air_quality.dart';

class ApiClient {
  final String baseUrl;
  final http.Client _client;

  ApiClient({
    String? baseUrl,
    http.Client? client,
  }) : baseUrl = baseUrl ?? AppConfig.apiBaseUrl,
       _client = client ?? http.Client();

  Future<Map<String, dynamic>> checkHealth() async {
    try {
      final response = await _client.get(Uri.parse('$baseUrl/health')).timeout(
        const Duration(seconds: 3),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {
      // Backend offline or unreachable in local mock mode
    }
    return {'status': 'offline', 'mode': 'unavailable'};
  }

  Future<AirQuality?> fetchAirQuality({String city = 'New Delhi', String standard = 'IN_AQI'}) async {
    // The legacy city-name AQI endpoint was removed; use coordinates via
    // NearbyAirQualityRepository to avoid substituting fabricated values.
    return null;
  }
}
