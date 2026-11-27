import 'package:flutter_test/flutter_test.dart';
import 'package:smogshield_ai/core/constants/app_colors.dart';
import 'package:smogshield_ai/core/constants/aqi_standards.dart';
import 'package:smogshield_ai/core/data/mock_repository.dart';
import 'package:smogshield_ai/core/models/air_quality.dart';

void main() {
  AirQuality buildAirQuality(int aqi) => AirQuality(
        city: 'Demo City',
        aqi: aqi,
        pm25: 184.0,
        pm10: 276.0,
        no2: 84.5,
        so2: 24.2,
        co: 2.8,
        o3: 38.0,
        updatedAt: DateTime(2026, 11, 17, 8, 0),
        source: 'Central Continuous Monitoring (CPCB Simulated)',
        stationName: 'Anand Vihar Clean Air Station',
        isMock: true,
      );

  group('Indian AQI Category Exact Boundary Tests', () {
    test('AQI category colors have an accessible foreground pairing', () {
      for (final aqi in [25, 75, 150, 250, 350, 450]) {
        final foreground = AppColors.getAqiTextColor(aqi);
        final background = AppColors.getAqiColor(aqi);
        final foregroundLuminance = foreground.computeLuminance();
        final backgroundLuminance = background.computeLuminance();
        final lighter = foregroundLuminance > backgroundLuminance
            ? foregroundLuminance
            : backgroundLuminance;
        final darker = foregroundLuminance > backgroundLuminance
            ? backgroundLuminance
            : foregroundLuminance;
        expect(
          (lighter + 0.05) / (darker + 0.05),
          greaterThanOrEqualTo(4.5),
          reason: 'AQI $aqi uses an accessible foreground',
        );
      }
    });

    test('Boundary 0–50: Good', () {
      expect(buildAirQuality(0).category, 'Good');
      expect(buildAirQuality(25).category, 'Good');
      expect(buildAirQuality(50).category, 'Good'); // Exact upper boundary
      expect(buildAirQuality(50).categoryColor, AppColors.aqiGood);
      expect(
        buildAirQuality(50).healthAdvisory,
        contains('satisfactory, and air pollution poses little or no risk'),
      );
    });

    test('Boundary 51–100: Satisfactory', () {
      expect(
          buildAirQuality(51).category, 'Satisfactory'); // Exact lower boundary
      expect(buildAirQuality(75).category, 'Satisfactory');
      expect(buildAirQuality(100).category,
          'Satisfactory'); // Exact upper boundary
      expect(buildAirQuality(100).categoryColor, AppColors.aqiSatisfactory);
      expect(
        buildAirQuality(100).healthAdvisory,
        contains('Minor breathing discomfort to sensitive people'),
      );
    });

    test('Boundary 101–200: Moderate', () {
      expect(buildAirQuality(101).category, 'Moderate'); // Exact lower boundary
      expect(buildAirQuality(150).category, 'Moderate');
      expect(buildAirQuality(200).category, 'Moderate'); // Exact upper boundary
      expect(buildAirQuality(200).categoryColor, AppColors.aqiModerate);
      expect(
        buildAirQuality(200).healthAdvisory,
        contains(
            'breathing discomfort to children, the elderly, and people with asthma'),
      );
    });

    test('Boundary 201–300: Poor', () {
      expect(buildAirQuality(201).category, 'Poor'); // Exact lower boundary
      expect(buildAirQuality(250).category, 'Poor');
      expect(buildAirQuality(300).category, 'Poor'); // Exact upper boundary
      expect(buildAirQuality(300).categoryColor, AppColors.aqiPoor);
      expect(
        buildAirQuality(300).healthAdvisory,
        contains('Breathing discomfort to most people on prolonged exposure'),
      );
    });

    test('Boundary 301–400: Very Poor (Includes Mock AQI 342)', () {
      expect(
          buildAirQuality(301).category, 'Very Poor'); // Exact lower boundary
      expect(buildAirQuality(342).category,
          'Very Poor'); // Mock Demonstration Data point
      expect(
          buildAirQuality(400).category, 'Very Poor'); // Exact upper boundary
      expect(buildAirQuality(342).categoryColor, AppColors.aqiVeryPoor);
      expect(
        buildAirQuality(342).healthAdvisory,
        contains(
            'Respiratory illness on prolonged exposure. Significant risk for sensitive groups. Wear N95 outdoors.'),
      );
    });

    test('Boundary 401+: Severe', () {
      expect(buildAirQuality(401).category, 'Severe'); // Exact lower boundary
      expect(buildAirQuality(450).category, 'Severe');
      expect(buildAirQuality(500).category, 'Severe'); // Standard scale maximum
      expect(buildAirQuality(525).category, 'Severe'); // Hazardous off-scale
      expect(buildAirQuality(500).categoryColor, AppColors.aqiSevere);
      expect(
        buildAirQuality(500).healthAdvisory,
        contains(
            'Emergency conditions. Affects healthy people and severely impacts individuals with lung or heart disease.'),
      );
    });
  });

  group('AqiStandardsHelper Indian Categories', () {
    test('Returns correct AqiCategoryInfo metadata for boundaries', () {
      final infoGood = AqiStandardsHelper.getCategoryInfo(50);
      expect(infoGood.category, 'Good');
      expect(infoGood.minAqi, 0);
      expect(infoGood.maxAqi, 50);

      final infoSatisfactory = AqiStandardsHelper.getCategoryInfo(51);
      expect(infoSatisfactory.category, 'Satisfactory');

      final infoModerate = AqiStandardsHelper.getCategoryInfo(101);
      expect(infoModerate.category, 'Moderate');

      final infoPoor = AqiStandardsHelper.getCategoryInfo(201);
      expect(infoPoor.category, 'Poor');

      final infoVeryPoor = AqiStandardsHelper.getCategoryInfo(342);
      expect(infoVeryPoor.category, 'Very Poor');
      expect(infoVeryPoor.minAqi, 301);
      expect(infoVeryPoor.maxAqi, 400);

      final infoSevere = AqiStandardsHelper.getCategoryInfo(401);
      expect(infoSevere.category, 'Severe');
    });
  });

  group('Demonstration Data and Serialization', () {
    test('Mock AQI 342 New Delhi scenario carries demonstration metadata',
        () async {
      final repo = MockAirQualityRepository();
      final delhi = await repo.load();

      expect(delhi.city, 'New Delhi');
      expect(delhi.aqi, 342);
      expect(delhi.category, 'Very Poor');
      expect(delhi.isMock, isTrue);
      expect(delhi.source, contains('CPCB Simulated'));
      expect(delhi.stationName, 'Anand Vihar Clean Air Station');
      expect(delhi.pm25, 184.0);
      expect(delhi.pm10, 276.0);
      expect(delhi.no2, 84.5);
      expect(delhi.so2, 24.2);
      expect(delhi.co, 2.8);
      expect(delhi.o3, 38.0);
      expect(delhi.hourlyForecast, isNotEmpty);
      expect(delhi.formattedObservationTime, contains('Nov 2026'));
      expect(delhi.formattedObservationTime, contains('IST'));
    });

    test('Unknown demo cities never reuse New Delhi measurements', () async {
      final repo = MockAirQualityRepository();
      await expectLater(
        repo.loadCity('Pune'),
        throwsA(
          isA<AirQualityRepositoryException>().having(
            (error) => error.statusCode,
            'statusCode',
            404,
          ),
        ),
      );
    });

    test('AirQuality.fromJson parses FastAPI backend response schema', () {
      final fastApiPayload = {
        'city': 'New Delhi',
        'aqi': 342,
        'aqi_standard': 'IN_AQI',
        'category': 'Very Poor',
        'pm25_ug_m3': 184.0,
        'pm10_ug_m3': 276.0,
        'no2_ug_m3': 84.5,
        'so2_ug_m3': 24.2,
        'co_mg_m3': 2.8,
        'o3_ug_m3': 38.0,
        'station_name': 'Anand Vihar Clean Air Station',
        'observed_at': '2026-11-17T08:00:00+05:30',
        'source': 'Central Continuous Monitoring (CPCB Simulated)',
        'is_mock': true,
        'health_advisory': 'Respiratory illness on prolonged exposure.',
        'hourly_trend': [
          {'hour': 0, 'aqi': 310, 'pm25': 160.0},
          {'hour': 8, 'aqi': 375, 'pm25': 210.0},
        ],
      };

      final parsed = AirQuality.fromJson(fastApiPayload);
      expect(parsed.city, 'New Delhi');
      expect(parsed.aqi, 342);
      expect(parsed.pm25, 184.0);
      expect(parsed.pm10, 276.0);
      expect(parsed.no2, 84.5);
      expect(parsed.so2, 24.2);
      expect(parsed.co, 2.8);
      expect(parsed.o3, 38.0);
      expect(parsed.isMock, isTrue);
      expect(parsed.hourlyForecast.length, 2);
      expect(parsed.hourlyForecast.first.timeLabel, '12 AM');

      // Verify toJson roundtrip
      final json = parsed.toJson();
      expect(json['city'], 'New Delhi');
      expect(json['aqi'], 342);
      expect(json['pm25_ug_m3'], 184.0);
      expect(json['is_mock'], isTrue);
    });
  });

  group('AirQualityRepository Abstract Contract & Implementations', () {
    test('MockAirQualityRepository fulfills contract', () async {
      final repo = MockAirQualityRepository();
      expect(repo, isA<AirQualityRepository>());

      final cities = repo.getAvailableCities();
      expect(cities, contains('New Delhi'));
      expect(cities, contains('Mumbai'));
      expect(cities, contains('Lahore'));

      final health = await repo.checkHealth();
      expect(health, isTrue);

      final forecast = await repo.getHourlyForecast('New Delhi');
      expect(forecast, isNotEmpty);
    });

    test('FastApiAirQualityRepository fulfills contract interface', () {
      final repo =
          FastApiAirQualityRepository(baseUrl: 'http://127.0.0.1:8000');
      expect(repo, isA<AirQualityRepository>());
      expect(repo.getAvailableCities(), contains('New Delhi'));
    });
  });
}
