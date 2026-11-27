import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smogshield_ai/app/app.dart';
import 'package:smogshield_ai/features/impact/impact_screen.dart';
import 'package:smogshield_ai/features/profile/profile_screen.dart';

void main() {
  group('Phase 1 Quality Gate Widget & Viewport Tests', () {
    testWidgets(
        'Impact screen allows toggling actions and renders formula & exposure note',
        (tester) async {
      tester.view.physicalSize = const Size(360, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: ImpactScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check header and critical safety distinction
      expect(find.text('Your Impact'), findsOneWidget);
      expect(find.text('CRITICAL SAFETY DISTINCTION'), findsOneWidget);
      expect(
          find.textContaining('Community Emissions Savings'), findsOneWidget);
      expect(
          find.textContaining('Personal Exposure Reduction'), findsOneWidget);

      // Check initial logged count is 0
      expect(find.text('Actions Logged: 0'), findsOneWidget);

      // Scroll down until the Log Action button is visible
      await tester.scrollUntilVisible(
        find.text('Log Action'),
        250,
        scrollable: find.byType(Scrollable),
      );
      await tester.pumpAndSettle();

      // Tap the first Log Action button
      await tester.tap(find.text('Log Action').first);
      await tester.pumpAndSettle();

      // Now it should show "Recorded in Session"
      expect(find.text('Recorded in Session'), findsOneWidget);

      // Scroll back up to verify cumulative metrics updated
      await tester.scrollUntilVisible(
        find.text('Your Impact'),
        -250,
        scrollable: find.byType(Scrollable),
      );
      await tester.pumpAndSettle();
      expect(find.text('Actions Logged: 1'), findsOneWidget);

      // Scroll down and toggle it back off
      await tester.scrollUntilVisible(
        find.text('Recorded in Session'),
        250,
        scrollable: find.byType(Scrollable),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Recorded in Session').first);
      await tester.pumpAndSettle();

      // Scroll back up and verify it reset to 0
      await tester.scrollUntilVisible(
        find.text('Your Impact'),
        -250,
        scrollable: find.byType(Scrollable),
      );
      await tester.pumpAndSettle();
      expect(find.text('Actions Logged: 0'), findsOneWidget);
    });

    testWidgets(
        'Profile screen allows modifying demographics and vulnerability switches',
        (tester) async {
      tester.view.physicalSize = const Size(360, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: ProfileScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check disclaimer
      expect(find.text('Family Profile'), findsOneWidget);
      expect(
          find.textContaining('Profile changes remain local'), findsOneWidget);
      expect(find.text('Household Demographics'), findsOneWidget);

      // Empty local profiles begin with no household members.
      expect(find.text('0'), findsNWidgets(3));

      // Find the add icon for adults (first add_circle_outline)
      final addAdult = find.byIcon(Icons.add_circle_outline).first;
      await tester.tap(addAdult);
      await tester.pumpAndSettle();

      // The first adult can be added without assuming household size.
      expect(find.text('1'), findsOneWidget);

      // Vulnerability preferences default to off until selected.
      final switches = find.byType(Switch);
      expect(switches, findsNWidgets(2));
      final asthmaSwitch = switches.at(1);
      expect(tester.widget<Switch>(asthmaSwitch).value, isFalse);

      // Enable the respiratory-vulnerability guidance.
      await tester.drag(find.byType(ListView), const Offset(0, -180));
      await tester.pumpAndSettle();
      await tester.tap(asthmaSwitch);
      await tester.pumpAndSettle();
      expect(tester.widget<Switch>(asthmaSwitch).value, isTrue);

      // Tap to toggle back on
      await tester.tap(asthmaSwitch);
      await tester.pumpAndSettle();
      expect(tester.widget<Switch>(asthmaSwitch).value, isFalse);
    });

    testWidgets(
        'Responsive shell adapts mobile, tablet, desktop, and wide layouts',
        (tester) async {
      // Small and regular mobile widths should retain bottom navigation.
      tester.view.physicalSize = const Size(320, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const ProviderScope(child: SmogShieldApp()));
      await tester.pumpAndSettle();
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(tester.takeException(), isNull);

      tester.view.physicalSize = const Size(360, 720);
      await tester.pumpWidget(const ProviderScope(child: SmogShieldApp()));
      await tester.pumpAndSettle();

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
      expect(tester.takeException(), isNull);

      // Tablet uses a navigation rail.
      tester.view.physicalSize = const Size(768, 800);
      await tester.pumpWidget(const ProviderScope(child: SmogShieldApp()));
      await tester.pumpAndSettle();
      expect(find.byType(NavigationRail), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Desktop uses a persistent sidebar.
      tester.view.physicalSize = const Size(1280, 800);
      await tester.pumpWidget(const ProviderScope(child: SmogShieldApp()));
      await tester.pumpAndSettle();

      expect(find.byType(NavigationRail), findsNothing);
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.text('Settings'), findsOneWidget);
      expect(tester.takeException(), isNull);

      tester.view.physicalSize = const Size(1920, 1080);
      await tester.pumpWidget(const ProviderScope(child: SmogShieldApp()));
      await tester.pumpAndSettle();
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.text('Settings'), findsOneWidget);
      expect(tester.takeException(), isNull);

      tester.view.physicalSize = const Size(1280, 420);
      await tester.pumpWidget(const ProviderScope(child: SmogShieldApp()));
      await tester.pumpAndSettle();
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
      expect(tester.takeException(), isNull);

      tester.view.physicalSize = const Size(768, 600);
      await tester.pumpWidget(const ProviderScope(child: SmogShieldApp()));
      await tester.pumpAndSettle();
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
