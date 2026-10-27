import 'package:flutter_test/flutter_test.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/services/color_service.dart';
import 'package:habitt/services/theme_catalog.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ColorProvider> _build(Map<String, Object> values) async {
  SharedPreferences.setMockInitialValues(values);
  final prefs = await SharedPreferences.getInstance();
  return ColorProvider(prefs);
}

void main() {
  testWidgets('a fresh install is on Habitt, exactly as before', (
    tester,
  ) async {
    final light = await _build({'color_mode': ColorMode.light.toString()});
    expect(light.theme, ThemeCatalog.habitt);
    expect(light.main, Light.main);
    expect(light.mainButtonLeftGradient, Light.mainButtonLeftGradient);
    expect(light.mainButtonRightGradient, Light.mainButtonRightGradient);
    light.dispose();

    final dark = await _build({'color_mode': ColorMode.dark.toString()});
    expect(dark.main, Dark.main);
    expect(dark.mainButtonLeftGradient, Dark.mainButtonLeftGradient);
    dark.dispose();
  });

  testWidgets('everyone starts on Habitt whatever a legacy accent says', (
    tester,
  ) async {
    final provider = await _build({
      'color_mode': ColorMode.light.toString(),
      'accent_name': 'cherry',
    });
    expect(provider.theme, ThemeCatalog.habitt);
    provider.dispose();
  });

  testWidgets('an unknown stored theme falls back to Habitt', (tester) async {
    final provider = await _build({
      'color_mode': ColorMode.light.toString(),
      'app_theme_id': 'removed-theme',
    });
    expect(provider.theme, ThemeCatalog.habitt);
    provider.dispose();
  });

  testWidgets('setTheme changes only the accent and persists it', (
    tester,
  ) async {
    final provider = await _build({'color_mode': ColorMode.light.toString()});
    final bg = provider.bg;
    final text = provider.text;
    final fail = provider.fail;
    final orange300 = provider.orange300;

    provider.setTheme(ThemeCatalog.ocean);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(provider.theme, ThemeCatalog.ocean);
    expect(provider.main, ThemeCatalog.ocean.light.main);
    expect(
      provider.mainButtonLeftGradient,
      ThemeCatalog.ocean.light.buttonLeft,
    );
    expect(
      provider.mainButtonRightGradient,
      ThemeCatalog.ocean.light.buttonRight,
    );
    // everything that is not the accent stays put
    expect(provider.bg, bg);
    expect(provider.text, text);
    expect(provider.fail, fail);
    expect(provider.orange300, orange300);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('app_theme_id'), 'ocean');
    provider.dispose();
  });

  testWidgets(
    'the stored theme is applied on the next launch, in dark mode too',
    (tester) async {
      final provider = await _build({
        'color_mode': ColorMode.dark.toString(),
        'app_theme_id': 'violet',
      });
      expect(provider.theme.id, 'violet');
      expect(provider.main, ThemeCatalog.violet.dark.main);
      provider.dispose();
    },
  );

  testWidgets('the tints follow the accent', (tester) async {
    final provider = await _build({
      'color_mode': ColorMode.light.toString(),
      'app_theme_id': 'indigo',
    });
    expect(provider.mainTint, provider.main.withValues(alpha: 0.1));
    expect(provider.mainBorder, provider.main.withValues(alpha: 0.2));
    provider.dispose();
  });

  testWidgets('selecting the current theme does nothing', (tester) async {
    final provider = await _build({'color_mode': ColorMode.light.toString()});
    var notified = 0;
    provider.addListener(() => notified++);

    provider.setTheme(ThemeCatalog.habitt);
    await tester.pump();

    expect(notified, 0);
    provider.dispose();
  });
}
