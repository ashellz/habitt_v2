import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/widgets/dialogs/whats_new_dialog.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ColorProvider> _pump(WidgetTester tester, {required bool dark}) async {
  SharedPreferences.setMockInitialValues({
    'color_mode': (dark ? ColorMode.dark : ColorMode.light).toString(),
  });
  final prefs = await SharedPreferences.getInstance();
  final cp = ColorProvider(prefs);
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ChangeNotifierProvider<ColorProvider>.value(
      value: cp,
      child: const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('en'),
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: WhatsNewDialog(),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return cp;
}

void main() {
  for (final dark in [false, true]) {
    testWidgets('pages through every feature without errors '
        '(${dark ? 'dark' : 'light'})', (tester) async {
      final cp = await _pump(tester, dark: dark);

      expect(find.text('Health sync'), findsOneWidget);
      expect(find.text('Got it'), findsOneWidget);

      final next = find.bySemanticsLabel('Next');
      for (final title in [
        'Habit alarms',
        'Daily Plan',
        'Strength over time',
        'New theme colors',
      ]) {
        await tester.tap(next);
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 800));
        // the strength graphic repeats its title inside the chart header
        expect(find.text(title), findsWidgets);
      }

      await tester.tap(find.byIcon(Icons.chevron_left_rounded));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 800));
      expect(find.text('Strength over time'), findsWidgets);

      expect(tester.takeException(), isNull);
      cp.dispose();
    });
  }
}
