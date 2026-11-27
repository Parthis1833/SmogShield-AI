import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smogshield_ai/app/app.dart';
import 'package:smogshield_ai/core/data/mock_repository.dart';
import 'package:smogshield_ai/core/models/air_quality.dart';
import 'package:smogshield_ai/features/dashboard/dashboard_screen.dart';

void main() {
  testWidgets('dashboard displays explicit mock-data warning', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: SmogShieldApp()));
    await tester.pumpAndSettle();
    expect(find.text('SmogShield AI'), findsOneWidget);
    expect(find.text('DEMO DATA — NOT LIVE'), findsOneWidget);
    expect(find.byIcon(Icons.air), findsOneWidget);
  });

  testWidgets('Dashboard renders complete demonstration data labels, Indian AQI, pollutants, and source', (tester) async {
    tester.view.physicalSize = const Size(1280, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const ProviderScope(child: SmogShieldApp()));
    await tester.pumpAndSettle();

    // 1. Mock AQI 342 clearly marked as demonstration data
    expect(find.text('DEMO DATA — NOT LIVE'), findsOneWidget);
    expect(find.text('Demonstration Data — Not Actual Current Conditions'), findsOneWidget);
    expect(find.text('342'), findsOneWidget);
    expect(find.textContaining('Mock AQI: 342'), findsWidgets);
    expect(find.textContaining('not imply or represent actual current atmospheric conditions'), findsWidgets);

    // 2. Indian AQI Category Presentation
    expect(find.text('Very Poor'), findsWidgets);
    expect(find.textContaining('Indian CPCB Scale'), findsOneWidget);
    expect(find.textContaining('Wear N95 outdoors'), findsWidgets);

    // 3. Pollutant measurements with units
    expect(find.text('Key Pollutants'), findsOneWidget);
    expect(find.text('PM 2.5'), findsOneWidget);
    expect(find.text('PM 10'), findsOneWidget);
    expect(find.text('NO₂'), findsOneWidget);
    expect(find.text('SO₂'), findsOneWidget);
    expect(find.text('CO'), findsOneWidget);
    expect(find.text('O₃'), findsOneWidget);
    expect(find.text('µg/m³'), findsWidgets);
    expect(find.text('mg/m³'), findsOneWidget);

    // 4. Source and Observation Labels
    expect(find.textContaining('Anand Vihar Clean Air Station'), findsWidgets);
    expect(find.textContaining('Central Continuous Monitoring'), findsWidgets);
    expect(find.textContaining('Observation Timestamp'), findsWidgets);
  });

  testWidgets('Dashboard renders loading state correctly', (tester) async {
    final completer = Completer<AirQuality>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          airQualityProvider.overrideWith((ref) => completer.future),
        ],
        child: const MaterialApp(
          home: Scaffold(body: DashboardScreen()),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('dashboard_loading_state')), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Loading Environmental Data...'), findsOneWidget);
  });

  testWidgets('Dashboard renders error state with retry and demo recovery buttons', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          airQualityProvider.overrideWith(
            (ref) => Future.error(
              const AirQualityRepositoryException('Failed to connect to air monitoring station', statusCode: 503),
            ),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(body: DashboardScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('dashboard_error_state')), findsOneWidget);
    expect(find.text('Unable to Load Air Quality Data'), findsOneWidget);
    expect(find.textContaining('Failed to connect to air monitoring station'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('Load Demo (New Delhi)'), findsOneWidget);
  });

  testWidgets('Dashboard renders empty state when air quality records are missing', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          airQualityProvider.overrideWith(
            (ref) => Future.value(
              AirQuality(
                city: '',
                aqi: -1,
                pm25: 0,
                pm10: 0,
                updatedAt: DateTime(2026),
                source: '',
                isMock: true,
              ),
            ),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(body: DashboardScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('dashboard_empty_state')), findsOneWidget);
    expect(find.text('No Air Quality Records Found'), findsOneWidget);
    expect(find.text('Select Monitored City'), findsOneWidget);
  });
}
