import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smogshield_ai/app/app.dart';
import 'package:smogshield_ai/core/services/firebase_service.dart';

void main() {
  testWidgets('Unauthenticated users are redirected to login', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [initialLocationProvider.overrideWithValue('/settings')],
        child: const SmogShieldApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.byKey(const Key('auth_google_sign_in')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Authenticated users can open a requested screen',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          initialLocationProvider.overrideWithValue('/settings'),
          authServiceProvider.overrideWithValue(_AuthenticatedTestAuth()),
        ],
        child: const SmogShieldApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Mobile More menu keeps Community reachable', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(_authenticatedApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();

    final menuItems = find.byType(PopupMenuItem<String>);
    expect(menuItems, findsNWidgets(3));
    await tester.tap(menuItems.at(1));
    await tester.pumpAndSettle();
    expect(find.text('Community Shield'), findsOneWidget);
  });

  testWidgets('Bottom navigation switches seamlessly between primary tabs',
      (tester) async {
    tester.view.physicalSize = const Size(500, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(_authenticatedApp());
    await tester.pumpAndSettle();

    // Starts on Dashboard
    expect(find.text('SmogShield AI'), findsOneWidget);
    expect(find.text('DEMO DATA — NOT LIVE'), findsOneWidget);

    // Tap AI Assistant tab in bottom navigation
    final navBar = find.byType(NavigationBar);
    final aiTab =
        find.descendant(of: navBar, matching: find.byIcon(Icons.auto_awesome));
    await tester.tap(aiTab);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull,
        reason: 'AI view should not overflow');
    expect(find.text('AI Assistant'), findsOneWidget);
    expect(
        find.text('Ask about air quality, filters, masks...'), findsOneWidget);

    // Tap Routine tab in bottom navigation
    final routineTab =
        find.descendant(of: navBar, matching: find.byIcon(Icons.event_note));
    await tester.tap(routineTab);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull,
        reason: 'Routine view should not overflow');
    expect(find.text('Daily Routine'), findsOneWidget);
    expect(find.text('DEMO ROUTINE • NOT PERSONALIZED'), findsOneWidget);

    // Tap Impact tab in bottom navigation
    final impactTab =
        find.descendant(of: navBar, matching: find.byIcon(Icons.eco_outlined));
    await tester.tap(impactTab);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull,
        reason: 'Impact view should not overflow');
    expect(find.text('Your Impact'), findsOneWidget);
    expect(find.text('CRITICAL SAFETY DISTINCTION'), findsOneWidget);

    // Tap Profile tab in bottom navigation
    final profileTab = find.descendant(
        of: navBar, matching: find.byIcon(Icons.person_outline));
    await tester.tap(profileTab);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull,
        reason: 'Family view should not overflow');
    expect(find.text('Family Profile'), findsOneWidget);
    expect(find.text('Household Demographics'), findsOneWidget);
  });
}

Widget _authenticatedApp() => ProviderScope(
      overrides: [
        authServiceProvider.overrideWithValue(_AuthenticatedTestAuth()),
      ],
      child: const SmogShieldApp(),
    );

class _AuthenticatedTestAuth implements AuthService {
  @override
  String? get currentUserDisplayName => 'Test User';

  @override
  String? get currentUserEmail => 'test@example.com';

  @override
  String? get currentUserId => 'test-user';

  @override
  String? get currentUserPhotoUrl => null;

  @override
  Stream<String?> get emailChanges => Stream<String?>.value('test@example.com');

  @override
  Stream<User?> get authStateChanges => Stream<User?>.value(null);

  @override
  Future<String> getIdToken() async => 'test-token';

  @override
  bool get isAnonymous => false;

  @override
  bool get isAuthenticated => true;

  @override
  Future<void> registerWithEmailAndPassword({
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> signInAnonymously() async {}

  @override
  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async =>
      throw UnimplementedError();

  @override
  Future<UserCredential> signInWithGoogle() async => throw UnimplementedError();

  @override
  Future<void> signOut() async {}
}
