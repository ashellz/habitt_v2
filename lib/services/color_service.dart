import 'package:flutter/material.dart';

class ColorService {
  // Light mode (default)
  static const Color primary = Color(0xFF0B6FF0);
  static const Color primaryVariant = Color(0xFF095BD6);
  static const Color secondary = Color(0xFF7C4DFF);
  static const Color success = Color(0xFF17B169);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFE02424);

  static const Color bgDefault = Color(0xFFF6F7FB);
  static const Color bgSurface = Color(0xFFFFFFFF);
  static const Color bgElevated = Color(0xFFF2F5FF);
  static const Color bgMuted = Color.fromARGB(255, 152, 162, 189);

  static const Color border = Color(0xFFE6E9F2);
  static const Color focus = Color(0xFFC7E0FF);

  static const Color textPrimary = Color(0xFF0F1724);
  static const Color textSecondary = Color(0xFF5B6470);
  static const Color textMuted = Color(0xFF98A0AA);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  static const Color shadowTint = Color.fromRGBO(11, 111, 240, 0.06);
  static const Color modalOverlay = Color.fromRGBO(3, 6, 23, 0.48);

  // Semantic subtle backgrounds (light)
  static const Color infoBg = Color(0xFFEAF4FF);
  static const Color successBg = Color(0xFFECFDF3);
  static const Color warningBg = Color(0xFFFFF7ED);
  static const Color errorBg = Color(0xFFFFF1F1);

  // Dark mode variant
  static const Color dmPrimary = Color(
    0xFF4EA6FF,
  ); // lighter primary for dark bg
  static const Color dmPrimaryVariant = Color(0xFF257FE6);
  static const Color dmSecondary = Color(0xFFB89BFF);
  static const Color dmSuccess = Color(0xFF6FDD9A);
  static const Color dmWarning = Color(0xFFF7C164);
  static const Color dmDanger = Color(0xFFFF6B6B);

  static const Color dmBgDefault = Color(0xFF0B0F14); // app background
  static const Color dmBgSurface = Color(0xFF0F1318); // cards/panels
  static const Color dmBgElevated = Color(0xFF141821); // elevated surfaces
  static const Color dmBgMuted = Color.fromARGB(255, 77, 90, 109);

  static const Color dmBorder = Color(0xFF242A33);
  static const Color dmFocus = Color(0xFF2B6FFF);

  static const Color dmTextPrimary = Color(0xFFE7EEF8);
  static const Color dmTextSecondary = Color(0xFFB8C2CC);
  static const Color dmTextMuted = Color(0xFF8D97A1);
  static const Color dmTextOnPrimary = Color(
    0xFF0B0F14,
  ); // dark text on light primary buttons if used

  static const Color dmShadowTint = Color.fromRGBO(0, 0, 0, 0.6);
  static const Color dmModalOverlay = Color.fromRGBO(2, 6, 12, 0.72);

  // Semantic subtle backgrounds (dark)
  static const Color dmInfoBg = Color(0xFF06243A);
  static const Color dmSuccessBg = Color(0xFF062917);
  static const Color dmWarningBg = Color(0xFF2B210A);
  static const Color dmErrorBg = Color(0xFF2A0E0E);

  // Convenience theme data (light)
  static ThemeData lightThemeData() {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: primary,
      scaffoldBackgroundColor: bgDefault,
      canvasColor: bgSurface,
      cardColor: bgSurface,
      dividerColor: border,
      focusColor: focus,
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: textPrimary),
        bodyMedium: TextStyle(color: textSecondary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: textOnPrimary,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary),
          backgroundColor: bgSurface,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: primary),
      ),
      colorScheme: ColorScheme.light(
        primary: primary,
        secondary: secondary,
        background: bgDefault,
        surface: bgSurface,
        error: danger,
        onPrimary: textOnPrimary,
        onBackground: textPrimary,
        onSurface: textPrimary,
        onError: textOnPrimary,
      ),
    );
  }

  // Convenience theme data (dark)
  static ThemeData darkThemeData() {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: dmPrimary,
      scaffoldBackgroundColor: dmBgDefault,
      canvasColor: dmBgSurface,
      cardColor: dmBgSurface,
      dividerColor: dmBorder,
      focusColor: dmFocus,
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: dmTextPrimary),
        bodyMedium: TextStyle(color: dmTextSecondary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: dmPrimary,
          foregroundColor: dmTextOnPrimary,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: dmPrimary,
          side: const BorderSide(color: dmPrimary),
          backgroundColor: dmBgSurface,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: dmPrimary),
      ),
      colorScheme: ColorScheme.dark(
        primary: dmPrimary,
        secondary: dmSecondary,
        background: dmBgDefault,
        surface: dmBgSurface,
        error: dmDanger,
        onPrimary: dmTextOnPrimary,
        onBackground: dmTextPrimary,
        onSurface: dmTextPrimary,
        onError: dmTextOnPrimary,
      ),
    );
  }
}
