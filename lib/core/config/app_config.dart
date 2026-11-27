
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AppConfig {
  static Map<String, dynamic> _config = {};
  static bool _isLoaded = false;

  static Future<void> load() async {
    if (_isLoaded) return;

    try {
      final jsonString =
          await rootBundle.loadString('config/frontend.json');

      _config = json.decode(jsonString) as Map<String, dynamic>;

      debugPrint('AppConfig loaded from frontend.json');
    } catch (e) {
      debugPrint('AppConfig: Using compile-time configuration');
    } finally {
      _isLoaded = true;
    }
  }

  static String getString(
    String key, {
    String defaultValue = '',
  }) {
    final value = _config[key]?.toString();

    if (value != null && value.isNotEmpty) {
      return value;
    }

    return defaultValue;
  }

  // API URLs
  static const _webUrl = String.fromEnvironment(
    'API_BASE_URL_WEB',
    defaultValue: 'http://127.0.0.1:8000',
  );

  static const _androidUrl = String.fromEnvironment(
    'API_BASE_URL_ANDROID',
    defaultValue: 'http://10.0.2.2:8000',
  );

  static String get apiBaseUrlWeb =>
      getString('API_BASE_URL_WEB', defaultValue: _webUrl);

  static String get apiBaseUrlAndroid =>
      getString('API_BASE_URL_ANDROID', defaultValue: _androidUrl);

  static String get apiBaseUrl {
    if (kIsWeb) return apiBaseUrlWeb;

    if (defaultTargetPlatform == TargetPlatform.android) {
      return apiBaseUrlAndroid;
    }

    return apiBaseUrlWeb;
  }

  // Firebase configuration
  static String get firebaseProjectId => getString(
    'FIREBASE_PROJECT_ID',
    defaultValue: const String.fromEnvironment('FIREBASE_PROJECT_ID'),
  );

  static String get firebaseMessagingSenderId => getString(
    'FIREBASE_MESSAGING_SENDER_ID',
    defaultValue: const String.fromEnvironment(
      'FIREBASE_MESSAGING_SENDER_ID',
    ),
  );

  static String get firebaseStorageBucket => getString(
    'FIREBASE_STORAGE_BUCKET',
    defaultValue: const String.fromEnvironment(
      'FIREBASE_STORAGE_BUCKET',
    ),
  );

  static String get firebaseAuthDomain => getString(
    'FIREBASE_AUTH_DOMAIN',
    defaultValue: const String.fromEnvironment('FIREBASE_AUTH_DOMAIN'),
  );

  static String get firebaseMeasurementId => getString(
    'FIREBASE_MEASUREMENT_ID',
    defaultValue: const String.fromEnvironment(
      'FIREBASE_MEASUREMENT_ID',
    ),
  );

  // Firebase Web
  static String get firebaseWebApiKey => getString(
    'FIREBASE_WEB_API_KEY',
    defaultValue: const String.fromEnvironment('FIREBASE_WEB_API_KEY'),
  );

  static String get firebaseWebAppId => getString(
    'FIREBASE_WEB_APP_ID',
    defaultValue: const String.fromEnvironment('FIREBASE_WEB_APP_ID'),
  );

  // Firebase Android
  static String get firebaseAndroidApiKey => getString(
    'FIREBASE_ANDROID_API_KEY',
    defaultValue: const String.fromEnvironment(
      'FIREBASE_ANDROID_API_KEY',
    ),
  );

  static String get firebaseAndroidAppId => getString(
    'FIREBASE_ANDROID_APP_ID',
    defaultValue: const String.fromEnvironment(
      'FIREBASE_ANDROID_APP_ID',
    ),
  );

  static void validate() {
    final requiredValues = {
      'FIREBASE_PROJECT_ID': firebaseProjectId,
      'FIREBASE_MESSAGING_SENDER_ID': firebaseMessagingSenderId,
    };

    for (final entry in requiredValues.entries) {
      if (entry.value.isEmpty) {
        throw Exception('Missing configuration: ${entry.key}');
      }
    }
  }
}