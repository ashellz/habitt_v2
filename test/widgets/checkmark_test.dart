import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/services/theme_catalog.dart';
import 'package:habitt/widgets/default/checkmark.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Color _greenAsLoaded(WidgetTester tester) {
  final loader =
      tester.widget<SvgPicture>(find.byType(SvgPicture)).bytesLoader
          as SvgAssetLoader;
  return loader.colorMapper!.substitute(
    null,
    'path',
    'fill',
    const Color(0xFF02D382),
  );
}

Future<ColorProvider> _pump(
  WidgetTester tester, {
  required bool secondary,
  required bool dark,
}) async {
  SharedPreferences.setMockInitialValues({
    'color_mode': (dark ? ColorMode.dark : ColorMode.light).toString(),
    'app_theme_id': 'ocean',
  });
  final prefs = await SharedPreferences.getInstance();
  final cp = ColorProvider(prefs);
  await tester.pumpWidget(
    ChangeNotifierProvider<ColorProvider>.value(
      value: cp,
      child: MaterialApp(
        home: Scaffold(
          body: Checkmark(value: true, secondaryCheckmarks: secondary),
        ),
      ),
    ),
  );
  await tester.pump();
  return cp;
}

void main() {
  for (final dark in [false, true]) {
    for (final secondary in [false, true]) {
      testWidgets(
        'a checked mark follows the theme '
        '(${dark ? 'dark' : 'light'}, ${secondary ? 'on a button' : 'on a habit'})',
        (tester) async {
          final cp = await _pump(tester, secondary: secondary, dark: dark);

          expect(
            _greenAsLoaded(tester),
            ThemeCatalog.ocean.accent(isDark: dark).main,
          );
          cp.dispose();
        },
      );
    }
  }
}
