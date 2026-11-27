
import 'package:firebase_core/firebase_core.dart'
    show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

import 'core/config/app_config.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;

      default:
        throw UnsupportedError(
          'Firebase is not configured for this platform.',
        );
    }
  }

  static FirebaseOptions get web => FirebaseOptions(
        apiKey: _required(
          AppConfig.firebaseWebApiKey,
          'FIREBASE_WEB_API_KEY',
        ),
        appId: _required(
          AppConfig.firebaseWebAppId,
          'FIREBASE_WEB_APP_ID',
        ),
        messagingSenderId: _required(
          AppConfig.firebaseMessagingSenderId,
          'FIREBASE_MESSAGING_SENDER_ID',
        ),
        projectId: _required(
          AppConfig.firebaseProjectId,
          'FIREBASE_PROJECT_ID',
        ),
        authDomain: _optional(AppConfig.firebaseAuthDomain),
        storageBucket: _optional(AppConfig.firebaseStorageBucket),
        measurementId: _optional(AppConfig.firebaseMeasurementId),
      );

  static FirebaseOptions get android => FirebaseOptions(
        apiKey: _required(
          AppConfig.firebaseAndroidApiKey,
          'FIREBASE_ANDROID_API_KEY',
        ),
        appId: _required(
          AppConfig.firebaseAndroidAppId,
          'FIREBASE_ANDROID_APP_ID',
        ),
        messagingSenderId: _required(
          AppConfig.firebaseMessagingSenderId,
          'FIREBASE_MESSAGING_SENDER_ID',
        ),
        projectId: _required(
          AppConfig.firebaseProjectId,
          'FIREBASE_PROJECT_ID',
        ),
        storageBucket: _optional(AppConfig.firebaseStorageBucket),
      );

  static String _required(String value, String key) {
    if (value.isEmpty) {
      throw StateError(
        'Missing Firebase configuration: $key',
      );
    }

    return value;
  }

  static String? _optional(String value) {
    return value.isEmpty ? null : value;
  }
}
