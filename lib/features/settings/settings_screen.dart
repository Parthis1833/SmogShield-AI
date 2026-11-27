import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/data/family_profile_provider.dart';
import '../../core/data/routine_repository.dart';
import '../../core/theme/theme_controller.dart';
import '../../core/widgets/section_card.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeModeProvider);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      children: [
        const PageHeading(
            'Settings', 'Preferences, standards, and data transparency'),
        // Appearance
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Appearance',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(
                'Choose how SmogShield AI looks on this device.',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(
                      value: ThemeMode.system,
                      label: Text('System'),
                      icon: Icon(Icons.brightness_auto)),
                  ButtonSegment(
                      value: ThemeMode.light,
                      label: Text('Light'),
                      icon: Icon(Icons.light_mode_outlined)),
                  ButtonSegment(
                      value: ThemeMode.dark,
                      label: Text('Dark'),
                      icon: Icon(Icons.dark_mode_outlined)),
                ],
                selected: {themeMode},
                onSelectionChanged: (set) async {
                  try {
                    await ref
                        .read(themeModeProvider.notifier)
                        .setThemeMode(set.first);
                  } catch (error) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              'Could not save appearance preference: $error')),
                    );
                  }
                },
              ),
              const SizedBox(height: 14),
              _ThemePreview(themeMode: themeMode),
            ],
          ),
        ),
        // Data Safety & Medical Disclaimer
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.security_outlined,
                      color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text('Data Safety & Disclaimers',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                '• Live Measurements: Air readings come only from configured monitoring providers and are shown with source and timestamp.\n• No Diagnostic Claims: Recommendations are environmental guidance and do not constitute medical diagnosis.\n• Emissions vs Inhalation: Estimated carbon savings are separate from measured air-quality improvements.',
                style: TextStyle(fontSize: 12, height: 1.45),
              ),
            ],
          ),
        ),
        // Reset
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Personalized routine',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              const Text(
                  'Generate an updated routine from your household profile and the configured assistant service.',
                  style: TextStyle(fontSize: 12)),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Generate new routine'),
                onPressed: () {
                  ref.invalidate(routineProvider);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'A new routine will be generated when you open Daily Routine.')),
                  );
                },
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                icon: const Icon(Icons.menu_book_outlined, size: 18),
                label: const Text('View welcome guide'),
                onPressed: () => context.go('/onboarding'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ThemePreview extends StatelessWidget {
  const _ThemePreview({required this.themeMode});

  final ThemeMode themeMode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final systemIsDark =
        MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    final isDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system && systemIsDark);
    final canvas = isDark ? AppColors.canvasDark : AppColors.canvasLight;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final brand = isDark ? AppColors.brandDark : AppColors.brandLight;
    final text =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      height: 76,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: canvas,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Row(
        children: [
          Container(
            width: 43,
            height: 54,
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: theme.colorScheme.outline),
            ),
            child: Icon(Icons.air_rounded, color: brand),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${themeMode.name[0].toUpperCase()}${themeMode.name.substring(1)} appearance',
                  style: theme.textTheme.labelLarge?.copyWith(color: text),
                ),
                const SizedBox(height: 5),
                Container(
                  height: 7,
                  width: 112,
                  decoration: BoxDecoration(
                    color: brand.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.check_circle, color: brand, size: 20),
        ],
      ),
    );
  }
}
