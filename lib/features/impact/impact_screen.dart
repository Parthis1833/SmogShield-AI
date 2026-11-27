import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/impact_repository.dart';
import '../../core/models/impact_action.dart';
import '../../core/widgets/section_card.dart';

class ImpactScreen extends ConsumerStatefulWidget {
  const ImpactScreen({super.key});

  @override
  ConsumerState<ImpactScreen> createState() => _ImpactScreenState();
}

class _ImpactScreenState extends ConsumerState<ImpactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _distanceController = TextEditingController();
  String? _baselineMode;
  String? _alternativeMode;
  String? _errorMessage;
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _distanceController.dispose();
    super.dispose();
  }

  Future<void> _recordAction(
    String baselineMode,
    String alternativeMode,
  ) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    try {
      await ref.read(impactRepositoryProvider).record(
            ImpactActionRequest(
              title: _titleController.text.trim(),
              baselineMode: baselineMode,
              alternativeMode: alternativeMode,
              distanceKm: double.parse(_distanceController.text.trim()),
            ),
          );
      if (!mounted) return;
      _titleController.clear();
      _distanceController.clear();
      ref.invalidate(impactDataProvider);
    } catch (error) {
      if (mounted) setState(() => _errorMessage = error.toString());
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dataAsync = ref.watch(impactDataProvider);
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      children: [
        const PageHeading(
          'Your Impact',
          'Record real travel choices using published emissions factors',
        ),
        dataAsync.when(
          loading: () => const SectionCard(
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => SectionCard(
            child: Column(
              children: [
                Text(
                  'Could not load impact data: $error',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => ref.invalidate(impactDataProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try again'),
                ),
              ],
            ),
          ),
          data: (data) {
            if (data.benchmarks.length < 2) {
              return const SectionCard(
                child: Text('Not enough emissions benchmarks are available.'),
              );
            }
            final baseline = _baselineMode ??
                data.benchmarks
                    .firstWhere(
                      (item) => item.mode == 'Solo Petrol Car',
                      orElse: () => data.benchmarks.first,
                    )
                    .mode;
            final alternatives = data.benchmarks
                .where((item) => item.mode != baseline)
                .toList();
            final alternative = alternatives.any(
              (item) => item.mode == _alternativeMode,
            )
                ? _alternativeMode!
                : alternatives.first.mode;
            final totalSavings = data.actions.fold<double>(
              0,
              (total, action) => total + action.co2eSavingsKg,
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Record a travel action',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              controller: _titleController,
                              decoration: const InputDecoration(
                                labelText: 'What did you do?',
                              ),
                              validator: (value) =>
                                  (value?.trim().length ?? 0) < 3
                                      ? 'Enter a short action description.'
                                      : null,
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              value: baseline,
                              decoration: const InputDecoration(
                                labelText: 'Compared with',
                              ),
                              items: data.benchmarks
                                  .map(
                                    (item) => DropdownMenuItem(
                                      value: item.mode,
                                      child: Text(item.mode),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) => setState(() {
                                _baselineMode = value;
                                if (value == _alternativeMode) {
                                  _alternativeMode = null;
                                }
                              }),
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              value: alternative,
                              decoration: const InputDecoration(
                                labelText: 'Travelled by',
                              ),
                              items: alternatives
                                  .map(
                                    (item) => DropdownMenuItem(
                                      value: item.mode,
                                      child: Text(item.mode),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) =>
                                  setState(() => _alternativeMode = value),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _distanceController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              decoration: const InputDecoration(
                                labelText: 'Distance (km)',
                              ),
                              validator: (value) {
                                final distance =
                                    double.tryParse(value?.trim() ?? '');
                                if (distance == null ||
                                    !distance.isFinite ||
                                    distance <= 0 ||
                                    distance > 1000) {
                                  return 'Enter a distance greater than 0 and at most 1,000 km.';
                                }
                                return null;
                              },
                            ),
                            if (_errorMessage != null) ...[
                              const SizedBox(height: 12),
                              Text(
                                _errorMessage!,
                                style: TextStyle(
                                  color: theme.colorScheme.error,
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            FilledButton.icon(
                              onPressed: _isSaving
                                  ? null
                                  : () => _recordAction(baseline, alternative),
                              icon: _isSaving
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.add_task),
                              label: const Text('Save action'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SectionCard(
                  color: theme.colorScheme.primaryContainer,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Estimated recorded emissions difference',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${totalSavings.toStringAsFixed(2)} kg CO₂e',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(data.disclaimer),
                    ],
                  ),
                ),
                Text(
                  'Your recorded actions',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (data.actions.isEmpty)
                  const SectionCard(
                    child: Text('No actions have been recorded yet.'),
                  ),
                for (final action in data.actions.reversed)
                  _ImpactActionCard(action: action),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ImpactActionCard extends StatelessWidget {
  const _ImpactActionCard({required this.action});

  final ImpactAction action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(action.title, style: theme.textTheme.titleSmall),
          const SizedBox(height: 6),
          Text(
            '${action.distanceKm.toStringAsFixed(1)} km • '
            '${action.baselineMode} → ${action.alternativeMode}',
          ),
          const SizedBox(height: 6),
          Text(action.formula, style: theme.textTheme.bodySmall),
          const SizedBox(height: 6),
          Text(
            '${action.co2eSavingsKg.toStringAsFixed(2)} kg CO₂e estimated • '
            '${action.recordedAt?.toLocal() ?? DateTime.now()}',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
