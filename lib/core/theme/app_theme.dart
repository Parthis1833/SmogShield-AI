import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

@immutable
class AerisTokens extends ThemeExtension<AerisTokens> {
  const AerisTokens({
    required this.surfaceSecondary,
    required this.surfaceElevated,
    required this.atmosphericSurface,
    required this.brandHover,
    required this.solarAccent,
    required this.success,
    required this.warning,
    required this.mutedText,
    required this.divider,
    required this.disabledBackground,
    required this.disabledText,
  });

  final Color surfaceSecondary;
  final Color surfaceElevated;
  final Color atmosphericSurface;
  final Color brandHover;
  final Color solarAccent;
  final Color success;
  final Color warning;
  final Color mutedText;
  final Color divider;
  final Color disabledBackground;
  final Color disabledText;

  static AerisTokens forBrightness(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return AerisTokens(
      surfaceSecondary: isDark
          ? AppColors.surfaceSecondaryDark
          : AppColors.surfaceSecondaryLight,
      surfaceElevated:
          isDark ? AppColors.surfaceElevatedDark : AppColors.surfaceLight,
      atmosphericSurface:
          isDark ? AppColors.atmosphericDark : AppColors.atmosphericLight,
      brandHover: isDark ? AppColors.brandHoverDark : AppColors.brandHoverLight,
      solarAccent: isDark ? AppColors.solarDark : AppColors.solarLight,
      success: isDark ? AppColors.successDark : AppColors.successLight,
      warning: isDark ? AppColors.warningDark : AppColors.warningLight,
      mutedText: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
      divider: isDark ? AppColors.dividerDark : AppColors.dividerLight,
      disabledBackground: isDark
          ? AppColors.disabledBackgroundDark
          : AppColors.disabledBackgroundLight,
      disabledText:
          isDark ? AppColors.disabledTextDark : AppColors.disabledTextLight,
    );
  }

  @override
  AerisTokens copyWith({
    Color? surfaceSecondary,
    Color? surfaceElevated,
    Color? atmosphericSurface,
    Color? brandHover,
    Color? solarAccent,
    Color? success,
    Color? warning,
    Color? mutedText,
    Color? divider,
    Color? disabledBackground,
    Color? disabledText,
  }) =>
      AerisTokens(
        surfaceSecondary: surfaceSecondary ?? this.surfaceSecondary,
        surfaceElevated: surfaceElevated ?? this.surfaceElevated,
        atmosphericSurface: atmosphericSurface ?? this.atmosphericSurface,
        brandHover: brandHover ?? this.brandHover,
        solarAccent: solarAccent ?? this.solarAccent,
        success: success ?? this.success,
        warning: warning ?? this.warning,
        mutedText: mutedText ?? this.mutedText,
        divider: divider ?? this.divider,
        disabledBackground: disabledBackground ?? this.disabledBackground,
        disabledText: disabledText ?? this.disabledText,
      );

  @override
  AerisTokens lerp(ThemeExtension<AerisTokens>? other, double t) {
    if (other is! AerisTokens) return this;
    return AerisTokens(
      surfaceSecondary:
          Color.lerp(surfaceSecondary, other.surfaceSecondary, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      atmosphericSurface:
          Color.lerp(atmosphericSurface, other.atmosphericSurface, t)!,
      brandHover: Color.lerp(brandHover, other.brandHover, t)!,
      solarAccent: Color.lerp(solarAccent, other.solarAccent, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      mutedText: Color.lerp(mutedText, other.mutedText, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      disabledBackground:
          Color.lerp(disabledBackground, other.disabledBackground, t)!,
      disabledText: Color.lerp(disabledText, other.disabledText, t)!,
    );
  }
}

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.brandLight,
      onPrimary: Colors.white,
      primaryContainer: AppColors.brandSubtleLight,
      onPrimaryContainer: AppColors.brandHoverLight,
      secondary: AppColors.solarLight,
      onSecondary: AppColors.textPrimaryLight,
      secondaryContainer: AppColors.atmosphericLight,
      onSecondaryContainer: AppColors.textPrimaryLight,
      tertiary: AppColors.successLight,
      onTertiary: Colors.white,
      error: AppColors.errorLight,
      onError: Colors.white,
      errorContainer: Color(0xFFFFE9EB),
      onErrorContainer: Color(0xFF7F202B),
      surface: AppColors.surfaceLight,
      onSurface: AppColors.textPrimaryLight,
      surfaceContainerHighest: AppColors.atmosphericLight,
      onSurfaceVariant: AppColors.textSecondaryLight,
      outline: AppColors.borderLight,
      outlineVariant: AppColors.dividerLight,
      shadow: Color(0x1A18202D),
      scrim: Color(0x660D1422),
      inverseSurface: AppColors.textPrimaryLight,
      onInverseSurface: Colors.white,
      inversePrimary: AppColors.brandDark,
    );

    return _base(
      colorScheme: colorScheme,
      canvas: AppColors.canvasLight,
      surface: AppColors.surfaceLight,
      border: AppColors.borderLight,
      primaryText: AppColors.textPrimaryLight,
      secondaryText: AppColors.textSecondaryLight,
      brand: AppColors.brandLight,
      onBrand: Colors.white,
      selected: AppColors.brandSubtleLight,
      tokens: const AerisTokens(
        surfaceSecondary: AppColors.surfaceSecondaryLight,
        surfaceElevated: AppColors.surfaceLight,
        atmosphericSurface: AppColors.atmosphericLight,
        brandHover: AppColors.brandHoverLight,
        solarAccent: AppColors.solarLight,
        success: AppColors.successLight,
        warning: AppColors.warningLight,
        mutedText: AppColors.textMutedLight,
        divider: AppColors.dividerLight,
        disabledBackground: AppColors.disabledBackgroundLight,
        disabledText: AppColors.disabledTextLight,
      ),
    );
  }

  static ThemeData dark() {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.brandDark,
      onPrimary: AppColors.canvasDark,
      primaryContainer: AppColors.brandSubtleDark,
      onPrimaryContainer: AppColors.brandHoverDark,
      secondary: AppColors.solarDark,
      onSecondary: AppColors.canvasDark,
      secondaryContainer: AppColors.atmosphericDark,
      onSecondaryContainer: AppColors.textPrimaryDark,
      tertiary: AppColors.successDark,
      onTertiary: AppColors.canvasDark,
      error: AppColors.errorDark,
      onError: AppColors.canvasDark,
      errorContainer: Color(0xFF4A2630),
      onErrorContainer: Color(0xFFFFDADF),
      surface: AppColors.surfaceDark,
      onSurface: AppColors.textPrimaryDark,
      surfaceContainerHighest: AppColors.surfaceSecondaryDark,
      onSurfaceVariant: AppColors.textSecondaryDark,
      outline: AppColors.borderDark,
      outlineVariant: AppColors.dividerDark,
      shadow: Color(0x66000000),
      scrim: Color(0x99000000),
      inverseSurface: AppColors.textPrimaryDark,
      onInverseSurface: AppColors.canvasDark,
      inversePrimary: AppColors.brandLight,
    );

    return _base(
      colorScheme: colorScheme,
      canvas: AppColors.canvasDark,
      surface: AppColors.surfaceDark,
      border: AppColors.borderDark,
      primaryText: AppColors.textPrimaryDark,
      secondaryText: AppColors.textSecondaryDark,
      brand: AppColors.brandDark,
      onBrand: AppColors.canvasDark,
      selected: AppColors.atmosphericDark,
      tokens: const AerisTokens(
        surfaceSecondary: AppColors.surfaceSecondaryDark,
        surfaceElevated: AppColors.surfaceElevatedDark,
        atmosphericSurface: AppColors.atmosphericDark,
        brandHover: AppColors.brandHoverDark,
        solarAccent: AppColors.solarDark,
        success: AppColors.successDark,
        warning: AppColors.warningDark,
        mutedText: AppColors.textMutedDark,
        divider: AppColors.dividerDark,
        disabledBackground: AppColors.disabledBackgroundDark,
        disabledText: AppColors.disabledTextDark,
      ),
    );
  }

  static ThemeData _base({
    required ColorScheme colorScheme,
    required Color canvas,
    required Color surface,
    required Color border,
    required Color primaryText,
    required Color secondaryText,
    required Color brand,
    required Color onBrand,
    required Color selected,
    required AerisTokens tokens,
  }) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(color: border),
    );
    final textTheme = AppTypography.textTheme(primaryText, secondaryText);
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: colorScheme.brightness,
      scaffoldBackgroundColor: canvas,
      canvasColor: canvas,
      cardColor: surface,
      dividerColor: tokens.divider,
      textTheme: textTheme,
      extensions: [tokens],
      visualDensity: VisualDensity.standard,
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: shape,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: canvas,
        foregroundColor: primaryText,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      iconTheme: IconThemeData(color: secondaryText),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        selectedColor: selected,
        side: BorderSide(color: border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        labelStyle: textTheme.labelMedium,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tokens.surfaceSecondary,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: textTheme.bodyMedium?.copyWith(color: tokens.mutedText),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: brand, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          backgroundColor: brand,
          foregroundColor: onBrand,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: brand,
          side: BorderSide(color: border),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: brand,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: selected,
        height: 72,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? textTheme.labelMedium
                  ?.copyWith(color: brand, fontWeight: FontWeight.w600)
              : textTheme.labelMedium,
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color:
                states.contains(WidgetState.selected) ? brand : secondaryText,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: surface,
        indicatorColor: selected,
        selectedIconTheme: IconThemeData(color: brand),
        unselectedIconTheme: IconThemeData(color: secondaryText),
        selectedLabelTextStyle: textTheme.labelMedium?.copyWith(color: brand),
        unselectedLabelTextStyle: textTheme.labelMedium,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: brand),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? onBrand : secondaryText,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? brand
              : tokens.disabledBackground,
        ),
      ),
    );
  }
}
