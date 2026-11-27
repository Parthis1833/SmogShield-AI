import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const canvasLight = Color(0xFFF3F2EB);
  static const surfaceLight = Color(0xFFFFFFFF);
  static const surfaceSecondaryLight = Color(0xFFF8FAF7);
  static const atmosphericLight = Color(0xFFDDEDE3);
  static const brandLight = Color(0xFF173B35);
  static const brandHoverLight = Color(0xFF102923);
  static const brandSubtleLight = Color(0xFFDDEDE3);
  static const textPrimaryLight = Color(0xFF242C2A);
  static const textSecondaryLight = Color(0xFF52605A);
  static const textMutedLight = Color(0xFF788680);
  static const borderLight = Color(0xFFDFE5DF);
  static const dividerLight = Color(0xFFE7ECE7);
  static const solarLight = Color(0xFFE5A45B);
  static const successLight = Color(0xFF3E7557);
  static const warningLight = Color(0xFF91621F);
  static const errorLight = Color(0xFFB3433E);
  static const disabledBackgroundLight = Color(0xFFE8ECE7);
  static const disabledTextLight = Color(0xFF788680);

  static const canvasDark = Color(0xFF102923);
  static const surfaceDark = Color(0xFF173B35);
  static const surfaceSecondaryDark = Color(0xFF1D3E36);
  static const surfaceElevatedDark = Color(0xFF23483E);
  static const atmosphericDark = Color(0xFF294A40);
  static const brandDark = Color(0xFFB9E4C9);
  static const brandHoverDark = Color(0xFFDDEDE3);
  static const brandSubtleDark = Color(0xFF284A3F);
  static const textPrimaryDark = Color(0xFFF3F5F1);
  static const textSecondaryDark = Color(0xFFC1CDC6);
  static const textMutedDark = Color(0xFFA0B1A8);
  static const borderDark = Color(0xFF39564C);
  static const dividerDark = Color(0xFF304A41);
  static const solarDark = Color(0xFFE5A45B);
  static const successDark = Color(0xFF86B89A);
  static const warningDark = Color(0xFFE5A45B);
  static const errorDark = Color(0xFFE69A91);
  static const disabledBackgroundDark = Color(0xFF2C433B);
  static const disabledTextDark = Color(0xFF83938A);

  static const aqiGood = Color(0xFF26965C);
  static const aqiSatisfactory = Color(0xFF78AC45);
  static const aqiModerate = Color(0xFFE9B949);
  static const aqiPoor = Color(0xFFE58B43);
  static const aqiVeryPoor = Color(0xFFD65C67);
  static const aqiSevere = Color(0xFFA64D86);

  static const forestGreen = brandLight;
  static const primaryTeal = brandLight;
  static const lightTeal = brandDark;
  static const mint = successDark;
  static const tealContainer = brandSubtleLight;
  static const tealDark = brandHoverLight;
  static const lightBackground = canvasLight;
  static const lightCard = surfaceLight;
  static const lightBorder = borderLight;
  static const darkBackground = canvasDark;
  static const darkCard = surfaceDark;
  static const darkCardElevated = surfaceElevatedDark;
  static const darkBorder = borderDark;
  static const textDark = textPrimaryLight;
  static const textMuted = textMutedLight;
  static const textLight = textPrimaryDark;
  static const textLightMuted = textMutedDark;

  static Color getAqiColor(int aqi) {
    if (aqi <= 50) return aqiGood;
    if (aqi <= 100) return aqiSatisfactory;
    if (aqi <= 200) return aqiModerate;
    if (aqi <= 300) return aqiPoor;
    if (aqi <= 400) return aqiVeryPoor;
    return aqiSevere;
  }

  static Color getAqiTextColor(int aqi) {
    return getContrastingTextColor(getAqiColor(aqi));
  }

  static Color getContrastingTextColor(Color background) {
    final luminance = background.computeLuminance();
    final darkTextLuminance = Colors.black.computeLuminance();
    final darkContrast = (luminance + 0.05) / (darkTextLuminance + 0.05);
    final lightContrast = 1.05 / (luminance + 0.05);
    return darkContrast >= lightContrast ? Colors.black : Colors.white;
  }
}
