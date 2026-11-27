import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:smogshield_ai/core/services/firebase_service.dart';
import 'package:smogshield_ai/features/auth/auth_screen.dart';

void main() {
  testWidgets('Login validates credentials before calling Firebase auth',
      (tester) async {
    final auth = _TestAuthService();
    await tester.pumpWidget(_authApp(auth, '/login'));

    await tester.ensureVisible(find.byKey(const Key('auth_submit')));
    await tester.tap(find.byKey(const Key('auth_submit')));
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid email address.'), findsOneWidget);
    expect(find.text('Use at least 6 characters.'), findsOneWidget);
    expect(auth.signInCount, 0);

    await tester.enterText(
        find.byKey(const Key('auth_email')), 'person@example.com');
    await tester.enterText(
        find.byKey(const Key('auth_password')), 'correct-horse');
    await tester.ensureVisible(find.byKey(const Key('auth_submit')));
    await tester.tap(find.byKey(const Key('auth_submit')));
    await tester.pumpAndSettle();

    expect(auth.signInCount, 1);
    expect(auth.lastEmail, 'person@example.com');
    expect(find.text('Profile destination'), findsOneWidget);
  });

  testWidgets('Registration validates confirmation and creates an account',
      (tester) async {
    final auth = _TestAuthService();
    await tester.pumpWidget(_authApp(auth, '/register'));

    await tester.enterText(
        find.byKey(const Key('auth_email')), 'new@example.com');
    await tester.enterText(
        find.byKey(const Key('auth_password')), 'correct-horse');
    await tester.enterText(
        find.byKey(const Key('auth_confirm_password')), 'different-password');
    await tester.ensureVisible(find.byKey(const Key('auth_submit')));
    await tester.tap(find.byKey(const Key('auth_submit')));
    await tester.pumpAndSettle();
    expect(find.text('Passwords do not match.'), findsOneWidget);
    expect(auth.registrationCount, 0);

    await tester.enterText(
        find.byKey(const Key('auth_confirm_password')), 'correct-horse');
    await tester.ensureVisible(find.byKey(const Key('auth_submit')));
    await tester.tap(find.byKey(const Key('auth_submit')));
    await tester.pumpAndSettle();

    expect(auth.registrationCount, 1);
    expect(auth.lastEmail, 'new@example.com');
    expect(find.text('Profile destination'), findsOneWidget);
  });

  testWidgets('Login offers Google sign-in and displays service errors',
      (tester) async {
    final auth = _TestAuthService();
    await tester.pumpWidget(_authApp(auth, '/login'));

    final googleButton = find.byKey(const Key('auth_google_sign_in'));
    expect(googleButton, findsOneWidget);
    await tester.tap(googleButton);
    await tester.pumpAndSettle();

    expect(auth.googleSignInCount, 1);
    expect(
        find.text(
            'Could not reach Firebase. Check your connection and try again.'),
        findsOneWidget);
  });
}

Widget _authApp(_TestAuthService auth, String initialLocation) {
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (_, __) => const RegistrationScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (_, __) => const Scaffold(body: Text('Profile destination')),
      ),
    ],
  );
  addTearDown(router.dispose);
  return ProviderScope(
    overrides: [authServiceProvider.overrideWithValue(auth)],
    child: MaterialApp.router(routerConfig: router),
  );
}

class _TestAuthService implements AuthService {
  int signInCount = 0;
  int googleSignInCount = 0;
  int registrationCount = 0;
  String? lastEmail;

  @override
  String? get currentUserEmail => null;

  @override
  String? get currentUserId => null;

  @override
  String? get currentUserDisplayName => null;

  @override
  String? get currentUserPhotoUrl => null;

  @override
  bool get isAnonymous => true;

  @override
  Stream<String?> get emailChanges => Stream<String?>.value(null);

  @override
  Stream<User?> get authStateChanges => Stream<User?>.value(null);

  @override
  bool get isAuthenticated => false;

  @override
  Future<String> getIdToken() async => 'test-token';

  @override
  Future<void> registerWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    registrationCount++;
    lastEmail = email;
  }

  @override
  Future<void> signInAnonymously() async {}

  @override
  Future<UserCredential> signInWithGoogle() async {
    googleSignInCount++;
    throw FirebaseAuthException(code: 'network-request-failed');
  }

  @override
  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    signInCount++;
    lastEmail = email;
  }

  @override
  Future<void> signOut() async {}
}
