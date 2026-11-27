import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smogshield_ai/core/data/location_search_repository.dart';
import 'package:smogshield_ai/core/data/nearby_air_quality_repository.dart';
import 'package:smogshield_ai/core/models/nearby_air_quality.dart';
import 'package:smogshield_ai/core/data/mock_repository.dart';
import 'package:smogshield_ai/features/dashboard/dashboard_screen.dart';

Map<String, dynamic> _nearbyResponse({
  required bool found,
  String? stationName,
  double requestedLatitude = 19.076,
  double requestedLongitude = 72.8777,
  String freshness = 'Fresh',
  bool isCached = false,
  String dataStatus = 'nearest_station',
  int searchRadiusKm = 5,
}) {
  return {
    'found': found,
    'status': found ? 'success' : 'no_data',
    'source': 'OpenAQ',
    'data_status': found ? dataStatus : 'no_station',
    'requested_location': {
      'latitude': requestedLatitude,
      'longitude': requestedLongitude,
    },
    'station': found
        ? {
            'id': '123',
            'name': stationName,
            'latitude': 19.08,
            'longitude': 72.88,
            'distance_km': 2.4,
          }
        : null,
    'is_cached': isCached,
    'cache_age_seconds': isCached ? 420.0 : 0,
    'search_radius_km': searchRadiusKm,
    'provider_error': isCached ? 'OpenAQ temporarily unavailable.' : null,
    'location_id': found ? '123' : null,
    'station_name': stationName,
    'distance_km': found ? 2.4 : null,
    'provider': found ? 'Example Network' : null,
    'observed_at': found ? '2026-01-02T03:04:00Z' : null,
    'freshness': found ? freshness : null,
    'freshest_age_minutes': found ? 12.0 : null,
    'pollutants': {
      'pm25': {
        'value': found ? 12.5 : null,
        'unit': found ? 'µg/m³' : null,
        'observed_at': found ? '2026-01-02T03:04:00Z' : null,
      },
      'pm10': {'value': null, 'unit': null, 'observed_at': null},
      'no2': {'value': null, 'unit': null, 'observed_at': null},
      'so2': {'value': null, 'unit': null, 'observed_at': null},
      'o3': {'value': null, 'unit': null, 'observed_at': null},
      'co': {'value': null, 'unit': null, 'observed_at': null},
    },
    'recommendations':
        found ? ['Keep windows closed during peak readings.'] : [],
    'recommendation_engine': found ? 'gemini' : null,
    'recommendations_is_mock': !found,
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  LocationSearchRepository locationRepository({
    List<String>? requestPaths,
  }) {
    final client = MockClient((request) async {
      requestPaths?.add(request.url.path);
      expect(request.headers['authorization'], 'Bearer test-id-token');
      if (request.url.path == '/api/v1/locations/search') {
        final city = request.url.queryParameters['q']!;
        expect(request.url.queryParameters['session_token'], hasLength(36));
        return http.Response(
          jsonEncode({
            'suggestions': [
              {
                'place_id': 'places/$city',
                'city': city,
                'state': null,
                'country': null,
                'display_name': '$city, India',
                'description': '$city, India',
                'attribution': 'Google Maps',
              }
            ],
            'session_token': request.url.queryParameters['session_token'],
            'source': 'Google Places',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      expect(request.url.path, '/api/v1/locations/details');
      final city = request.url.queryParameters['place_id']!.substring(7);
      return http.Response(
        jsonEncode({
          'place_id': 'places/$city',
          'city': city,
          'state': 'Delhi',
          'country': 'India',
          'latitude': 28.6139,
          'longitude': 77.209,
          'display_name': 'New Delhi, Delhi, India',
          'attribution': 'Google Maps',
          'source': 'Google Places',
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    return LocationSearchRepository(
      baseUrl: 'https://api.example',
      client: client,
      idTokenProvider: () async => 'test-id-token',
    );
  }

  test('selected and recent locations restore from persisted Riverpod state',
      () async {
    final location = LocationDetails(
      placeId: 'places/pune',
      city: 'Pune',
      state: 'Maharashtra',
      country: 'India',
      latitude: 18.5204,
      longitude: 73.8567,
      displayName: 'Pune, Maharashtra, India',
    );
    final writer = ProviderContainer();
    await writer.read(selectedLocationProvider.notifier).setLocation(location);
    await writer.read(recentLocationsProvider.notifier).add(location);
    writer.dispose();

    final reader = ProviderContainer();
    await reader.read(selectedLocationProvider.notifier).restore();
    await reader.read(recentLocationsProvider.notifier).restore();

    expect(reader.read(selectedLocationProvider)?.city, 'Pune');
    expect(reader.read(selectedLocationProvider)?.latitude, 18.5204);
    expect(reader.read(recentLocationsProvider).single.displayName,
        'Pune, Maharashtra, India');
    reader.dispose();
  });

  test('parses nullable concentration values and recommendation metadata', () {
    final response = NearbyAirQuality.fromJson(
      _nearbyResponse(found: true, stationName: 'Central monitor'),
    );

    expect(response.stationName, 'Central monitor');
    expect(response.source, 'OpenAQ');
    expect(response.requestedLocation?.latitude, 19.076);
    expect(response.stationLatitude, 19.08);
    expect(response.pollutants['pm25']?.value, 12.5);
    expect(response.pollutants['pm25']?.unit, 'µg/m³');
    expect(
      response.pollutants['pm25']?.observedAt,
      DateTime.parse('2026-01-02T03:04:00Z'),
    );
    expect(response.pollutants['pm10']?.value, isNull);
    expect(response.recommendations,
        ['Keep windows closed during peak readings.']);
    expect(response.recommendationsAreMock, isFalse);
  });

  test('parses pollutant values from the documented measurements object', () {
    final payload = _nearbyResponse(found: false)
      ..['pollutants'] = <String, dynamic>{}
      ..['measurements'] = {
        'PM2.5': {
          'value': 18.2,
          'unit': 'µg/m³',
          'observed_at': '2026-01-02T03:04:00Z',
        },
      };

    final response = NearbyAirQuality.fromJson(payload);

    expect(response.pollutants['PM2.5']?.value, 18.2);
    expect(response.pollutants['PM2.5']?.unit, 'µg/m³');
  });

  test('Google Places details require finite, in-range coordinates', () {
    final valid = LocationDetails.fromJson({
      'place_id': 'places/pune',
      'city': 'Pune',
      'latitude': 18.5204,
      'longitude': 73.8567,
      'display_name': 'Pune, Maharashtra, India',
    });

    expect(valid.latitude, 18.5204);
    expect(valid.longitude, 73.8567);
    expect(
      () => LocationDetails.fromJson({
        'place_id': 'places/pune',
        'city': 'Pune',
        'latitude': 91,
        'longitude': 73.8567,
        'display_name': 'Pune, Maharashtra, India',
      }),
      throwsFormatException,
    );
    expect(
      () => LocationDetails.fromJson({
        'place_id': 'places/pune',
        'city': 'Pune',
        'latitude': 18.5204,
        'longitude': double.nan,
        'display_name': 'Pune, Maharashtra, India',
      }),
      throwsFormatException,
    );
  });

  test('nearby repository rejects invalid coordinates before HTTP', () async {
    final repository = NearbyAirQualityRepository(
      baseUrl: 'https://api.example',
      client: MockClient((_) async {
        fail('Invalid coordinates must not be sent to the backend.');
      }),
    );

    await expectLater(
      () => repository.loadNearby(latitude: 91, longitude: 73.8567),
      throwsA(isA<NearbyAirQualityRepositoryException>()),
    );
  });

  test('legacy city AQI adapter fails without making a retired endpoint call',
      () async {
    final repository = FastApiAirQualityRepository(
      baseUrl: 'https://api.example',
      client: MockClient((_) async {
        fail('The retired city-name AQI endpoint must not be called.');
      }),
    );

    await expectLater(
      repository.loadCity('Nagpur'),
      throwsA(isA<AirQualityRepositoryException>()),
    );
  });

  test('repository sends the expected manual-search request', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/api/v1/air-quality/search');
      expect(request.url.queryParameters, {'query': 'New Delhi'});
      return http.Response(
        jsonEncode(_nearbyResponse(found: false)),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final repository = NearbyAirQualityRepository(
        baseUrl: 'https://api.example', client: client);

    final result = await repository.search('  New Delhi  ');

    expect(result.found, isFalse);
  });

  testWidgets(
      'dashboard startup does not activate the retired city AQI provider',
      (tester) async {
    var cityAqiRequests = 0;
    final container = ProviderContainer(
      overrides: [
        airQualityProvider.overrideWith((ref) async {
          cityAqiRequests++;
          throw StateError('The city AQI provider must not run.');
        }),
        locationSearchRepositoryProvider
            .overrideWithValue(locationRepository()),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(body: DashboardScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(cityAqiRequests, 0);
    final err = tester.takeException();
    if (err is FlutterError) {
      for (final d in err.diagnostics) {
        print('DIAG_DEEP: ${d.toStringDeep()}');
      }
    }
    expect(err, isNull);
  });

  testWidgets('dashboard identifies expanded-radius and cached stale readings',
      (tester) async {
    final client = MockClient((_) async => http.Response(
          jsonEncode(_nearbyResponse(
            found: true,
            stationName: 'Fallback station',
            freshness: 'Stale',
            isCached: true,
            dataStatus: 'nearest_station_fallback_25km',
            searchRadiusKm: 25,
          )),
          200,
          headers: {'content-type': 'application/json'},
        ));
    final repository = NearbyAirQualityRepository(
      baseUrl: 'https://api.example',
      client: client,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          nearbyAirQualityRepositoryProvider.overrideWithValue(repository),
          locationSearchRepositoryProvider
              .overrideWithValue(locationRepository()),
        ],
        child: const MaterialApp(home: Scaffold(body: DashboardScreen())),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Mumbai');
    await tester.tap(find.byTooltip('Search locations'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Mumbai'));
    await tester.pumpAndSettle();

    expect(find.text('Fallback station'), findsOneWidget);
    expect(find.textContaining('within 25 km'), findsOneWidget);
    expect(find.textContaining('Cached observation'), findsOneWidget);
    expect(find.textContaining('Stale reading'), findsOneWidget);
    final err = tester.takeException();
    if (err is FlutterError) {
      for (final d in err.diagnostics) {
        print('DIAG_DEEP: ${d.toStringDeep()}');
      }
    }
    expect(err, isNull);
  });

  testWidgets('dashboard searches a place and renders live data accessibly',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    final client = MockClient((request) async {
      expect(request.url.path, '/api/v1/air-quality/nearby');
      expect(request.url.queryParameters, {
        'lat': '28.6139',
        'lon': '77.209',
        'city': 'New Delhi',
        'state': 'Delhi',
        'country': 'India',
        'display_name': 'New Delhi, Delhi, India',
      });
      return http.Response(
        jsonEncode(_nearbyResponse(
          found: true,
          stationName: 'Central monitoring station',
          requestedLatitude: 28.6139,
          requestedLongitude: 77.209,
        )),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final repository = NearbyAirQualityRepository(
        baseUrl: 'https://api.example', client: client);

    final locationPaths = <String>[];
    final container = ProviderContainer(
      overrides: [
        nearbyAirQualityRepositoryProvider.overrideWithValue(repository),
        locationSearchRepositoryProvider.overrideWithValue(
          locationRepository(requestPaths: locationPaths),
        ),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(body: DashboardScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'New Delhi');
    await tester.tap(find.byTooltip('Search locations'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'New Delhi'));
    await tester.pumpAndSettle();

    expect(locationPaths, [
      '/api/v1/locations/search',
      '/api/v1/locations/details',
    ]);
    expect(container.read(selectedLocationProvider)?.latitude, 28.6139);
    expect(container.read(selectedLocationProvider)?.longitude, 77.209);
    expect(find.text('Central monitoring station'), findsOneWidget);
    expect(
        find.textContaining('Your location: 28.6139, 77.2090'), findsOneWidget);
    expect(find.text('12.5'), findsOneWidget);
    expect(find.text('N/A'), findsNWidgets(5));
    expect(find.textContaining('not AQI'), findsOneWidget);
    expect(
        find.text('Keep windows closed during peak readings.'), findsOneWidget);
    final err = tester.takeException();
    if (err is FlutterError) {
      for (final d in err.diagnostics) {
        print('DIAG_DEEP: ${d.toStringDeep()}');
      }
    }
    expect(err, isNull);

    for (final width in [320.0, 768.0, 1280.0, 1920.0]) {
      tester.view.physicalSize = Size(width, 800);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'Viewport width $width');
    }
  });

  testWidgets('dashboard shows the no-station state from live search',
      (tester) async {
    final client = MockClient((_) async => http.Response(
          jsonEncode(_nearbyResponse(found: false)),
          200,
          headers: {'content-type': 'application/json'},
        ));
    final repository = NearbyAirQualityRepository(
        baseUrl: 'https://api.example', client: client);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          nearbyAirQualityRepositoryProvider.overrideWithValue(repository),
          locationSearchRepositoryProvider
              .overrideWithValue(locationRepository()),
        ],
        child: const MaterialApp(
          home: Scaffold(body: DashboardScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Nowhere');
    await tester.tap(find.byTooltip('Search locations'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Nowhere'));
    await tester.pumpAndSettle();

    expect(find.text('No station with recent readings found'), findsOneWidget);
    final err = tester.takeException();
    if (err is FlutterError) {
      for (final d in err.diagnostics) {
        print('DIAG_DEEP: ${d.toStringDeep()}');
      }
    }
    expect(err, isNull);
  });

  testWidgets('rapid city switching ignores late place and station responses',
      (tester) async {
    final londonDetails = Completer<http.Response>();
    final locationClient = MockClient((request) async {
      if (request.url.path == '/api/v1/locations/search') {
        final city = request.url.queryParameters['q']!;
        return http.Response(
          jsonEncode({
            'suggestions': [
              {
                'place_id': 'place/$city',
                'city': city,
                'state': null,
                'country': null,
                'display_name': '$city, country',
                'description': '$city, country',
                'attribution': 'Google Maps',
              }
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }

      final city = request.url.queryParameters['place_id']!.substring(6);
      if (city == 'London') return londonDetails.future;
      return http.Response(
        jsonEncode({
          'place_id': 'place/New York',
          'city': 'New York',
          'state': 'New York',
          'country': 'United States',
          'latitude': 40.7128,
          'longitude': -74.006,
          'display_name': 'New York, NY, USA',
          'attribution': 'Google Maps',
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final locations = LocationSearchRepository(
      baseUrl: 'https://api.example',
      client: locationClient,
      idTokenProvider: () async => 'test-id-token',
    );
    final nearby = NearbyAirQualityRepository(
      baseUrl: 'https://api.example',
      client: MockClient((request) async {
        expect(request.url.path, '/api/v1/air-quality/nearby');
        expect(request.url.queryParameters['lat'], '40.7128');
        return http.Response(
          jsonEncode(
            _nearbyResponse(found: true, stationName: 'New York station'),
          ),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          locationSearchRepositoryProvider.overrideWithValue(locations),
          nearbyAirQualityRepositoryProvider.overrideWithValue(nearby),
        ],
        child: const MaterialApp(
          home: Scaffold(body: DashboardScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'London');
    await tester.tap(find.byTooltip('Search locations'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'London'));
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'New York');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'New York'));
    await tester.pumpAndSettle();

    londonDetails.complete(
      http.Response(
        jsonEncode({
          'place_id': 'place/London',
          'city': 'London',
          'state': 'England',
          'country': 'United Kingdom',
          'latitude': 51.5074,
          'longitude': -0.1278,
          'display_name': 'London, United Kingdom',
          'attribution': 'Google Maps',
        }),
        200,
        headers: {'content-type': 'application/json'},
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('New York station'), findsOneWidget);
    expect(find.text('London station'), findsNothing);
    final err = tester.takeException();
    if (err is FlutterError) {
      for (final d in err.diagnostics) {
        print('DIAG_DEEP: ${d.toStringDeep()}');
      }
    }
    expect(err, isNull);
  });
}
