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

Future<void> _pumpHost(
  WidgetTester tester, {
  required double contentHeight,
  bool withButtons = false,
}) async {
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
                              overrideDefaultButtons: !withButtons,
                              child: SizedBox(
                                height: contentHeight,
                                child: const Align(
                                  alignment: Alignment.topCenter,
                                  child: Text('content top'),
                                ),
                              ),
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

void _useTallPhone(WidgetTester tester) {
  tester.view.physicalSize = const Size(400, 800);
  tester.view.devicePixelRatio = 1;
  tester.view.padding = const FakeViewPadding(top: _statusBarHeight);
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('a tall sheet stops below the status bar, and only its content '
      'scrolls', (tester) async {
    _useTallPhone(tester);
    await _pumpHost(tester, contentHeight: 2000);
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(
      tester.getTopLeft(find.byType(NewDefaultDialog)).dy,
      greaterThanOrEqualTo(_statusBarHeight),
    );

    final cardTop = tester.getTopLeft(find.byType(NewDefaultDialog));
    final cardSize = tester.getSize(find.byType(NewDefaultDialog));
    final titleTop = tester.getTopLeft(find.text('Tall sheet'));
    final contentTop = tester.getTopLeft(find.text('content top'));

    await tester.drag(find.text('content top'), const Offset(0, -300));
    await tester.pumpAndSettle();

    // the card and its title stay put, the content moves
    expect(tester.getTopLeft(find.byType(NewDefaultDialog)), cardTop);
    expect(tester.getSize(find.byType(NewDefaultDialog)), cardSize);
    expect(tester.getTopLeft(find.text('Tall sheet')), titleTop);
    expect(
      tester.getTopLeft(find.text('content top')).dy,
      lessThan(contentTop.dy),
    );
  });

  testWidgets('the buttons stay on screen under a tall content', (
    tester,
  ) async {
    _useTallPhone(tester);
    await _pumpHost(tester, contentHeight: 2000, withButtons: true);
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final done = find.text('Done');
    expect(done, findsOneWidget);
    expect(tester.getBottomLeft(done).dy, lessThanOrEqualTo(800));

    final doneTop = tester.getTopLeft(done);
    await tester.drag(find.text('content top'), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(done), doneTop);
  });

  testWidgets('a short sheet is not stretched', (tester) async {
    _useTallPhone(tester);
    await _pumpHost(tester, contentHeight: 100);
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(tester.getSize(find.byType(NewDefaultDialog)).height, lessThan(400));
  });
}
