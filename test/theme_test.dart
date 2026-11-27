import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smogshield_ai/core/theme/app_colors.dart';
import 'package:smogshield_ai/core/theme/app_theme.dart';
import 'package:smogshield_ai/core/theme/theme_controller.dart';

void main() {
  test('light and dark themes use the SmogShield forest palette', () {
    expect(AppTheme.light().scaffoldBackgroundColor, AppColors.canvasLight);
    expect(AppTheme.light().colorScheme.primary, AppColors.brandLight);
    expect(AppTheme.light().cardColor, AppColors.surfaceLight);
    expect(AppTheme.dark().scaffoldBackgroundColor, AppColors.canvasDark);
    expect(AppTheme.dark().colorScheme.primary, AppColors.brandDark);
    expect(AppTheme.dark().cardColor, AppColors.surfaceDark);
    expect(AppColors.canvasLight, const Color(0xFFF3F2EB));
    expect(AppColors.brandLight, const Color(0xFF173B35));
    expect(AppColors.brandDark, const Color(0xFFB9E4C9));
  });

  test('theme mode is restored and persisted locally', () async {
    SharedPreferences.setMockInitialValues({});

    final firstContainer = ProviderContainer();
    addTearDown(firstContainer.dispose);

    expect(firstContainer.read(themeModeProvider), ThemeMode.system);
    await firstContainer
        .read(themeModeProvider.notifier)
        .setThemeMode(ThemeMode.dark);
    expect(firstContainer.read(themeModeProvider), ThemeMode.dark);

    final restoredContainer = ProviderContainer();
    addTearDown(restoredContainer.dispose);
    restoredContainer.read(themeModeProvider);
    await SharedPreferences.getInstance();
    await Future<void>.delayed(Duration.zero);

    expect(restoredContainer.read(themeModeProvider), ThemeMode.dark);
  });
}
