import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/indoor_tip.dart';

class IndoorTipRepositoryException implements Exception {
  const IndoorTipRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}

class IndoorTipRepository {
  IndoorTipRepository({String? baseUrl, http.Client? client})
      : baseUrl = baseUrl ?? AppConfig.apiBaseUrl,
        _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  Future<List<IndoorTip>> loadTips() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/api/v1/indoor-tips'),
        headers: const {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 15));
      final body = jsonDecode(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final detail =
            body is Map<String, dynamic> ? body['detail']?.toString() : null;
        throw IndoorTipRepositoryException(
          detail ?? 'Indoor guidance service returned HTTP ${response.statusCode}.',
        );
      }
      if (body is! List) {
        throw const FormatException(
          'Indoor guidance service returned invalid data.',
        );
      }
      return body
          .map((item) => IndoorTip.fromJson(item as Map<String, dynamic>))
          .toList();
    } on IndoorTipRepositoryException {
      rethrow;
    } on TimeoutException {
      throw const IndoorTipRepositoryException(
        'Indoor guidance request timed out. Try again.',
      );
    } on http.ClientException catch (error) {
      throw IndoorTipRepositoryException(
        'Could not connect to indoor guidance service: ${error.message}',
      );
    } on FormatException catch (error) {
      throw IndoorTipRepositoryException(
        'Could not read indoor guidance response: ${error.message}',
      );
    }
  }
}

final indoorTipRepositoryProvider = Provider<IndoorTipRepository>(
  (ref) => IndoorTipRepository(),
);

final indoorTipsProvider = FutureProvider<List<IndoorTip>>(
  (ref) => ref.watch(indoorTipRepositoryProvider).loadTips(),
);
