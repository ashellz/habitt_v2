import 'package:flutter/material.dart';
import 'package:habitt/services/old_color_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// DEPRECATED - no longer used, ignore, will delete later

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
          ? OldColorService.accentDark[accentName]
          : OldColorService.accentLight[accentName];

  // Core colors (primary derived from accent selection)
  Color get primaryColor =>
      (_accentPalette?.primary) ??
      (isDark ? OldColorService.dmPrimary : OldColorService.primary);
  Color get primaryVariant =>
      (_accentPalette?.primaryVariant) ??
      (isDark
          ? OldColorService.dmPrimaryVariant
          : OldColorService.primaryVariant);
  Color get secondaryColor =>
      (_accentPalette?.secondary) ??
      (isDark ? OldColorService.dmSecondary : OldColorService.secondary);
  Color get successColor =>
      isDark ? OldColorService.dmSuccess : OldColorService.success;
  Color get warningColor =>
      isDark ? OldColorService.dmWarning : OldColorService.warning;
  Color get dangerColor =>
      isDark ? OldColorService.dmDanger : OldColorService.danger;

  // Backgrounds / surfaces
  Color get backgroundColor =>
      isDark ? OldColorService.dmBgDefault : OldColorService.bgDefault;
  Color get surfaceColor =>
      isDark ? OldColorService.dmBgSurface : OldColorService.bgSurface;
  Color get elevatedSurfaceColor =>
      (_accentPalette?.bgElevated) ??
      (isDark ? OldColorService.dmBgElevated : OldColorService.bgElevated);
  Color get mutedBgColor =>
      isDark ? OldColorService.dmBgMuted : OldColorService.bgMuted;
  Color get nestedSurfaceColor =>
      isDark ? OldColorService.dmNestedSurface : OldColorService.nestedSurface;

  // Borders & focus
  Color get borderColor =>
      isDark ? OldColorService.dmBorder : OldColorService.border;
  Color get focusColor =>
      (_accentPalette?.focus) ??
      (isDark ? OldColorService.dmFocus : OldColorService.focus);

  // Text colors
  Color get primaryTextColor =>
      isDark ? OldColorService.dmTextPrimary : OldColorService.textPrimary;
  Color get secondaryTextColor =>
      isDark ? OldColorService.dmTextSecondary : OldColorService.textSecondary;
  Color get mutedTextColor =>
      isDark ? OldColorService.dmTextMuted : OldColorService.textMuted;
  Color get onPrimaryTextColor =>
      isDark ? OldColorService.dmTextOnPrimary : OldColorService.textOnPrimary;

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
      (isDark ? OldColorService.dmInfoBg : OldColorService.infoBg);
  Color get successBackground =>
      isDark ? OldColorService.dmSuccessBg : OldColorService.successBg;
  Color get warningBackground =>
      isDark ? OldColorService.dmWarningBg : OldColorService.warningBg;
  Color get errorBackground =>
      isDark ? OldColorService.dmErrorBg : OldColorService.errorBg;

  // Shadows & overlays
  Color get shadowTint =>
      (_accentPalette?.shadowTint) ??
      (isDark ? OldColorService.dmShadowTint : OldColorService.shadowTint);
  Color get modalOverlay =>
      isDark ? OldColorService.dmModalOverlay : OldColorService.modalOverlay;

  // Habit color presets resolved for current theme
  List<HabitColorChoice> get habitColorOptions {
    final dark = isDark;
    return OldColorService.habitColorSpecs.entries.map((entry) {
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
