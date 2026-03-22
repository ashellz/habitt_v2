import 'package:flutter/material.dart';
import 'package:habitt/services/old_color_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const _kThemePrefKey = 'theme_mode'; // 'light' | 'dark' | 'system'
  static const _kAccentPrefKey = 'accent_name'; // 'blue' | 'cherry' | ...

  ThemeMode mode;
  String accentName;
  ThemeProvider(this.mode, [this.accentName = 'blue']);

  // init from prefs
  static Future<ThemeProvider> initFromPrefs(SharedPreferences prefs) async {
    final s = prefs.getString(_kThemePrefKey);
    final mode =
        s == 'light'
            ? ThemeMode.light
            : s == 'dark'
            ? ThemeMode.dark
            : ThemeMode.system;
    final a = prefs.getString(_kAccentPrefKey) ?? 'blue';
    return ThemeProvider(mode, a);
  }

  Future<void> setMode(ThemeMode newMode) async {
    if (newMode == mode) return;
    mode = newMode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kThemePrefKey,
      mode == ThemeMode.light
          ? 'light'
          : mode == ThemeMode.dark
          ? 'dark'
          : 'system',
    );
  }

  Future<void> setAccent(String newAccent) async {
    if (newAccent == accentName) return;
    accentName = newAccent;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kAccentPrefKey, accentName);
  }

  // Resolved against current platform brightness only when mode == system.
  bool get isDark {
    if (mode == ThemeMode.light) return false;
    if (mode == ThemeMode.dark) return true;
    return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
        Brightness.dark;
  }

  // Accent palette resolved for current brightness
  AccentPalette? get _accentPalette =>
      isDark
          ? ColorService.accentDark[accentName]
          : ColorService.accentLight[accentName];

  // Core colors (primary derived from accent selection)
  Color get primaryColor =>
      (_accentPalette?.primary) ??
      (isDark ? ColorService.dmPrimary : ColorService.primary);
  Color get primaryVariant =>
      (_accentPalette?.primaryVariant) ??
      (isDark ? ColorService.dmPrimaryVariant : ColorService.primaryVariant);
  Color get secondaryColor =>
      (_accentPalette?.secondary) ??
      (isDark ? ColorService.dmSecondary : ColorService.secondary);
  Color get successColor =>
      isDark ? ColorService.dmSuccess : ColorService.success;
  Color get warningColor =>
      isDark ? ColorService.dmWarning : ColorService.warning;
  Color get dangerColor => isDark ? ColorService.dmDanger : ColorService.danger;

  // Backgrounds / surfaces
  Color get backgroundColor =>
      isDark ? ColorService.dmBgDefault : ColorService.bgDefault;
  Color get surfaceColor =>
      isDark ? ColorService.dmBgSurface : ColorService.bgSurface;
  Color get elevatedSurfaceColor =>
      (_accentPalette?.bgElevated) ??
      (isDark ? ColorService.dmBgElevated : ColorService.bgElevated);
  Color get mutedBgColor =>
      isDark ? ColorService.dmBgMuted : ColorService.bgMuted;
  Color get nestedSurfaceColor =>
      isDark ? ColorService.dmNestedSurface : ColorService.nestedSurface;

  // Borders & focus
  Color get borderColor => isDark ? ColorService.dmBorder : ColorService.border;
  Color get focusColor =>
      (_accentPalette?.focus) ??
      (isDark ? ColorService.dmFocus : ColorService.focus);

  // Text colors
  Color get primaryTextColor =>
      isDark ? ColorService.dmTextPrimary : ColorService.textPrimary;
  Color get secondaryTextColor =>
      isDark ? ColorService.dmTextSecondary : ColorService.textSecondary;
  Color get mutedTextColor =>
      isDark ? ColorService.dmTextMuted : ColorService.textMuted;
  Color get onPrimaryTextColor =>
      isDark ? ColorService.dmTextOnPrimary : ColorService.textOnPrimary;

  // Buttons
  Color get primaryButtonBackground => primaryColor;
  Color get primaryButtonForeground => onPrimaryTextColor;
  Color get primaryButtonHover => primaryVariant;

  Color get secondaryButtonBackground => surfaceColor;
  Color get secondaryButtonBorder => primaryColor;
  Color get secondaryButtonForeground => primaryColor;

  Color get tertiaryButtonForeground => primaryColor;

  Color get destructiveButtonBackground => dangerColor;
  Color get destructiveButtonForeground => onPrimaryTextColor;

  Color get successButtonBackground => successColor;
  Color get successButtonForeground => onPrimaryTextColor;

  // Semantic subtle backgrounds
  Color get infoBackground =>
      (_accentPalette?.infoBg) ??
      (isDark ? ColorService.dmInfoBg : ColorService.infoBg);
  Color get successBackground =>
      isDark ? ColorService.dmSuccessBg : ColorService.successBg;
  Color get warningBackground =>
      isDark ? ColorService.dmWarningBg : ColorService.warningBg;
  Color get errorBackground =>
      isDark ? ColorService.dmErrorBg : ColorService.errorBg;

  // Shadows & overlays
  Color get shadowTint =>
      (_accentPalette?.shadowTint) ??
      (isDark ? ColorService.dmShadowTint : ColorService.shadowTint);
  Color get modalOverlay =>
      isDark ? ColorService.dmModalOverlay : ColorService.modalOverlay;

  // Habit color presets resolved for current theme
  List<HabitColorChoice> get habitColorOptions {
    final dark = isDark;
    return ColorService.habitColorSpecs.entries.map((entry) {
      final spec = entry.value;
      return HabitColorChoice(
        name: entry.key,
        color: dark ? spec.dark : spec.light,
        textColor: dark ? spec.darkText : spec.lightText,
      );
    }).toList();
  }

  // Helpers
  Brightness get brightness => isDark ? Brightness.dark : Brightness.light;
}
