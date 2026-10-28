import 'package:flutter/material.dart';
import 'package:habitt/models/app_theme.dart';
import 'package:habitt/services/color_service.dart';

/// The themes a user can pick. All are free for everyone.
///
/// Rules for adding one (enforced by `test/services/theme_catalog_test.dart`):
/// - Keep the hue away from the semantic colours: `fail` red (~23°) and the
///   amber/streak orange (~50–71°), ≥ 35° in OKLCH. `main` marks completion, so
///   a red or orange accent would make done look failed or like a streak.
/// - Light accents are no lighter than the brand's (white-on-accent contrast of
///   Habitt is ~2:1); dark accents keep ≥ 4.5:1 against the dark background.
/// - Take lightness near the hue's chroma peak (brand-like vividness) rather
///   than the brand's own lightness, which would wash out blues and violets.
class ThemeCatalog {
  /// The brand and the default. Built from the same constants the app has
  /// always used, so it renders exactly as before.
  static const AppTheme habitt = AppTheme(
    id: 'habitt',
    light: AccentSet(
      main: Light.main,
      buttonLeft: Light.mainButtonLeftGradient,
      buttonRight: Light.mainButtonRightGradient,
    ),
    dark: AccentSet(
      main: Dark.main,
      buttonLeft: Dark.mainButtonLeftGradient,
      buttonRight: Dark.mainButtonRightGradient,
    ),
  );

  static const AppTheme lagoon = AppTheme(
    id: 'lagoon',
    light: AccentSet(
      main: Color(0xFF00CBCE),
      buttonLeft: Color(0xFF00CBCE),
      buttonRight: Color(0xFF02BBBE),
    ),
    dark: AccentSet(
      main: Color(0xFF09EAEE),
      buttonLeft: Color(0xFF30F6FA),
      buttonRight: Color(0xFF03E1E4),
    ),
  );

  static const AppTheme ocean = AppTheme(
    id: 'ocean',
    light: AccentSet(
      main: Color(0xFF09A3FD),
      buttonLeft: Color(0xFF09A3FD),
      buttonRight: Color(0xFF0495E9),
    ),
    dark: AccentSet(
      main: Color(0xFF3CACFF),
      buttonLeft: Color(0xFF5EB8FF),
      buttonRight: Color(0xFF31A4F6),
    ),
  );

  static const AppTheme indigo = AppTheme(
    id: 'indigo',
    light: AccentSet(
      main: Color(0xFF5D73EA),
      buttonLeft: Color(0xFF5D73EA),
      buttonRight: Color(0xFF5367D5),
    ),
    dark: AccentSet(
      main: Color(0xFF859DFE),
      buttonLeft: Color(0xFF94AAFF),
      buttonRight: Color(0xFF7E95F5),
    ),
  );

  static const AppTheme violet = AppTheme(
    id: 'violet',
    light: AccentSet(
      main: Color(0xFF955FD8),
      buttonLeft: Color(0xFF955FD8),
      buttonRight: Color(0xFF8755C4),
    ),
    dark: AccentSet(
      main: Color(0xFFBA86FF),
      buttonLeft: Color(0xFFC297FE),
      buttonRight: Color(0xFFB27EF6),
    ),
  );

  static const AppTheme orchid = AppTheme(
    id: 'orchid',
    light: AccentSet(
      main: Color(0xFFDA62B7),
      buttonLeft: Color(0xFFDA62B7),
      buttonRight: Color(0xFFC858A8),
    ),
    dark: AccentSet(
      main: Color(0xFFF16BCA),
      buttonLeft: Color(0xFFFD77D6),
      buttonRight: Color(0xFFE863C2),
    ),
  );

  /// In picker order, the brand first.
  static const List<AppTheme> all = [
    habitt,
    lagoon,
    ocean,
    indigo,
    violet,
    orchid,
  ];

  /// The theme with [id], or Habitt for a missing or unknown id.
  static AppTheme byId(String? id) =>
      all.firstWhere((theme) => theme.id == id, orElse: () => habitt);
}
