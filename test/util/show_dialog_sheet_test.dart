import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/util/show_dialog_sheet.dart';
import 'package:habitt/widgets/default/new_default_dialog.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const double _statusBarHeight = 59;

Future<void> _pumpHost(WidgetTester tester, {required double contentHeight}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ChangeNotifierProvider(
      create: (_) => ColorProvider(prefs),
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder:
              (context) => Scaffold(
                body: TextButton(
                  onPressed:
                      () => showDialogSheet<void>(
                        context: context,
                        builder:
                            (_) => NewDefaultDialog(
                              title: 'Tall sheet',
                              overrideDefaultButtons: true,
                              child: SizedBox(height: contentHeight),
                            ),
                      ),
                  child: const Text('open'),
                ),
              ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('a sheet taller than the screen stops below the status bar '
      'and scrolls', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: _statusBarHeight);
    addTearDown(tester.view.reset);

    await _pumpHost(tester, contentHeight: 2000);
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final sheetTop = tester.getTopLeft(find.byType(NewDefaultDialog)).dy;
    expect(sheetTop, greaterThanOrEqualTo(_statusBarHeight));

    final scrollable = tester.state<ScrollableState>(
      find.descendant(
        of: find.byType(NewDefaultDialog),
        matching: find.byType(Scrollable),
      ),
    );
    expect(scrollable.position.maxScrollExtent, greaterThan(0));
  });

  testWidgets('a short sheet is not stretched', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: _statusBarHeight);
    addTearDown(tester.view.reset);

    await _pumpHost(tester, contentHeight: 100);
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(tester.getSize(find.byType(NewDefaultDialog)).height, lessThan(400));
  });
}
