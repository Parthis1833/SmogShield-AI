import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/config/app_config.dart';
import 'app/app.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'features/splash/splash_screen.dart';

Future<FirebaseApp>? _firebaseInitialization;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final requestedLocation =
      kIsWeb ? _webInitialLocation(Uri.base) : '/';

  // Show splash screen immediately.
  runApp(const SmogShieldLoadingApp());

  try {
    // STEP 1: Load centralized configuration.
    await AppConfig.load();

    // STEP 2: Generate Firebase options from AppConfig.
    final expectedOptions =
        DefaultFirebaseOptions.currentPlatform;

    // STEP 3: Initialize Firebase once and reuse the default app.
    final firebaseApp = await _initializeFirebase(expectedOptions);

    // STEP 4: Verify Firebase project configuration.
    if (firebaseApp.options.projectId != expectedOptions.projectId ||
        firebaseApp.options.appId != expectedOptions.appId) {
      throw StateError(
        'Firebase configuration mismatch. '
        'Check Firebase app IDs and project settings.',
      );
    }

    // STEP 5: Configure Firebase Auth language.
    try {
      final locale = PlatformDispatcher.instance.locale;
      final languageCode = locale.languageCode;

      await FirebaseAuth.instance.setLanguageCode(languageCode);

      debugPrint('Firebase Auth locale set to: $languageCode');
    } catch (localeError) {
      debugPrint('Could not set Firebase locale: $localeError');
    }

    debugPrint(
      'Firebase initialized for project: '
      '${firebaseApp.options.projectId}',
    );

    // STEP 6: Start application.
    runApp(
      ProviderScope(
        overrides: [
          initialLocationProvider.overrideWithValue(
            requestedLocation == '/'
                ? '/login'
                : requestedLocation,
          ),
        ],
        child: const SmogShieldApp(),
      ),
    );
  } catch (error, stackTrace) {
    debugPrint('Firebase startup error: $error');
    debugPrintStack(stackTrace: stackTrace);

    runApp(
      FirebaseInitializationErrorApp(
        message: _safeFirebaseError(error),
      ),
    );
  }
}

Future<FirebaseApp> _initializeFirebase(FirebaseOptions options) {
  return _firebaseInitialization ??= _createFirebaseApp(options);
}

Future<FirebaseApp> _createFirebaseApp(FirebaseOptions options) async {
  final existingApp = _defaultFirebaseApp;
  if (existingApp != null) return existingApp;

  try {
    return await Firebase.initializeApp(options: options);
  } on FirebaseException catch (error) {
    // Another startup path may have created the default app after the check
    // above. Reuse it instead of surfacing a duplicate-app error.
    if (error.code == 'duplicate-app') {
      final app = _defaultFirebaseApp;
      if (app != null) return app;
    }
    rethrow;
  }
}

FirebaseApp? get _defaultFirebaseApp {
  for (final app in Firebase.apps) {
    if (app.name == '[DEFAULT]') return app;
  }
  return null;
}

String _webInitialLocation(Uri uri) {
  if (uri.fragment.startsWith('/')) return uri.fragment;
  if (uri.path.startsWith('/') && uri.path != '/') return uri.path;
  return '/';
}

class SmogShieldLoadingApp extends StatelessWidget {
  const SmogShieldLoadingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmogShield AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: const SplashScreen(),
      onGenerateRoute: (settings) => MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => const SplashScreen(),
      ),
    );
  }
}

String _safeFirebaseError(Object error) {
  if (error is UnsupportedError) {
    return 'Firebase is not configured for this platform.';
  }

  if (error is FirebaseException) {
    return 'Firebase initialization failed (${error.code}). '
        'Please verify the platform configuration.';
  }

  if (error is StateError) {
    return 'Firebase configuration mismatch. '
        'Check the Firebase project and app IDs.';
  }

  return 'Unable to initialize Firebase. '
      'Check the application configuration and restart.';
}

class FirebaseInitializationErrorApp extends StatelessWidget {
  const FirebaseInitializationErrorApp({
    required this.message,
    super.key,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmogShield AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Firebase initialization failed',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    SelectableText(message),
                    const SizedBox(height: 16),
                    const Text(
                      'Verify Firebase configuration and '
                      'restart SmogShield AI.',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
