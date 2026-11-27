import 'package:intl/intl.dart';

/// Strongly typed domain model for AI Assistant conversation messages.
///
/// Represents live FastAPI assistant responses and user messages.
class AssistantMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? engine;
  final String? disclaimer;
  final String? conversationId;
  final String? modelName;
  final String? sourceStatus;
  final String? retryPrompt;
  final List<String> relatedSuggestions;
  final List<String> citations;

  const AssistantMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.engine,
    this.disclaimer,
    this.conversationId,
    this.modelName,
    this.sourceStatus,
    this.retryPrompt,
    this.relatedSuggestions = const [],
    this.citations = const [],
  });

  /// Factory helper for creating outgoing user chat messages.
  factory AssistantMessage.user(String text) {
    return AssistantMessage(
      id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
      text: text.trim(),
      isUser: true,
      timestamp: DateTime.now(),
    );
  }

  /// Factory helper for creating assistant responses.
  factory AssistantMessage.assistant({
    required String text,
    String? engine,
    String? disclaimer,
    List<String> relatedSuggestions = const [],
    List<String> citations = const [],
  }) {
    return AssistantMessage(
      id: 'ast_${DateTime.now().millisecondsSinceEpoch}',
      text: text,
      isUser: false,
      timestamp: DateTime.now(),
      engine: engine,
      disclaimer: disclaimer,
      relatedSuggestions: relatedSuggestions,
      citations: citations,
    );
  }

  /// Formatted timestamp display (e.g. 08:30 AM).
  String get formattedTime => DateFormat('hh:mm a').format(timestamp);

  /// Deserialization supporting both local format and FastAPI `AssistantResponse`.
  factory AssistantMessage.fromJson(Map<String, dynamic> json) {
    final dynamic rawSuggestions = json['suggested_prompts'] ??
        json['related_suggestions'] ??
        json['relatedSuggestions'];
    final List<String> suggestions = rawSuggestions is List
        ? rawSuggestions.map((e) => e.toString()).toList()
        : const [];

    final dynamic rawCitations = json['citations'];
    final List<String> citations = rawCitations is List
        ? rawCitations.map((e) => e.toString()).toList()
        : const [];

    final parsedTimestamp = json['timestamp'] != null
        ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
        : DateTime.now();

    return AssistantMessage(
      id: json['id'] as String? ??
          'msg_${DateTime.now().millisecondsSinceEpoch}',
      text: json['text'] as String? ??
          json['message'] as String? ??
          json['answer'] as String? ??
          '',
      isUser: json['is_user'] as bool? ?? json['isUser'] as bool? ?? false,
      timestamp: parsedTimestamp,
      engine: json['engine'] as String?,
      disclaimer: json['disclaimer'] as String?,
      conversationId: json['conversation_id'] as String?,
      modelName: json['model'] as String?,
      sourceStatus: json['source_status'] as String?,
      relatedSuggestions: suggestions,
      citations: citations,
    );
  }

  /// Serialization compatible with backend JSON envelopes.
  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'answer': text,
        'is_user': isUser,
        'timestamp': timestamp.toIso8601String(),
        'engine': engine,
        'disclaimer': disclaimer,
        'conversation_id': conversationId,
        'model': modelName,
        'source_status': sourceStatus,
        'suggested_prompts': relatedSuggestions,
        'citations': citations,
      };

  AssistantMessage copyWith({
    String? id,
    String? text,
    bool? isUser,
    DateTime? timestamp,
    String? engine,
    String? disclaimer,
    String? conversationId,
    String? modelName,
    String? sourceStatus,
    String? retryPrompt,
    List<String>? relatedSuggestions,
    List<String>? citations,
  }) {
    return AssistantMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      engine: engine ?? this.engine,
      disclaimer: disclaimer ?? this.disclaimer,
      conversationId: conversationId ?? this.conversationId,
      modelName: modelName ?? this.modelName,
      sourceStatus: sourceStatus ?? this.sourceStatus,
      retryPrompt: retryPrompt ?? this.retryPrompt,
      relatedSuggestions: relatedSuggestions ?? this.relatedSuggestions,
      citations: citations ?? this.citations,
    );
  }
}

/// Request payload model mirroring FastAPI backend schema `Question`.
class AssistantRequest {
  final String message;
  final String city;
  final bool hasChildren;
  final bool hasRespiratoryCondition;

  const AssistantRequest({
    required this.message,
    this.city = 'New Delhi',
    this.hasChildren = false,
    this.hasRespiratoryCondition = false,
  });

  factory AssistantRequest.fromJson(Map<String, dynamic> json) {
    return AssistantRequest(
      message: json['message'] as String? ?? '',
      city: json['city'] as String? ?? 'New Delhi',
      hasChildren: json['has_children'] as bool? ??
          json['hasChildren'] as bool? ??
          false,
      hasRespiratoryCondition: json['has_respiratory_condition'] as bool? ??
          json['hasRespiratoryCondition'] as bool? ??
          false,
    );
  }

  Map<String, dynamic> toJson() => {
        'message': message,
        'city': city,
        'has_children': hasChildren,
        'has_respiratory_condition': hasRespiratoryCondition,
      };
}
