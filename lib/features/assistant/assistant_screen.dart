import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/data/family_members_repository.dart';
import '../../core/data/location_search_repository.dart';
import '../../core/data/family_profile_provider.dart';
import '../../core/models/assistant_message.dart';
import '../../core/services/gemini_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/section_card.dart';

class AssistantScreen extends ConsumerStatefulWidget {
  const AssistantScreen({super.key});

  @override
  ConsumerState<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends ConsumerState<AssistantScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final List<AssistantMessage> _history = [];
  String? _conversationId;
  bool _isLoading = false;

  final List<AssistantMessage> _messages = [
    AssistantMessage(
      id: 'welcome_1',
      text:
          'Ask about air-quality protection and the readings available for your selected location.',
      isUser: false,
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      disclaimer: 'Environmental guidance only. Not a medical diagnosis.',
      relatedSuggestions: const [
        'What do the current measurements mean?',
        'What outdoor precautions should I consider?',
        'How can I reduce indoor particle exposure?',
      ],
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  Future<void> _sendMessage({
    String? presetText,
    AssistantMessage? retryUserMessage,
    String? retryErrorId,
  }) async {
    final text = (presetText ?? _controller.text).trim();
    // Empty-input validation: never submit empty or whitespace-only messages
    if (text.isEmpty || _isLoading) return;

    final userMessage = retryUserMessage ?? AssistantMessage.user(text);
    final requestHistory = List<AssistantMessage>.of(_history);

    setState(() {
      if (retryErrorId != null) {
        _messages.removeWhere((message) => message.id == retryErrorId);
      }
      if (retryUserMessage == null) {
        _messages.add(userMessage);
      }
      _isLoading = true;
      if (presetText == null) {
        _controller.clear();
      }
    });
    _scrollToBottom();

    final geminiService = ref.read(geminiServiceProvider);
    final profile = ref.read(familyProfileProvider);
    final selectedLocation = ref.read(selectedLocationProvider);
    final familyMembers = ref.read(familyMembersStreamProvider).value ?? [];
    final hasAnyAsthma = familyMembers.any((m) => m.health.hasAsthma);
    final hasAnyRespiratory =
        hasAnyAsthma || familyMembers.any((m) => m.health.otherRespiratoryConditions.isNotEmpty);
    final hasChildren =
        profile.childrenCount > 0 || familyMembers.any((m) => m.isChild);

    final familySummary = familyMembers.map((m) => {
      'name': m.name,
      'relationship': m.relationship,
      'age': m.age,
      'has_asthma': m.health.hasAsthma,
      'asthma_severity': m.health.asthmaSeverity,
      'other_respiratory_conditions': m.health.otherRespiratoryConditions,
      'other_health_conditions': m.health.otherHealthConditions,
      'is_vulnerable': m.isVulnerable,
    }).toList();

    final cityContext =
        selectedLocation == null || selectedLocation.city != profile.city
            ? profile.city
            : [
                selectedLocation.city,
                selectedLocation.state,
                selectedLocation.country,
              ].whereType<String>().where((part) => part.isNotEmpty).join(', ');
    AssistantMessage reply;
    try {
      reply = await geminiService.askQuestion(
        text,
        userContext: {
          'city': cityContext,
          'has_children': hasChildren,
          'has_respiratory_condition': profile.hasVulnerableMember || hasAnyRespiratory,
          'primary_commute_mode': profile.primaryCommuteMode,
          'air_purification_setup': profile.airPurificationSetup,
          'family_members': familySummary,
        },
        selectedLocation: selectedLocation?.toJson(),
        history: requestHistory,
        conversationId: _conversationId,
      );
    } on GeminiServiceUnavailable catch (error) {
      reply = AssistantMessage(
        id: 'ast_error_${DateTime.now().millisecondsSinceEpoch}',
        text: error.message,
        isUser: false,
        timestamp: DateTime.now(),
        engine: 'unavailable',
        disclaimer: 'No response was generated. You can retry this question.',
        retryPrompt: text,
      );
    }

    if (mounted) {
      setState(() {
        _messages.add(reply);
        _isLoading = false;
        if (reply.engine != 'unavailable') {
          _history
            ..add(userMessage)
            ..add(reply);
          _conversationId = reply.conversationId ?? _conversationId;
        }
      });
      _scrollToBottom();
      _focusNode.requestFocus();
    }
  }

  void _retryMessage(AssistantMessage errorMessage) {
    final prompt = errorMessage.retryPrompt;
    if (prompt == null || _isLoading) return;
    final errorIndex = _messages.indexOf(errorMessage);
    final previous = errorIndex > 0 ? _messages[errorIndex - 1] : null;
    final userMessage =
        previous != null && previous.isUser && previous.text == prompt
            ? previous
            : null;
    _sendMessage(
      presetText: prompt,
      retryUserMessage: userMessage,
      retryErrorId: errorMessage.id,
    );
  }

  void _resetConversation() {
    setState(() {
      _messages.removeRange(1, _messages.length);
      _history.clear();
      _conversationId = null;
      _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AerisTokens>() ??
        AerisTokens.forBrightness(theme.brightness);
    final isSendEnabled = _controller.text.trim().isNotEmpty && !_isLoading;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 960),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            children: [
              // Screen Header
              PageHeading(
                'AI Assistant',
                'Gemini guidance grounded in your selected location',
                trailing: IconButton(
                  tooltip: 'Reset Conversation',
                  icon: const Icon(Icons.refresh),
                  onPressed: _isLoading ? null : _resetConversation,
                ),
              ),

              Container(
                key: const Key('assistant_service_banner'),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.colorScheme.outline),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Responses are generated by Gemini through the SmogShield backend. Environmental guidance only.',
                        style:
                            theme.textTheme.bodySmall?.copyWith(height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),

              // Chat Messages ListView
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: _messages.length + (_isLoading ? 1 : 0),
                  itemBuilder: (context, i) {
                    if (i == _messages.length && _isLoading) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: theme.colorScheme.outline,
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 14,
                                  height: 14,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'Waiting for Gemini...',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    final msg = _messages[i];
                    return _MessageBubble(
                      message: msg,
                      onSuggestionTap: (suggestion) =>
                          _sendMessage(presetText: suggestion),
                      onRetry: msg.retryPrompt == null
                          ? null
                          : () => _retryMessage(msg),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),

              // Input Bar with keyboard submission and empty-input validation
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.outline,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        maxLength: 1000,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                        decoration: InputDecoration(
                          hintText: 'Ask about air quality, filters, masks...',
                          hintStyle: theme.textTheme.bodyMedium?.copyWith(
                            color: tokens.mutedText,
                          ),
                          border: InputBorder.none,
                          counterText: '',
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          suffixIcon: _controller.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    _controller.clear();
                                    setState(() {});
                                  },
                                )
                              : null,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton.filled(
                      key: const Key('assistant_send_button'),
                      onPressed: isSendEnabled ? () => _sendMessage() : null,
                      icon: const Icon(Icons.send, size: 18),
                      tooltip: 'Send',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final AssistantMessage message;
  final ValueChanged<String>? onSuggestionTap;
  final VoidCallback? onRetry;

  const _MessageBubble({
    required this.message,
    this.onSuggestionTap,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.isUser;
    final tokens = theme.extension<AerisTokens>() ??
        AerisTokens.forBrightness(theme.brightness);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser && message.engine != null) ...[
                CircleAvatar(
                  radius: 15,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Icon(Icons.auto_awesome,
                      size: 16, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 620),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isUser
                        ? (theme.brightness == Brightness.dark
                            ? tokens.atmosphericSurface
                            : theme.colorScheme.primaryContainer)
                        : theme.colorScheme.surface,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isUser ? 16 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 16),
                    ),
                    border: Border.all(
                      color: isUser
                          ? Colors.transparent
                          : theme.colorScheme.outline,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header tag for assistant message
                      if (!isUser && message.engine != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            message.engine == 'unavailable'
                                ? 'Service unavailable'
                                : message.modelName ?? 'Gemini',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                      ],

                      // Message Body
                      Text(
                        message.text,
                        style:
                            theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                      ),

                      if (onRetry != null) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            if (onRetry != null)
                              TextButton.icon(
                                onPressed: onRetry,
                                icon: const Icon(Icons.refresh, size: 16),
                                label: const Text('Retry'),
                              ),
                          ],
                        ),
                      ],

                      // Citations if present
                      if (message.citations.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Scientific references: ${message.citations.join(" • ")}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],

                      // Disclaimer if present
                      if (message.disclaimer != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.shield_outlined,
                              size: 16,
                              color: tokens.warning,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                message.disclaimer!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontStyle: FontStyle.italic,
                                  color: tokens.warning,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Text(
                          message.formattedTime,
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: tokens.mutedText),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (isUser) ...[
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 15,
                  backgroundColor:
                      theme.colorScheme.primary.withValues(alpha: 0.2),
                  child: Icon(Icons.person,
                      size: 16, color: theme.colorScheme.primary),
                ),
              ],
            ],
          ),

          // Clickable suggestion chips
          if (message.relatedSuggestions.isNotEmpty) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 38),
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: message.relatedSuggestions.map((s) {
                  return ActionChip(
                    avatar: Icon(Icons.arrow_forward,
                        size: 14, color: theme.colorScheme.primary),
                    label: Text(s, style: theme.textTheme.labelMedium),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    onPressed: () => onSuggestionTap?.call(s),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
