import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/data/routine_repository.dart';
import '../../core/models/routine_item.dart';
import '../../core/widgets/section_card.dart';

class RoutineScreen extends ConsumerStatefulWidget {
  const RoutineScreen({super.key});

  @override
  ConsumerState<RoutineScreen> createState() => _RoutineScreenState();
}

class _RoutineScreenState extends ConsumerState<RoutineScreen> {
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final routinesAsync = ref.watch(routineProvider);
    final routines = routinesAsync.value ?? const <RoutineItem>[];
    final theme = Theme.of(context);

    final filteredRoutines = routines.where((item) {
      if (_selectedFilter == 'All') return true;
      if (_selectedFilter == 'Morning') return item.timePeriod == 'Morning';
      if (_selectedFilter == 'Afternoon') return item.timePeriod == 'Afternoon';
      if (_selectedFilter == 'Evening & Night') {
        return item.timePeriod == 'Evening' || item.timePeriod == 'Night';
      }
      return true;
    }).toList();

    final completedCount = routines.where((r) => r.isCompleted).length;
    final progressFraction =
        routines.isEmpty ? 0.0 : completedCount / routines.length;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      children: [
        PageHeading(
          'Daily Routine',
          'Personalized environmental guidance for your household',
          trailing: IconButton(
            tooltip: 'Generate a new routine',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(routineProvider),
          ),
        ),
        if (routinesAsync.isLoading)
          const SectionCard(
            child: Center(child: CircularProgressIndicator()),
          ),
        if (routinesAsync.hasError)
          SectionCard(
            child: Column(
              children: [
                Text(
                  'Could not load a personalized routine: '
                  '${routinesAsync.error}',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => ref.invalidate(routineProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try again'),
                ),
              ],
            ),
          ),
        if (routinesAsync.hasValue) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.colorScheme.outline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  routines.isEmpty
                      ? 'No routine steps were returned.'
                      : 'Completed: $completedCount / ${routines.length}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (routines.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progressFraction,
                      minHeight: 8,
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

        // Time period filter tabs
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ['All', 'Morning', 'Afternoon', 'Evening & Night']
                .map((filter) {
              final isSelected = _selectedFilter == filter;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(filter),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _selectedFilter = filter),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),

        // Explanatory Routine Cards: Time, Action, Why it matters
        LayoutBuilder(
          builder: (context, constraints) {
            if (filteredRoutines.isEmpty) {
              return SectionCard(
                child: SizedBox(
                  width: double.infinity,
                  child: Column(
                    children: [
                      Icon(
                        Icons.event_busy_outlined,
                        size: 30,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        routines.isEmpty
                            ? 'No routine steps are available yet'
                            : 'No steps match this time period',
                        style: theme.textTheme.titleSmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        routines.isEmpty
                            ? 'No personalized schedule is shown until routine data is available.'
                            : 'Choose another time period to see the available steps.',
                        style: theme.textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }
            final wide = constraints.maxWidth >= 900;
            final cardWidth =
                wide ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth;
            return Wrap(
              spacing: 16,
              children: [
                for (final item in filteredRoutines)
                  SizedBox(
                    width: cardWidth,
                    child: _RoutineCard(
                      item: item,
                      onToggle: () {
                        ref
                            .read(routineProvider.notifier)
                            .toggleCompleted(item.id);
                      },
                    ),
                  ),
              ],
            );
          },
        ),

        const SizedBox(height: 8),

        // Educational Atmospheric Inversion Insight Card
        SectionCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.wb_twilight_outlined,
                  color: theme.colorScheme.primary, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Diurnal Inversion Shielding Cycle',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Winter smog follows a distinct surface thermal inversion cycle. Ground radiative cooling traps cold air and concentrated exhaust near ground level between 6–10 AM and 7–11 PM. The afternoon solar window (1–3 PM) provides the best thermal dispersion for essential outdoor transitions or brief cross-ventilation.',
                      style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Safety Disclaimer Card
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.colorScheme.outline),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.shield_outlined,
                  size: 18, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Routine recommendations are environmental guidance generated from your household profile. They do not diagnose or treat medical conditions. Consult a healthcare professional for individual respiratory or heart concerns.',
                  style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ],
      ],
    );
  }
}

class _RoutineCard extends StatelessWidget {
  final RoutineItem item;
  final VoidCallback onToggle;

  const _RoutineCard({
    required this.item,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SectionCard(
      color: item.isCompleted ? theme.colorScheme.tertiaryContainer : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: item.isCompleted,
            activeColor: theme.colorScheme.primary,
            onChanged: (_) => onToggle(),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Time Badge + Time Period + Target Audience
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item.time,
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          item.timePeriod,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.targetAudience,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Action: Title & Detail
                Text(
                  item.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    decoration:
                        item.isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item.detail,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.4,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),

                // Explanatory "Why it matters" Section
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.lightbulb_outline,
                          size: 18, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: 'Why it matters: ',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              TextSpan(text: item.reason),
                            ],
                          ),
                          style: theme.textTheme.bodySmall?.copyWith(
                            height: 1.35,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
