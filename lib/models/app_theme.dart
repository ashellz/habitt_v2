import 'package:flutter/material.dart';

/// The accent role of the app for one brightness: the colour of completed
/// things, primary buttons and selections, and the button's gradient pair.
/// Everything else (neutrals, fail/mid, streak orange) is fixed across themes.
@immutable
class AccentSet {
  const AccentSet({
    required this.main,
    required this.buttonLeft,
    required this.buttonRight,
  });

  final Color main;
  final Color buttonLeft;
  final Color buttonRight;
}

/// A selectable theme. Themes only swap the accent, so every one of them is
/// still recognisably Habitt. See `docs/themes.md` for the guardrails.
@immutable
class AppTheme {
  const AppTheme({required this.id, required this.light, required this.dark});

  /// Stored in preferences, never change an existing id.
  final String id;
  final AccentSet light;
  final AccentSet dark;

  AccentSet accent({required bool isDark}) => isDark ? dark : light;
}
