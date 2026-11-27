import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/community_challenge.dart';
import '../services/firebase_service.dart';

class CommunityRepositoryException implements Exception {
  const CommunityRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}

class CommunityRepository {
  CommunityRepository({
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

  Future<List<CommunityChallenge>> loadChallenges() async {
    final response = await _request('GET', '/api/v1/community/challenges');
    final rawChallenges = response['challenges'] as List;
    return rawChallenges
        .map((item) =>
            CommunityChallenge.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<CommunityChallenge> createChallenge({
    required String title,
    required String description,
    required String goal,
    required int participantGoal,
    required DateTime endsAt,
  }) async {
    final response = await _request(
      'POST',
      '/api/v1/community/challenges',
      payload: {
        'title': title,
        'description': description,
        'goal': goal,
        'participant_goal': participantGoal,
        'ends_at': endsAt.toUtc().toIso8601String(),
      },
    );
    return CommunityChallenge.fromJson(response);
  }

  Future<void> joinChallenge(String id) async {
    await _request('POST', '/api/v1/community/challenges/$id/join');
  }

  Future<void> leaveChallenge(String id) async {
    await _request('DELETE', '/api/v1/community/challenges/$id/join');
  }

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, Object>? payload,
  }) async {
    try {
      final token = await _idTokenProvider();
      final uri = Uri.parse('$baseUrl$path');
      final headers = {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        if (payload != null) 'Content-Type': 'application/json',
      };
      final response = switch (method) {
        'GET' => await _client.get(uri, headers: headers),
        'POST' => await _client.post(
            uri,
            headers: headers,
            body: payload == null ? null : jsonEncode(payload),
          ),
        'DELETE' => await _client.delete(uri, headers: headers),
        _ => throw StateError('Unsupported request method: $method'),
      };
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final decoded = response.body.isEmpty ? null : jsonDecode(response.body);
        final detail =
            decoded is Map<String, dynamic> ? decoded['detail']?.toString() : null;
        throw CommunityRepositoryException(
          detail ?? 'Community service returned HTTP ${response.statusCode}.',
        );
      }
      if (response.body.isEmpty) return const {};
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Community service returned invalid data.');
      }
      return decoded;
    } on CommunityRepositoryException {
      rethrow;
    } on TimeoutException {
      throw const CommunityRepositoryException(
        'Community service request timed out. Try again.',
      );
    } on http.ClientException catch (error) {
      throw CommunityRepositoryException(
        'Could not connect to community service: ${error.message}',
      );
    } on FormatException catch (error) {
      throw CommunityRepositoryException(
        'Could not read community service response: ${error.message}',
      );
    } on StateError catch (error) {
      throw CommunityRepositoryException(error.message.toString());
    }
  }
}

final communityRepositoryProvider = Provider<CommunityRepository>(
  (ref) => CommunityRepository(
    idTokenProvider: () => ref.read(authServiceProvider).getIdToken(),
  ),
);

final communityChallengesProvider =
    FutureProvider<List<CommunityChallenge>>(
  (ref) => ref.watch(communityRepositoryProvider).loadChallenges(),
);
