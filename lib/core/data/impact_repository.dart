import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/impact_action.dart';
import '../services/firebase_service.dart';

class ImpactRepositoryException implements Exception {
  const ImpactRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ImpactData {
  const ImpactData({
    required this.benchmarks,
    required this.actions,
    required this.disclaimer,
  });

  final List<ImpactBenchmark> benchmarks;
  final List<ImpactAction> actions;
  final String disclaimer;
}

class ImpactRepository {
  ImpactRepository({
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

  Future<ImpactData> load() async {
    final values = await Future.wait([
      _get('/api/v1/impact/benchmarks', authenticated: false),
      _get('/api/v1/impact/actions'),
    ]);
    final benchmarksBody = values[0];
    final actionsBody = values[1];
    final rawBenchmarks = benchmarksBody['benchmarks'] as List;
    final rawActions = actionsBody['actions'] as List;
    return ImpactData(
      benchmarks: rawBenchmarks
          .map((item) =>
              ImpactBenchmark.fromJson(item as Map<String, dynamic>))
          .toList(),
      actions: rawActions
          .map((item) => ImpactAction.fromJson(item as Map<String, dynamic>))
          .toList(),
      disclaimer: benchmarksBody['disclaimer'] as String,
    );
  }

  Future<ImpactAction> record(ImpactActionRequest request) async {
    final token = await _idTokenProvider();
    final body = await _send(
      '/api/v1/impact/actions',
      method: 'POST',
      token: token,
      payload: request.toJson(),
    );
    return ImpactAction.fromJson(body);
  }

  Future<Map<String, dynamic>> _get(
    String path, {
    bool authenticated = true,
  }) async {
    final token = authenticated ? await _idTokenProvider() : null;
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl$path'),
        headers: {
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));
      return _parseResponse(response);
    } on ImpactRepositoryException {
      rethrow;
    } on TimeoutException {
      throw const ImpactRepositoryException(
        'Impact service timed out. Try again.',
      );
    } on http.ClientException catch (error) {
      throw ImpactRepositoryException(
        'Could not connect to impact service: ${error.message}',
      );
    } on FormatException catch (error) {
      throw ImpactRepositoryException(
        'Could not read impact response: ${error.message}',
      );
    } on StateError catch (error) {
      throw ImpactRepositoryException(error.message.toString());
    }
  }

  Future<Map<String, dynamic>> _send(
    String path, {
    required String method,
    required String token,
    required Map<String, Object> payload,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$path');
      final response = await _client
          .post(
            uri,
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 15));
      return _parseResponse(response);
    } on ImpactRepositoryException {
      rethrow;
    } on TimeoutException {
      throw const ImpactRepositoryException(
        'Could not save your impact action before the request timed out.',
      );
    } on http.ClientException catch (error) {
      throw ImpactRepositoryException(
        'Could not connect to impact service: ${error.message}',
      );
    } on FormatException catch (error) {
      throw ImpactRepositoryException(
        'Could not read impact response: ${error.message}',
      );
    }
  }

  Map<String, dynamic> _parseResponse(http.Response response) {
    final decoded = jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final detail =
          decoded is Map<String, dynamic> ? decoded['detail']?.toString() : null;
      throw ImpactRepositoryException(
        detail ?? 'Impact service returned HTTP ${response.statusCode}.',
      );
    }
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Impact service returned invalid data.');
    }
    return decoded;
  }
}

final impactRepositoryProvider = Provider<ImpactRepository>(
  (ref) => ImpactRepository(
    idTokenProvider: () => ref.read(authServiceProvider).getIdToken(),
  ),
);

final impactDataProvider = FutureProvider<ImpactData>(
  (ref) => ref.watch(impactRepositoryProvider).load(),
);
