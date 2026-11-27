import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 860;
            final intro = _BrandIntro(theme: theme, wide: wide);
            final features = _FeatureList();
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: wide ? 48 : 24,
                vertical: 28,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1080),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (wide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(flex: 4, child: intro),
                            const SizedBox(width: 56),
                            Expanded(flex: 5, child: features),
                          ],
                        )
                      else ...[
                        intro,
                        const SizedBox(height: 32),
                        features,
                      ],
                      const SizedBox(height: 32),
                      SizedBox(
                        height: 52,
                        child: FilledButton(
                          onPressed: () => context.go('/'),
                          child: const Text('Get started'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Location access is requested only when you choose GPS.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BrandIntro extends StatelessWidget {
  const _BrandIntro({required this.theme, required this.wide});

  final ThemeData theme;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          wide ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Icon(
              Icons.shield_outlined,
              size: 38,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(height: 22),
        Text(
          'SmogShield AI',
          textAlign: wide ? TextAlign.start : TextAlign.center,
          style: theme.textTheme.displayMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'A clear, practical companion for cleaner air and healthier days.',
          textAlign: wide ? TextAlign.start : TextAlign.center,
          style: theme.textTheme.bodyLarge
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _FeatureList extends StatelessWidget {
  const _FeatureList();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _PillarRow(
          icon: Icons.air,
          title: 'Measured air, with context',
          subtitle:
              'Read nearby station measurements with their source and observation time.',
        ),
        SizedBox(height: 20),
        _PillarRow(
          icon: Icons.auto_awesome,
          title: 'Practical daily guidance',
          subtitle:
              'Plan commuting, school runs, and indoor exercise with clear data labels.',
        ),
        SizedBox(height: 20),
        _PillarRow(
          icon: Icons.home_repair_service_outlined,
          title: 'Indoor air hygiene',
          subtitle:
              'Explore filtration, sealing, and ventilation recommendations.',
        ),
        SizedBox(height: 20),
        _PillarRow(
          icon: Icons.eco_outlined,
          title: 'Understand your impact',
          subtitle: 'Track avoided CO₂e with transparent calculations.',
        ),
      ],
    );
  }
}

class _PillarRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _PillarRow(
      {required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: theme.colorScheme.primary, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }
}
