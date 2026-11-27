import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smogshield_ai/core/config/app_config.dart';
import 'package:smogshield_ai/core/services/gemini_service.dart';

void main() {
  test('uses the local FastAPI endpoints for Web and Android emulator', () {
    expect(AppConfig.apiBaseUrlWeb, 'http://127.0.0.1:8000');
    expect(AppConfig.apiBaseUrlAndroid, 'http://10.0.2.2:8000');
  });

  test('selects the Web and Android backend URLs independently', () {
    expect(
      AppConfig.apiBaseUrlFor(
        isWeb: true,
        targetPlatform: TargetPlatform.android,
      ),
      AppConfig.apiBaseUrlWeb,
    );
    expect(
      AppConfig.apiBaseUrlFor(
        isWeb: false,
        targetPlatform: TargetPlatform.android,
      ),
      AppConfig.apiBaseUrlAndroid,
    );
    expect(
      AppConfig.apiBaseUrlFor(
        isWeb: false,
        targetPlatform: TargetPlatform.iOS,
      ),
      AppConfig.apiBaseUrlWeb,
    );
  });

  test('simulated assistant is available only in explicit demo mode', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final service = container.read(geminiServiceProvider);
    if (const bool.fromEnvironment('DEMO_MODE')) {
      expect(service, isA<SimulatedGeminiService>());
    } else {
      expect(service, isA<FastApiGeminiService>());
    }
  });
}
