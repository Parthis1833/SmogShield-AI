import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/assistant_message.dart';
import 'firebase_service.dart';

abstract class GeminiService {
  Future<AssistantMessage> askQuestion(
    String prompt, {
    Map<String, dynamic>? userContext,
    Map<String, dynamic>? selectedLocation,
    List<AssistantMessage> history = const [],
    String? conversationId,
  });
}

class GeminiServiceUnavailable implements Exception {
  const GeminiServiceUnavailable(this.message);

  final String message;

  @override
  String toString() => message;
}

class FastApiGeminiService implements GeminiService {
  FastApiGeminiService({
    String? baseUrl,
    http.Client? client,
    Future<String> Function()? idTokenProvider,
  })  : baseUrl = baseUrl ?? AppConfig.apiBaseUrl,
        _client = client ?? http.Client(),
        _idTokenProvider =
            idTokenProvider ?? FirebaseAuthService().getIdToken;

  final String baseUrl;
  final http.Client _client;
  final Future<String> Function() _idTokenProvider;

  List<Map<String, String>> _serializeHistory(
    List<AssistantMessage> history,
  ) {
    final serialized = <Map<String, String>>[];
    var totalCharacters = 0;
    for (final message in history.reversed) {
      if (serialized.length == 12 ||
          message.text.length > 6000 ||
          totalCharacters + message.text.length > 24000) {
        break;
      }
      serialized.insert(0, {
        'role': message.isUser ? 'user' : 'assistant',
        'content': message.text,
      });
      totalCharacters += message.text.length;
    }
    return serialized;
  }

  @override
  Future<AssistantMessage> askQuestion(
    String prompt, {
    Map<String, dynamic>? userContext,
    Map<String, dynamic>? selectedLocation,
    List<AssistantMessage> history = const [],
    String? conversationId,
  }) async {
    try {
      final idToken = await _idTokenProvider();
      final response = await _client
          .post(
            Uri.parse('$baseUrl/api/v1/assistant'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $idToken',
            },
            body: jsonEncode({
              'message': prompt,
              'conversation_id': conversationId,
              'history': _serializeHistory(history),
              'city': userContext?['city'],
              'has_children': userContext?['has_children'] ?? false,
              'has_respiratory_condition':
                  userContext?['has_respiratory_condition'] ?? false,
              'primary_commute_mode': userContext?['primary_commute_mode'],
              'air_purification_setup': userContext?['air_purification_setup'],
              'family_members': userContext?['family_members'] ?? [],
              'selected_location': selectedLocation,
            }),
          )
          .timeout(const Duration(seconds: 25));

      final decoded = jsonDecode(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final detail =
            decoded is Map<String, dynamic> ? decoded['detail']?.toString() : null;
        throw GeminiServiceUnavailable(
          detail ??
              'The Gemini assistant service returned HTTP ${response.statusCode}.',
        );
      }
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Gemini returned an invalid response.');
      }
      return AssistantMessage.fromJson(decoded);
    } on GeminiServiceUnavailable {
      rethrow;
    } on TimeoutException {
      throw const GeminiServiceUnavailable(
        'The SmogShield assistant timed out. Try again.',
      );
    } on http.ClientException {
      throw const GeminiServiceUnavailable(
        'Could not connect to the SmogShield backend. Gemini is unavailable.',
      );
    } on FirebaseAuthException catch (error) {
      throw GeminiServiceUnavailable(
        'Firebase authentication failed: ${error.message ?? error.code}',
      );
    } on StateError catch (error) {
      throw GeminiServiceUnavailable(error.message.toString());
    } on FormatException {
      throw const GeminiServiceUnavailable(
        'The SmogShield backend returned an invalid assistant response.',
      );
    }
  }
}

final geminiServiceProvider = Provider<GeminiService>((ref) {
  if (const bool.fromEnvironment('DEMO_MODE')) {
    return SimulatedGeminiService();
  }
  return FastApiGeminiService(
    idTokenProvider: () => ref.read(authServiceProvider).getIdToken(),
  );
});

class SimulatedGeminiService implements GeminiService {
  @override
  Future<AssistantMessage> askQuestion(
    String prompt, {
    Map<String, dynamic>? userContext,
    Map<String, dynamic>? selectedLocation,
    List<AssistantMessage> history = const [],
    String? conversationId,
  }) async {
    final trimmed = prompt.trim();
    if (trimmed.isEmpty) {
      return AssistantMessage(
        id: 'sim_empty',
        text: 'Please type a question regarding air quality or health precautions.',
        isUser: false,
        timestamp: DateTime(2026),
        engine: 'simulated-gemini',
        isMock: true,
        disclaimer: 'This guidance is educational and not medical advice.',
        relatedSuggestions: const [
          'Can I exercise outside today?',
          'Which air purifier should I buy?',
        ],
      );
    }

    final lower = trimmed.toLowerCase();
    String text;
    List<String> suggestions = [];

    if (lower.contains('jogging') || lower.contains('run') || lower.contains('exercise')) {
      text = 'During periods of high smog, avoid outdoor exercise. Instead, exercise indoors in a room with HEPA air filtration.';
      suggestions = ['Can I walk outside with a mask?', 'Indoor workout ideas'];
    } else if (lower.contains('purifier') || lower.contains('filter')) {
      text = 'Choose an air purifier equipped with a true HEPA filter and check the Clean Air Delivery Rate (CADR) for your room size.';
      suggestions = ['How to clean pre-filters?', 'What is CADR?'];
    } else if (lower.contains('commute') || lower.contains('travel') || lower.contains('work')) {
      text = 'When commuting in heavy smog, prefer public transit like the metro to lower personal CO₂e emissions. In private cars, turn on cabin air recirculation.';
      suggestions = ['Should I wear a mask while commuting?', 'Tips for cycling in smog'];
    } else if (lower.contains('mask') || lower.contains('n95') || lower.contains('respirator')) {
      text = 'Certified N95, KN95, or FFP2 respirators filter particulate matter. Ensure a snug fit; special pediatric-certified sizing is recommended for children.';
      suggestions = ['How often should I replace N95 masks?', 'Cloth masks vs N95'];
    } else if (lower.contains('ventilate') || lower.contains('window')) {
      text = 'Avoid opening windows during nocturnal thermal inversion periods. The best window for solar convective ventilation is typically between midday and early afternoon when dispersion improves.';
      suggestions = ['How to create cross ventilation?', 'Using air purifiers during smog'];
    } else {
      text = 'Air quality fluctuates based on environmental factors. Ensure high-efficiency filtration indoors and limit prolonged exposure outdoors.';
      suggestions = ['Check today AQI', 'Safety tips for sensitive groups'];
    }

    return AssistantMessage(
      id: 'sim_${DateTime.now().millisecondsSinceEpoch}',
      text: text,
      isUser: false,
      timestamp: DateTime.now(),
      engine: 'gemini-1.5-flash-simulated',
      isMock: true,
      disclaimer: 'Environmental recommendations only; this is not medical advice or clinical diagnosis.',
      relatedSuggestions: suggestions,
    );
  }
}
