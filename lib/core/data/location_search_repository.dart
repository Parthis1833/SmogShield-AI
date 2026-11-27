import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'nearby_air_quality_repository.dart';

class LocationSuggestion {
  const LocationSuggestion({
    required this.placeId,
    required this.city,
    required this.displayName,
    required this.description,
    this.latitude,
    this.longitude,
    this.state,
    this.country,
  });

  final String placeId;
  final String city;
  final String? state;
  final String? country;
  final double? latitude;
  final double? longitude;
  final String displayName;
  final String description;

  factory LocationSuggestion.fromJson(Map<String, dynamic> json) =>
      LocationSuggestion(
        placeId: json['place_id'] as String,
        city: json['city'] as String,
        state: json['state'] as String?,
        country: json['country'] as String?,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        displayName: json['display_name'] as String,
        description: json['description'] as String,
      );
}

class LocationDetails {
  const LocationDetails({
    required this.placeId,
    required this.city,
    required this.latitude,
    required this.longitude,
    required this.displayName,
    this.state,
    this.country,
  });

  final String placeId;
  final String city;
  final String? state;
  final String? country;
  final double latitude;
  final double longitude;
  final String displayName;

  factory LocationDetails.fromJson(Map<String, dynamic> json) =>
      LocationDetails(
        placeId: json['place_id'] as String,
        city: json['city'] as String,
        state: json['state'] as String?,
        country: json['country'] as String?,
        latitude: _coordinate(
          json['latitude'],
          minimum: -90,
          maximum: 90,
          name: 'latitude',
        ),
        longitude: _coordinate(
          json['longitude'],
          minimum: -180,
          maximum: 180,
          name: 'longitude',
        ),
        displayName: json['display_name'] as String,
      );

  static double _coordinate(
    Object? value, {
    required double minimum,
    required double maximum,
    required String name,
  }) {
    if (value is! num ||
        !value.isFinite ||
        value < minimum ||
        value > maximum) {
      throw FormatException('Google Places returned an invalid $name.');
    }
    return value.toDouble();
  }

  Map<String, dynamic> toJson() => {
        'place_id': placeId,
        'city': city,
        'state': state,
        'country': country,
        'latitude': latitude,
        'longitude': longitude,
        'display_name': displayName,
      };
}

class LocationSearchRepositoryException implements Exception {
  const LocationSearchRepositoryException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class LocationSearchRepository {
  LocationSearchRepository({
    String? baseUrl,
    http.Client? client,
    Future<String> Function()? idTokenProvider,
  })  : baseUrl = baseUrl ?? defaultApiBaseUrl,
        _client = client ?? http.Client(),
        _idTokenProvider = idTokenProvider ?? _firebaseIdToken;

  final String baseUrl;
  final http.Client _client;
  final Future<String> Function() _idTokenProvider;

  Future<List<LocationSuggestion>> search(
    String query, {
    required String sessionToken,
  }) async {
    final response = await _get('/api/v1/locations/search', {
      'q': query.trim(),
      'session_token': sessionToken,
    });
    final rawSuggestions = response['suggestions'];
    if (rawSuggestions is! List) {
      throw const LocationSearchRepositoryException(
        'Location service returned invalid suggestions.',
      );
    }
    return rawSuggestions
        .whereType<Map<String, dynamic>>()
        .map(LocationSuggestion.fromJson)
        .toList();
  }

  Future<LocationDetails> details(
    String placeId, {
    required String sessionToken,
  }) async {
    final response = await _get('/api/v1/locations/details', {
      'place_id': placeId,
      'session_token': sessionToken,
    });
    return LocationDetails.fromJson(response);
  }

  Future<Map<String, dynamic>> _get(
    String path,
    Map<String, String> queryParameters,
  ) async {
    try {
      final idToken = await _idTokenProvider();
      final response = await _client.get(
        Uri.parse('$baseUrl$path').replace(
          queryParameters: queryParameters,
        ),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
      ).timeout(const Duration(seconds: 9));
      final body = jsonDecode(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final detail =
            body is Map<String, dynamic> ? body['detail']?.toString() : null;
        throw LocationSearchRepositoryException(
          detail ?? 'Location service returned HTTP ${response.statusCode}.',
          statusCode: response.statusCode,
        );
      }
      if (body is! Map<String, dynamic>) {
        throw const FormatException('Location service returned invalid data.');
      }
      return body;
    } on LocationSearchRepositoryException {
      rethrow;
    } on FormatException catch (error) {
      throw LocationSearchRepositoryException(
        'Could not read location response: ${error.message}',
      );
    } on http.ClientException catch (error) {
      throw LocationSearchRepositoryException(
        'Could not connect to the SmogShield backend: ${error.message}',
      );
    } on TimeoutException {
      throw const LocationSearchRepositoryException(
        'Location service timed out. Try again.',
      );
    } on FirebaseAuthException catch (error) {
      throw LocationSearchRepositoryException(
        'Firebase authentication failed: ${error.message ?? error.code}',
      );
    } catch (error) {
      throw LocationSearchRepositoryException(
        'Location request failed: $error',
      );
    }
  }

  static Future<String> _firebaseIdToken() async {
    if (Firebase.apps.isEmpty) {
      throw const LocationSearchRepositoryException(
        'Firebase is not configured. Configure Firebase Authentication to search cities.',
      );
    }

    final auth = FirebaseAuth.instance;
    final user = auth.currentUser;
    if (user == null || user.isAnonymous) {
      throw const LocationSearchRepositoryException(
        'Sign in before searching cities.',
      );
    }
    final token = await user.getIdToken();
    if (token == null || token.isEmpty) {
      throw const LocationSearchRepositoryException(
        'Firebase did not return an ID token.',
      );
    }
    return token;
  }
}

final locationSearchRepositoryProvider = Provider<LocationSearchRepository>(
  (ref) => LocationSearchRepository(),
);

class SelectedLocationNotifier extends Notifier<LocationDetails?> {
  static const _preferenceKey = 'selected_air_quality_location';

  @override
  LocationDetails? build() => null;

  Future<void> restore() async {
    final preferences = await SharedPreferences.getInstance();
    final stored = preferences.getString(_preferenceKey);
    if (stored == null) return;
    try {
      state = LocationDetails.fromJson(
        jsonDecode(stored) as Map<String, dynamic>,
      );
    } on FormatException catch (error) {
      debugPrint('Could not restore selected location: $error');
      await preferences.remove(_preferenceKey);
    } on TypeError catch (error) {
      debugPrint('Could not restore selected location: $error');
      await preferences.remove(_preferenceKey);
    }
  }

  Future<void> setLocation(LocationDetails location) async {
    state = location;
    final preferences = await SharedPreferences.getInstance();
    if (!await preferences.setString(_preferenceKey, jsonEncode(location))) {
      throw StateError('Could not save the selected location.');
    }
  }

  Future<void> clearLocation() async {
    state = null;
    final preferences = await SharedPreferences.getInstance();
    if (preferences.containsKey(_preferenceKey) &&
        !await preferences.remove(_preferenceKey)) {
      throw StateError('Could not clear the selected location.');
    }
  }
}

final selectedLocationProvider =
    NotifierProvider<SelectedLocationNotifier, LocationDetails?>(
  SelectedLocationNotifier.new,
);

class RecentLocationsNotifier extends Notifier<List<LocationDetails>> {
  static const _preferenceKey = 'recent_air_quality_locations';

  @override
  List<LocationDetails> build() => const [];

  Future<void> restore() async {
    final preferences = await SharedPreferences.getInstance();
    final stored = preferences.getString(_preferenceKey);
    if (stored == null) return;
    try {
      final decoded = jsonDecode(stored) as List<dynamic>;
      state = decoded
          .whereType<Map<String, dynamic>>()
          .map(LocationDetails.fromJson)
          .take(5)
          .toList();
    } on FormatException catch (error) {
      debugPrint('Could not restore recent locations: $error');
      await preferences.remove(_preferenceKey);
    } on TypeError catch (error) {
      debugPrint('Could not restore recent locations: $error');
      await preferences.remove(_preferenceKey);
    }
  }

  Future<void> add(LocationDetails location) async {
    state = [
      location,
      ...state.where((item) => item.placeId != location.placeId),
    ].take(5).toList();
    final preferences = await SharedPreferences.getInstance();
    final encoded = jsonEncode(state.map((item) => item.toJson()).toList());
    if (!await preferences.setString(_preferenceKey, encoded)) {
      throw StateError('Could not save recent locations.');
    }
  }
}

final recentLocationsProvider =
    NotifierProvider<RecentLocationsNotifier, List<LocationDetails>>(
  RecentLocationsNotifier.new,
);
