import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/data/indoor_tip_repository.dart';
import '../../core/models/indoor_tip.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/section_card.dart';

class IndoorAirScreen extends ConsumerStatefulWidget {
  const IndoorAirScreen({super.key});

  @override
  ConsumerState<IndoorAirScreen> createState() => _IndoorAirScreenState();
}

class _IndoorAirScreenState extends ConsumerState<IndoorAirScreen> {
  IndoorCategory? _selectedCategory;
  final Set<String> _checkedChecklist = {};

  final List<String> _checklistItems = [
    'True HEPA (H13/H14) filter operating in bedrooms',
    'Windows sealed with weather-stripping or draft stoppers',
    'Zero unvented incense sticks, agarbatti, or scented candles',
    'Kitchen ducted exhaust fan active during cooking',
    'Wet mopping instead of dry brooming to prevent particle resuspension',
    'Indoor air quality monitor placed away from direct drafts',
  ];

  @override
  Widget build(BuildContext context) {
    final tipsAsync = ref.watch(indoorTipsProvider);
    final tips = tipsAsync.value ?? const <IndoorTip>[];
    final theme = Theme.of(context);

    final filteredTips = _selectedCategory == null
        ? tips
        : tips.where((t) => t.category == _selectedCategory).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      children: [
        const PageHeading('Indoor Air Quality',
            'Evidence-based indoor smog defense & filtration'),
        // Health Notice Disclaimer
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.colorScheme.outline),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.verified_outlined,
                  size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Evidence-based environmental guidance. Does not diagnose or treat medical conditions. Consult a physician for acute respiratory distress.',
                  style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
                ),
              ),
            ],
          ),
        ),
        // Home Clean Air Readiness Audit
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Indoor Clean Air Audit',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Score: ${_checkedChecklist.length}/${_checklistItems.length}',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _checkedChecklist.length / _checklistItems.length,
                  minHeight: 8,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
                ),
              ),
              const SizedBox(height: 12),
              for (final item in _checklistItems)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(item, style: const TextStyle(fontSize: 13)),
                  value: _checkedChecklist.contains(item),
                  activeColor: theme.colorScheme.primary,
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        _checkedChecklist.add(item);
                      } else {
                        _checkedChecklist.remove(item);
                      }
                    });
                  },
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Category filters
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: const Text('All Topics'),
                  selected: _selectedCategory == null,
                  onSelected: (_) => setState(() => _selectedCategory = null),
                ),
              ),
              for (final cat in IndoorCategory.values)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(cat.label),
                    selected: _selectedCategory == cat,
                    onSelected: (_) => setState(() => _selectedCategory = cat),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (tipsAsync.isLoading)
          const SectionCard(
            child: Center(child: CircularProgressIndicator()),
          ),
        if (tipsAsync.hasError)
          SectionCard(
            child: Column(
              children: [
                Text(
                  'Could not load indoor guidance: ${tipsAsync.error}',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => ref.invalidate(indoorTipsProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try again'),
                ),
              ],
            ),
          ),
        if (tipsAsync.hasValue)
          LayoutBuilder(
            builder: (context, constraints) {
              if (filteredTips.isEmpty) {
                return const SectionCard(
                  child: Text('No indoor guidance is available.'),
                );
              }
              final wide = constraints.maxWidth >= 900;
              final cardWidth = wide
                  ? (constraints.maxWidth - 16) / 2
                  : constraints.maxWidth;
              return Wrap(
                spacing: 16,
                children: [
                  for (final tip in filteredTips)
                    SizedBox(
                      width: cardWidth,
                      child: _tipCard(context, tip),
                    ),
                ],
              );
            },
          ),
      ],
    );
  }

  Widget _tipCard(BuildContext context, IndoorTip tip) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AerisTokens>() ??
        AerisTokens.forBrightness(theme.brightness);
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      (tip.isDoItem ? tokens.success : theme.colorScheme.error)
                          .withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      tip.isDoItem
                          ? Icons.check_circle_outline
                          : Icons.highlight_off,
                      size: 14,
                      color: tip.isDoItem
                          ? tokens.success
                          : theme.colorScheme.error,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      tip.isDoItem ? 'RECOMMENDED' : 'AVOID',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: tip.isDoItem
                            ? tokens.success
                            : theme.colorScheme.error,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  tip.category.label,
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            tip.title,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            tip.summary,
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            tip.detailedExplanation,
            style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.colorScheme.outline),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.science_outlined,
                    size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Basis: ${tip.scientificBasis}',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(fontStyle: FontStyle.italic),
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
