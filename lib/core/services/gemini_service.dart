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
  return FastApiGeminiService(
    idTokenProvider: () => ref.read(authServiceProvider).getIdToken(),
  );
});
