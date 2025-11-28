import 'package:flutter/material.dart';

class AccentPalette {
  // Core accent colors
  final Color primary;
  final Color primaryVariant;
  final Color secondary;

  // Accent-influenced backgrounds
  final Color bgElevated;
  final Color focus;
  final Color shadowTint;
  final Color infoBg;

  const AccentPalette({
    required this.primary,
    required this.primaryVariant,
    required this.secondary,
    required this.bgElevated,
    required this.focus,
    required this.shadowTint,
    required this.infoBg,
  });
}

class ColorService {
  // Light mode (default)
  static const Color primary = Color(0xFF0B6FF0);
  static const Color primaryVariant = Color(0xFF095BD6);
  static const Color secondary = Color(0xFF7C4DFF);
  // Adjusted for better white text contrast (AA 4.5+). Old: #17B169 (~3.9 ratio)
  static const Color success = Color.fromARGB(
    255,
    22,
    168,
    100,
  ); // contrast ~5.7 vs white
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
  static const Color dmSuccess = Color.fromARGB(255, 95, 204, 137);
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
        surface: bgSurface,
        error: danger,
        onPrimary: textOnPrimary,
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
        surface: dmBgSurface,
        error: dmDanger,
        onPrimary: dmTextOnPrimary,
        onSurface: dmTextPrimary,
        onError: dmTextOnPrimary,
      ),
    );
  }

  // Accent palettes for light mode
  static const Map<String, AccentPalette> accentLight = {
    'cherry': AccentPalette(
      primary: Color(0xFFD20A2E), // rich cherry red
      primaryVariant: Color(0xFFB00826),
      secondary: Color(0xFFFF6F00), // warm orange complement
      bgElevated: Color(0xFFFFF2F4), // cherry-tinted elevated bg
      focus: Color(0xFFFFD6DC), // cherry focus ring
      shadowTint: Color.fromRGBO(210, 10, 46, 0.06),
      infoBg: Color(0xFFFFE4E9), // cherry info bg
    ),
    'pink': AccentPalette(
      primary: Color(0xFFE91E63), // vibrant pink
      primaryVariant: Color(0xFFC2185B),
      secondary: Color(0xFF00BFA5), // teal complement
      bgElevated: Color(0xFFFFF5F8),
      focus: Color(0xFFFFCDD2),
      shadowTint: Color.fromRGBO(233, 30, 99, 0.06),
      infoBg: Color(0xFFFFE4EC),
    ),
    'green': AccentPalette(
      primary: Color(0xFF2E7D32), // forest green
      primaryVariant: Color(0xFF1B5E20),
      secondary: Color(0xFF8E24AA), // purple complement
      bgElevated: Color(0xFFF1F8F2),
      focus: Color(0xFFC8E6C9),
      shadowTint: Color.fromRGBO(46, 125, 50, 0.06),
      infoBg: Color(0xFFE8F5E9),
    ),
    'cyan': AccentPalette(
      primary: Color(0xFF00ACC1), // bright cyan
      primaryVariant: Color(0xFF00838F),
      secondary: Color(0xFFFF6D00), // deep orange complement
      bgElevated: Color(0xFFF0FAFB),
      focus: Color(0xFFB2EBF2),
      shadowTint: Color.fromRGBO(0, 172, 193, 0.06),
      infoBg: Color(0xFFE0F7FA),
    ),
    'blue': AccentPalette(
      primary: Color(0xFF1976D2), // classic blue
      primaryVariant: Color(0xFF0D47A1),
      secondary: Color(0xFF7C4DFF), // purple complement
      bgElevated: Color(0xFFF2F5FF),
      focus: Color(0xFFC7E0FF),
      shadowTint: Color.fromRGBO(25, 118, 210, 0.06),
      infoBg: Color(0xFFE3F2FD),
    ),
    'teal': AccentPalette(
      primary: Color(0xFF00796B), // deep teal
      primaryVariant: Color(0xFF004D40),
      secondary: Color(0xFFD81B60), // pink complement
      bgElevated: Color(0xFFF0F8F7),
      focus: Color(0xFFB2DFDB),
      shadowTint: Color.fromRGBO(0, 121, 107, 0.06),
      infoBg: Color(0xFFE0F2F1),
    ),
    'magenta': AccentPalette(
      primary: Color(0xFF8E24AA), // rich magenta
      primaryVariant: Color(0xFF6A1B9A),
      secondary: Color(0xFF43A047), // green complement
      bgElevated: Color(0xFFF9F5FB),
      focus: Color(0xFFE1BEE7),
      shadowTint: Color.fromRGBO(142, 36, 170, 0.06),
      infoBg: Color(0xFFF3E5F5),
    ),
  };

  // Accent palettes for dark mode
  static const Map<String, AccentPalette> accentDark = {
    'cherry': AccentPalette(
      primary: Color(0xFFFF6783), // bright cherry
      primaryVariant: Color(0xFFFF4068),
      secondary: Color(0xFFFFAB40), // warm amber complement
      bgElevated: Color(0xFF1A1215), // cherry-tinted dark elevated
      focus: Color(0xFF4D1F2A), // cherry focus
      shadowTint: Color.fromRGBO(255, 103, 131, 0.12),
      infoBg: Color(0xFF2E1B22), // cherry dark info
    ),
    'pink': AccentPalette(
      primary: Color(0xFFFF80AB), // light pink
      primaryVariant: Color(0xFFFF4081),
      secondary: Color(0xFF64FFDA), // aqua complement
      bgElevated: Color(0xFF181316),
      focus: Color(0xFF4D1F33),
      shadowTint: Color.fromRGBO(255, 128, 171, 0.12),
      infoBg: Color(0xFF2C1D24),
    ),
    'green': AccentPalette(
      primary: Color(0xFF66BB6A), // lime green
      primaryVariant: Color(0xFF4CAF50),
      secondary: Color(0xFFB388FF), // light purple complement
      bgElevated: Color(0xFF111814),
      focus: Color(0xFF1F3D21),
      shadowTint: Color.fromRGBO(102, 187, 106, 0.12),
      infoBg: Color(0xFF1A2B1D),
    ),
    'cyan': AccentPalette(
      primary: Color(0xFF4DD0E1), // bright cyan
      primaryVariant: Color(0xFF26C6DA),
      secondary: Color(0xFFFF9E40), // orange complement
      bgElevated: Color(0xFF0F181A),
      focus: Color(0xFF1A3F45),
      shadowTint: Color.fromRGBO(77, 208, 225, 0.12),
      infoBg: Color(0xFF0E2326),
    ),
    'blue': AccentPalette(
      primary: Color(0xFF64B5F6), // sky blue
      primaryVariant: Color(0xFF42A5F5),
      secondary: Color(0xFFB388FF), // purple complement
      bgElevated: Color(0xFF0E1419),
      focus: Color(0xFF1A3A5C),
      shadowTint: Color.fromRGBO(100, 181, 246, 0.12),
      infoBg: Color(0xFF0E1B2A),
    ),
    'teal': AccentPalette(
      primary: Color(0xFF4DB6AC), // aqua teal
      primaryVariant: Color(0xFF26A69A),
      secondary: Color(0xFFFF4081), // pink accent complement
      bgElevated: Color(0xFF0F1716),
      focus: Color(0xFF1A3F3B),
      shadowTint: Color.fromRGBO(77, 182, 172, 0.12),
      infoBg: Color(0xFF0D1F1D),
    ),
    'magenta': AccentPalette(
      primary: Color(0xFFBA68C8), // light magenta
      primaryVariant: Color(0xFFAB47BC),
      secondary: Color(0xFF69F0AE), // mint green complement
      bgElevated: Color(0xFF141318),
      focus: Color(0xFF3D1F4D),
      shadowTint: Color.fromRGBO(186, 104, 200, 0.12),
      infoBg: Color(0xFF1E1627),
    ),
  };
}
