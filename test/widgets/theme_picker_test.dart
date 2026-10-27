import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/services/theme_catalog.dart';
import 'package:habitt/widgets/default/accent_svg.dart';
import 'package:habitt/widgets/settings/theme_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

late ColorProvider _cp;

Future<void> _pump(WidgetTester tester, Widget body) async {
  SharedPreferences.setMockInitialValues({
    'color_mode': ColorMode.light.toString(),
  });
  final prefs = await SharedPreferences.getInstance();
  _cp = ColorProvider(prefs);

  await tester.pumpWidget(
    ChangeNotifierProvider<ColorProvider>.value(
      value: _cp,
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: SingleChildScrollView(child: body)),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('lists every theme, the brand first', (tester) async {
    await _pump(tester, const ThemePicker());

    for (final name in [
      'Habitt',
      'Lagoon',
      'Ocean',
      'Indigo',
      'Violet',
      'Orchid',
    ]) {
      expect(find.text(name), findsOneWidget);
    }
    expect(
      tester.getTopLeft(find.text('Habitt')).dx,
      lessThan(tester.getTopLeft(find.text('Lagoon')).dx),
    );
    _cp.dispose();
  });

  testWidgets('tapping a theme selects it', (tester) async {
    await _pump(tester, const ThemePicker());
    expect(_cp.theme, ThemeCatalog.habitt);

    await tester.tap(find.text('Ocean'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(_cp.theme, ThemeCatalog.ocean);
    _cp.dispose();
  });

  testWidgets('AccentSvg swaps the baked-in greens for the accent', (
    tester,
  ) async {
    await _pump(
      tester,
      const AccentSvg('assets/images/new-svg/check-on-light.svg'),
    );
    _cp.setTheme(ThemeCatalog.violet);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final loader =
        tester.widget<SvgPicture>(find.byType(SvgPicture)).bytesLoader
            as SvgAssetLoader;
    final mapper = loader.colorMapper!;
    Color map(Color c) => mapper.substitute(null, 'path', 'fill', c);

    expect(map(const Color(0xFF02D382)), _cp.main);
    expect(map(const Color(0xFF11F29B)), _cp.main);
    // anything else is left alone
    expect(map(const Color(0xFF0C0C0C)), const Color(0xFF0C0C0C));
    _cp.dispose();
  });
}
