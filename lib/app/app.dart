import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/theme_controller.dart';
import '../core/services/firebase_service.dart';
import '../core/widgets/responsive_scaffold.dart';
import '../features/assistant/assistant_screen.dart';
import '../features/auth/auth_screen.dart';
import '../features/community/community_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/impact/impact_screen.dart';
import '../features/indoor_air/indoor_air_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/routine/routine_screen.dart';
import '../features/settings/settings_screen.dart';

final initialLocationProvider = Provider<String>((ref) => '/login');

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authServiceProvider);
  final authRefresh = _AuthStateRefresh(auth.authStateChanges);
  ref.onDispose(authRefresh.dispose);

  return GoRouter(
    initialLocation: ref.watch(initialLocationProvider),
    refreshListenable: authRefresh,
    redirect: (context, state) {
      final isAuthRoute =
          state.uri.path == '/login' || state.uri.path == '/register';
      final isSignedIn = auth.isAuthenticated && !auth.isAnonymous;

      if (!isSignedIn && !isAuthRoute) {
        return '/login?from=${Uri.encodeComponent(state.uri.toString())}';
      }

      if (isSignedIn && isAuthRoute) {
        final destination = state.uri.queryParameters['from'];
        if (destination != null &&
            destination.startsWith('/') &&
            !destination.startsWith('//')) {
          return destination;
        }
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (_, __) => const RegistrationScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(
          location: state.uri.path,
          child: child,
        ),
        routes: [
          GoRoute(path: '/', builder: (_, __) => const DashboardScreen()),
          GoRoute(
              path: '/assistant', builder: (_, __) => const AssistantScreen()),
          GoRoute(path: '/routine', builder: (_, __) => const RoutineScreen()),
          GoRoute(path: '/impact', builder: (_, __) => const ImpactScreen()),
          GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
          GoRoute(
              path: '/indoor-air', builder: (_, __) => const IndoorAirScreen()),
          GoRoute(
              path: '/community', builder: (_, __) => const CommunityScreen()),
          GoRoute(
              path: '/settings', builder: (_, __) => const SettingsScreen()),
        ],
      ),
    ],
  );
});

class _AuthStateRefresh extends ChangeNotifier {
  _AuthStateRefresh(Stream<Object?> authStateChanges) {
    _subscription = authStateChanges.listen((_) => notifyListeners());
  }

  late final StreamSubscription<Object?> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

class SmogShieldApp extends ConsumerWidget {
  const SmogShieldApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'SmogShield AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: ref.watch(routerProvider),
    );
  }
}

class AppShell extends StatelessWidget {
  const AppShell({required this.child, required this.location, super.key});

  final Widget child;
  final String location;

  @override
  Widget build(BuildContext context) => ResponsiveScaffold(
        location: location,
        onNavigate: (path) => context.go(path),
        child: child,
      );
}
