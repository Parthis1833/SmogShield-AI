import 'package:flutter/material.dart';

class AppTypography {
  AppTypography._();

  static const String fontFamily = 'Plus Jakarta Sans';
  static const List<String> fontFamilyFallback = ['Inter', 'sans-serif'];

  static TextTheme textTheme(Color primary, Color secondary) {
    const base = TextStyle(
      fontFamily: fontFamily,
      fontFamilyFallback: fontFamilyFallback,
    );
    return TextTheme(
      displayLarge: base.copyWith(
          fontSize: 40,
          fontWeight: FontWeight.w700,
          height: 1.12,
          color: primary),
      displayMedium: base.copyWith(
          fontSize: 34,
          fontWeight: FontWeight.w700,
          height: 1.16,
          color: primary),
      headlineLarge: base.copyWith(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          height: 1.2,
          color: primary),
      headlineMedium: base.copyWith(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          height: 1.25,
          color: primary),
      titleLarge: base.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          height: 1.3,
          color: primary),
      titleMedium: base.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          height: 1.35,
          color: primary),
      titleSmall: base.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          height: 1.35,
          color: primary),
      bodyLarge: base.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          height: 1.5,
          color: primary),
      bodyMedium: base.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 1.45,
          color: primary),
      bodySmall: base.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          height: 1.4,
          color: secondary),
      labelLarge: base.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          height: 1.3,
          color: primary),
      labelMedium: base.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          height: 1.3,
          color: secondary),
      labelSmall: base.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          height: 1.3,
          color: secondary),
    );
  }
}
