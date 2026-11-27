import 'dart:convert';
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/nearby_air_quality.dart';

String get defaultApiBaseUrl => AppConfig.apiBaseUrl;

class NearbyAirQualityRepositoryException implements Exception {
  const NearbyAirQualityRepositoryException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class NearbyAirQualityRepository {
  NearbyAirQualityRepository({
    String? baseUrl,
    http.Client? client,
  })  : baseUrl = baseUrl ?? defaultApiBaseUrl,
        _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  Future<NearbyAirQuality> loadNearby({
    required double latitude,
    required double longitude,
    String? city,
    String? state,
    String? country,
    String? displayName,
  }) {
    if (!latitude.isFinite ||
        latitude < -90 ||
        latitude > 90 ||
        !longitude.isFinite ||
        longitude < -180 ||
        longitude > 180) {
      throw const NearbyAirQualityRepositoryException(
        'The selected location has invalid coordinates.',
      );
    }
    final parameters = <String, String>{
      'lat': '$latitude',
      'lon': '$longitude',
      if (city != null) 'city': city,
      if (state != null) 'state': state,
      if (country != null) 'country': country,
      if (displayName != null) 'display_name': displayName,
    };
    return _get(
      '/api/v1/air-quality/nearby',
      parameters,
    );
  }

  Future<NearbyAirQuality> search(String query) {
    return _get('/api/v1/air-quality/search', {'query': query.trim()});
  }

  Future<NearbyAirQuality> _get(
    String path,
    Map<String, String> queryParameters,
  ) async {
    try {
      final uri = Uri.parse('$baseUrl$path').replace(
        queryParameters: queryParameters,
      );
      final response = await _client.get(
        uri,
        headers: const {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 25));
      final body = jsonDecode(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final detail =
            body is Map<String, dynamic> ? body['detail']?.toString() : null;
        throw NearbyAirQualityRepositoryException(
          detail ?? 'Air-quality service returned HTTP ${response.statusCode}.',
          statusCode: response.statusCode,
        );
      }
      if (body is! Map<String, dynamic>) {
        throw const FormatException(
            'Air-quality service returned invalid data.');
      }
      return NearbyAirQuality.fromJson(body);
    } on NearbyAirQualityRepositoryException {
      rethrow;
    } on FormatException catch (error) {
      throw NearbyAirQualityRepositoryException(
        'Could not read air-quality response: ${error.message}',
      );
    } on http.ClientException catch (error) {
      throw NearbyAirQualityRepositoryException(
        'Could not connect to the SmogShield backend: ${error.message}',
      );
    } on TimeoutException {
      throw const NearbyAirQualityRepositoryException(
        'The air-quality request timed out. Check your connection and try again.',
      );
    } catch (error) {
      if (error is NearbyAirQualityRepositoryException) rethrow;
      throw NearbyAirQualityRepositoryException(
        'Air-quality request failed: $error',
      );
    }
  }
}

final nearbyAirQualityRepositoryProvider = Provider<NearbyAirQualityRepository>(
  (ref) => NearbyAirQualityRepository(),
);
