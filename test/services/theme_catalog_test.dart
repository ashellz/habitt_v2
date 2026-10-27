import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitt/models/app_theme.dart';
import 'package:habitt/services/color_service.dart';
import 'package:habitt/services/theme_catalog.dart';

// OKLCH hue in degrees, the space the guardrails are defined in.
double _oklchHue(Color color) {
  double lin(double c) =>
      c <= 0.04045 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
  final r = lin(color.r), g = lin(color.g), b = lin(color.b);
  final l = math.pow(
    0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b,
    1 / 3,
  );
  final m = math.pow(
    0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b,
    1 / 3,
  );
  final s = math.pow(
    0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b,
    1 / 3,
  );
  final a = 1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s;
  final bb = 0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s;
  return (math.atan2(bb, a) * 180 / math.pi + 360) % 360;
}

double _hueGap(double a, double b) {
  final d = (a - b).abs() % 360;
  return d > 180 ? 360 - d : d;
}

double _contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  // semantic colours the accent must stay away from: fail red and the
  // amber/streak orange band
  const reservedHues = [23.0, 50.0, 71.0];
  const minHueGap = 35.0;

  group('catalog', () {
    test('ids are unique', () {
      final ids = ThemeCatalog.all.map((t) => t.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('Habitt comes first and is the default', () {
      expect(ThemeCatalog.all.first, ThemeCatalog.habitt);
      expect(ThemeCatalog.byId(null), ThemeCatalog.habitt);
    });

    test('an unknown id falls back to Habitt', () {
      expect(ThemeCatalog.byId('nope'), ThemeCatalog.habitt);
    });

    test('every theme is found by its own id', () {
      for (final theme in ThemeCatalog.all) {
        expect(ThemeCatalog.byId(theme.id), theme);
      }
    });

    test('Habitt equals the original brand constants', () {
      expect(ThemeCatalog.habitt.light.main, const Color(0xFF02D382));
      expect(
        ThemeCatalog.habitt.light.buttonLeft,
        Light.mainButtonLeftGradient,
      );
      expect(
        ThemeCatalog.habitt.light.buttonRight,
        Light.mainButtonRightGradient,
      );
      expect(ThemeCatalog.habitt.dark.main, const Color(0xFF11F29B));
      expect(ThemeCatalog.habitt.dark.buttonLeft, Dark.mainButtonLeftGradient);
      expect(
        ThemeCatalog.habitt.dark.buttonRight,
        Dark.mainButtonRightGradient,
      );
    });
  });

  group('brand guardrails', () {
    void forEachAccent(
      void Function(AppTheme theme, String mode, AccentSet a) f,
    ) {
      for (final theme in ThemeCatalog.all) {
        f(theme, 'light', theme.light);
        f(theme, 'dark', theme.dark);
      }
    }

    test('no accent sits near the fail red or the streak orange', () {
      forEachAccent((theme, mode, accent) {
        final hue = _oklchHue(accent.main);
        for (final reserved in reservedHues) {
          expect(
            _hueGap(hue, reserved),
            greaterThanOrEqualTo(minHueGap),
            reason: '${theme.id} $mode hue ${hue.round()} vs $reserved',
          );
        }
      });
    });

    test('light accents are no lighter than the brand', () {
      // white on the accent: Habitt itself is ~2:1, never go below that
      forEachAccent((theme, mode, accent) {
        if (mode != 'light') return;
        expect(
          _contrast(accent.main, Colors.white),
          greaterThanOrEqualTo(1.9),
          reason: theme.id,
        );
      });
    });

    test('dark accents stand out from the dark background', () {
      forEachAccent((theme, mode, accent) {
        if (mode != 'dark') return;
        expect(
          _contrast(accent.main, Dark.bg),
          greaterThanOrEqualTo(4.5),
          reason: theme.id,
        );
      });
    });

    test('a theme looks different from the brand', () {
      for (final theme in ThemeCatalog.all.skip(1)) {
        expect(
          _hueGap(
            _oklchHue(theme.light.main),
            _oklchHue(ThemeCatalog.habitt.light.main),
          ),
          greaterThanOrEqualTo(25),
          reason: theme.id,
        );
      }
    });
  });
}
