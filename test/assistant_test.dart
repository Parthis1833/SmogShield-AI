import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:smogshield_ai/core/models/assistant_message.dart';
import 'package:smogshield_ai/core/services/gemini_service.dart';

class _RecordingClient extends http.BaseClient {
  _RecordingClient(this.responseBody, this.statusCode);

  final Map<String, dynamic> responseBody;
  final int statusCode;
  late http.BaseRequest request;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    this.request = request;
    return http.StreamedResponse(
      Stream.value(utf8.encode(jsonEncode(responseBody))),
      statusCode,
      headers: const {'content-type': 'application/json'},
    );
  }
}

void main() {
  group('Simulated Gemini Service Tests (Rule-Based Phase 1)', () {
    final service = SimulatedGeminiService();

    test('Answers exercise queries with outdoor safety warning', () async {
      final reply = await service.askQuestion('Can I go jogging this morning?');
      expect(reply.isUser, isFalse);
      expect(reply.text.toLowerCase(), contains('exercise'));
      expect(reply.text.toLowerCase(), contains('hepa'));
      expect(reply.disclaimer, isNotNull);
      expect(reply.disclaimer?.toLowerCase(), contains('not medical advice'));
      expect(reply.engine, contains('simulated'));
      expect(reply.isMock, isTrue);
    });

    test('Answers purifier queries with HEPA advice', () async {
      final reply = await service
          .askQuestion('Which air purifier is best for winter smog?');
      expect(reply.text, contains('HEPA'));
      expect(reply.text, contains('CADR'));
      expect(reply.relatedSuggestions, isNotEmpty);
      expect(reply.disclaimer, isNotNull);
    });

    test(
        'Answers commute questions with low-emission alternatives and exposure notes',
        () async {
      final reply = await service
          .askQuestion('How should I commute to work in heavy smog?');
      expect(reply.text.toLowerCase(), contains('metro'));
      expect(reply.text.toLowerCase(), contains('co₂e'));
      expect(reply.text.toLowerCase(), contains('recirculation'));
      expect(reply.relatedSuggestions, isNotEmpty);
    });

    test('Answers mask queries with certified respirator specifications',
        () async {
      final reply =
          await service.askQuestion('Should children wear an N95 mask?');
      expect(reply.text, contains('N95'));
      expect(reply.text.toLowerCase(), contains('children'));
      expect(reply.disclaimer, isNotNull);
    });

    test('Answers ventilation queries with inversion cycle guidance', () async {
      final reply =
          await service.askQuestion('When is it safe to ventilate windows?');
      expect(reply.text.toLowerCase(), contains('inversion'));
      expect(reply.text.toLowerCase(), contains('solar'));
    });

    test('Handles blank input safely without medical claims or crashes',
        () async {
      final reply = await service.askQuestion('   ');
      expect(reply.text.toLowerCase(), contains('please type a question'));
      expect(reply.relatedSuggestions, isNotEmpty);
    });

    test('Does not make medical diagnosis claims in any rule-based response',
        () async {
      final reply = await service
          .askQuestion('I feel breathless, what medicine should I take?');
      expect(reply.disclaimer?.toLowerCase(), contains('not medical advice'));
      expect(reply.text.toLowerCase(), isNot(contains('prescribe')));
      expect(reply.text.toLowerCase(), isNot(contains('diagnosis')));
    });
  });

  group('Assistant Typed Models & Serialization (FastAPI Compatibility)', () {
    test('AssistantMessage.fromJson parses FastAPI backend schema', () {
      final fastApiPayload = {
        'answer': 'Use mechanical HEPA filtration in sealed rooms.',
        'engine': 'gemini-1.5-flash-simulated',
        'is_mock': true,
        'disclaimer': 'Non-diagnostic environmental information.',
        'suggested_prompts': ['How to check filter CADR?'],
        'citations': ['ISO 29463 Standard'],
      };

      final message = AssistantMessage.fromJson(fastApiPayload);
      expect(message.text, 'Use mechanical HEPA filtration in sealed rooms.');
      expect(message.engine, 'gemini-1.5-flash-simulated');
      expect(message.isMock, isTrue);
      expect(message.relatedSuggestions, contains('How to check filter CADR?'));
      expect(message.citations, contains('ISO 29463 Standard'));
      expect(message.isUser, isFalse);
    });

    test('AssistantRequest serializes to FastAPI Question schema', () {
      const request = AssistantRequest(
        message: 'How to seal windows?',
        city: 'New Delhi',
        hasChildren: true,
        hasRespiratoryCondition: false,
      );

      final json = request.toJson();
      expect(json['message'], 'How to seal windows?');
      expect(json['city'], 'New Delhi');
      expect(json['has_children'], isTrue);
      expect(json['has_respiratory_condition'], isFalse);
    });
  });

  test(
      'FastAPI client sends Firebase auth, history, location and conversation ID',
      () async {
    final client = _RecordingClient({
      'message': 'Recent PM2.5 observations were provided.',
      'answer': 'Recent PM2.5 observations were provided.',
      'conversation_id': 'conversation-1',
      'model': 'gemini-test',
      'source_status': 'available_fresh',
      'engine': 'gemini',
      'is_mock': false,
      'disclaimer': 'Environmental guidance only.',
    }, 200);
    final service = FastApiGeminiService(
      baseUrl: 'http://test.local',
      client: client,
      idTokenProvider: () async => 'firebase-id-token',
    );

    final reply = await service.askQuestion(
      'Explain those measurements.',
      conversationId: 'conversation-1',
      history: [
        AssistantMessage.user('What is PM2.5?'),
        AssistantMessage.assistant(text: 'Fine particulate matter.'),
      ],
      selectedLocation: {
        'latitude': 18.52,
        'longitude': 73.85,
        'city': 'Pune',
      },
    );

    expect(client.request.url.path, '/api/v1/assistant');
    expect(client.request.headers['Authorization'], 'Bearer firebase-id-token');
    final body = jsonDecode((client.request as http.Request).body)
        as Map<String, dynamic>;
    expect(body['conversation_id'], 'conversation-1');
    expect(body['history'], [
      {'role': 'user', 'content': 'What is PM2.5?'},
      {'role': 'assistant', 'content': 'Fine particulate matter.'},
    ]);
    expect((body['selected_location'] as Map<String, dynamic>)['city'], 'Pune');
    expect(reply.text, 'Recent PM2.5 observations were provided.');
    expect(reply.modelName, 'gemini-test');
    expect(reply.sourceStatus, 'available_fresh');
    expect(reply.isMock, isFalse);
  });

  test(
      'FastAPI client surfaces model service failures without a fallback answer',
      () async {
    final service = FastApiGeminiService(
      baseUrl: 'http://test.local',
      client: _RecordingClient(
          {'detail': 'Gemini quota is temporarily unavailable.'}, 503),
      idTokenProvider: () async => 'firebase-id-token',
    );

    await expectLater(
      service.askQuestion('What is PM2.5?'),
      throwsA(
        isA<GeminiServiceUnavailable>().having(
          (error) => error.message,
          'message',
          contains('quota'),
        ),
      ),
    );
  });
}
