import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/community_repository.dart';
import '../../core/models/community_challenge.dart';
import '../../core/widgets/section_card.dart';

class CommunityScreen extends ConsumerStatefulWidget {
  const CommunityScreen({super.key});

  @override
  ConsumerState<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends ConsumerState<CommunityScreen> {
  String? _busyChallengeId;

  Future<void> _createChallenge() async {
    final draft = await showDialog<_ChallengeDraft>(
      context: context,
      builder: (context) => const _CreateChallengeDialog(),
    );
    if (draft == null || !mounted) return;
    try {
      await ref.read(communityRepositoryProvider).createChallenge(
            title: draft.title,
            description: draft.description,
            goal: draft.goal,
            participantGoal: draft.participantGoal,
            endsAt: draft.endsAt,
          );
      ref.invalidate(communityChallengesProvider);
    } catch (error) {
      if (mounted) _showError(error);
    }
  }

  Future<void> _toggleJoin(CommunityChallenge challenge) async {
    setState(() => _busyChallengeId = challenge.id);
    try {
      final repository = ref.read(communityRepositoryProvider);
      if (challenge.isJoined) {
        await repository.leaveChallenge(challenge.id);
      } else {
        await repository.joinChallenge(challenge.id);
      }
      ref.invalidate(communityChallengesProvider);
    } catch (error) {
      if (mounted) _showError(error);
    } finally {
      if (mounted) setState(() => _busyChallengeId = null);
    }
  }

  void _showError(Object error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error.toString())),
    );
  }

  @override
  Widget build(BuildContext context) {
    final challengesAsync = ref.watch(communityChallengesProvider);
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      children: [
        PageHeading(
          'Community Shield',
          'Create or join community clean-air challenges',
          trailing: IconButton(
            tooltip: 'Create a challenge',
            onPressed: _createChallenge,
            icon: const Icon(Icons.add),
          ),
        ),
        challengesAsync.when(
          loading: () => const SectionCard(
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => SectionCard(
            child: Column(
              children: [
                Text(
                  'Could not load community challenges: $error',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => ref.invalidate(communityChallengesProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try again'),
                ),
              ],
            ),
          ),
          data: (challenges) {
            if (challenges.isEmpty) {
              return SectionCard(
                child: Column(
                  children: [
                    const Icon(Icons.groups_outlined, size: 36),
                    const SizedBox(height: 8),
                    Text(
                      'No community challenges yet.',
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Create a challenge to invite others to take part.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }
            return Column(
              children: [
                for (final challenge in challenges)
                  _ChallengeCard(
                    challenge: challenge,
                    isBusy: _busyChallengeId == challenge.id,
                    onToggleJoin: () => _toggleJoin(challenge),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ChallengeDraft {
  const _ChallengeDraft({
    required this.title,
    required this.description,
    required this.goal,
    required this.participantGoal,
    required this.endsAt,
  });

  final String title;
  final String description;
  final String goal;
  final int participantGoal;
  final DateTime endsAt;
}

class _CreateChallengeDialog extends StatefulWidget {
  const _CreateChallengeDialog();

  @override
  State<_CreateChallengeDialog> createState() => _CreateChallengeDialogState();
}

class _CreateChallengeDialogState extends State<_CreateChallengeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _goal = TextEditingController();
  final _participantGoal = TextEditingController(text: '10');
  DateTime _endsAt = DateTime.now().add(const Duration(days: 30));

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _goal.dispose();
    _participantGoal.dispose();
    super.dispose();
  }

  Future<void> _chooseEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endsAt,
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) setState(() => _endsAt = date);
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(
      _ChallengeDraft(
        title: _title.text.trim(),
        description: _description.text.trim(),
        goal: _goal.text.trim(),
        participantGoal: int.parse(_participantGoal.text.trim()),
        endsAt: _endsAt,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create a community challenge'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _title,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (value) => (value?.trim().length ?? 0) < 3
                    ? 'Enter at least 3 characters.'
                    : null,
              ),
              TextFormField(
                controller: _description,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
                validator: (value) => (value?.trim().length ?? 0) < 10
                    ? 'Enter at least 10 characters.'
                    : null,
              ),
              TextFormField(
                controller: _goal,
                decoration: const InputDecoration(labelText: 'Challenge goal'),
                validator: (value) => (value?.trim().length ?? 0) < 3
                    ? 'Describe the goal.'
                    : null,
              ),
              TextFormField(
                controller: _participantGoal,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: 'Participant target'),
                validator: (value) {
                  final count = int.tryParse(value?.trim() ?? '');
                  return count == null || count < 2 || count > 1000000
                      ? 'Choose a target between 2 and 1,000,000.'
                      : null;
                },
              ),
              TextButton.icon(
                onPressed: _chooseEndDate,
                icon: const Icon(Icons.calendar_today_outlined),
                label: Text('Ends ${_endsAt.toLocal().toString().split(' ').first}'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Create'),
        ),
      ],
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  const _ChallengeCard({
    required this.challenge,
    required this.isBusy,
    required this.onToggleJoin,
  });

  final CommunityChallenge challenge;
  final bool isBusy;
  final VoidCallback onToggleJoin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SectionCard(
      color: challenge.isJoined ? theme.colorScheme.primaryContainer : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(challenge.title, style: theme.textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(challenge.description),
          const SizedBox(height: 10),
          Text('Goal: ${challenge.goal}'),
          Text(
            '${challenge.participantsCount} / ${challenge.participantGoal} participants • '
            '${challenge.daysLeft} days remaining',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: challenge.currentProgress),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.tonalIcon(
              onPressed: isBusy ? null : onToggleJoin,
              icon: isBusy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      challenge.isJoined ? Icons.check : Icons.group_add,
                      size: 16,
                    ),
              label: Text(challenge.isJoined ? 'Leave challenge' : 'Join'),
            ),
          ),
        ],
      ),
    );
  }
}
