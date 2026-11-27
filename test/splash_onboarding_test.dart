import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smogshield_ai/main.dart';
import 'package:smogshield_ai/features/onboarding/onboarding_screen.dart';
import 'package:smogshield_ai/features/splash/splash_screen.dart';

void main() {
  testWidgets('Startup splash handles direct web routes while Firebase loads',
      (tester) async {
    tester.binding.platformDispatcher.defaultRouteNameTestValue = '/settings';
    addTearDown(() {
      tester.binding.platformDispatcher.defaultRouteNameTestValue = '/';
    });

    await tester.pumpWidget(const SmogShieldLoadingApp());
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(SplashScreen), findsWidgets);
  });

  testWidgets('Startup splash presents a branded Firebase loading state',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: SplashScreen()),
    );

    expect(find.text('SmogShield AI'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Onboarding remains scrollable on phones and composed on Web',
      (tester) async {
    for (final size in [const Size(320, 568), const Size(1280, 800)]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(
        const MaterialApp(home: OnboardingScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Get started'), findsOneWidget);
      expect(find.text('Measured air, with context'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'Viewport $size');
    }

    addTearDown(tester.view.resetPhysicalSize);
  });
}
