import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/util/show_dialog_sheet.dart';
import 'package:habitt/widgets/default/fading_scroll_view.dart';
import 'package:habitt/widgets/default/new_default_dialog.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const double _statusBarHeight = 59;

Future<void> _pumpHost(
  WidgetTester tester, {
  required double contentHeight,
  bool withButtons = false,
  bool showCloseButton = false,
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
                              showCloseButton: showCloseButton,
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

double _fade(WidgetTester tester, Key key) =>
    tester.widget<AnimatedOpacity>(find.byKey(key)).opacity;

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a tall dialog keeps its card, scrolls everything inside it and '
      'fades the edges', (tester) async {
    _useTallPhone(tester);
    await _pumpHost(tester, contentHeight: 2000);
    await _open(tester);

    expect(
      tester.getTopLeft(find.byType(NewDefaultDialog)).dy,
      greaterThanOrEqualTo(_statusBarHeight),
    );
    expect(_fade(tester, FadingScrollView.topFadeKey), 0);
    expect(_fade(tester, FadingScrollView.bottomFadeKey), 1);

    final cardTop = tester.getTopLeft(find.byType(NewDefaultDialog));
    final cardSize = tester.getSize(find.byType(NewDefaultDialog));
    final titleTop = tester.getTopLeft(find.text('Tall sheet'));

    await tester.drag(find.text('content top'), const Offset(0, -300));
    await tester.pumpAndSettle();

    // the card stays, the title scrolls away with the content
    expect(tester.getTopLeft(find.byType(NewDefaultDialog)), cardTop);
    expect(tester.getSize(find.byType(NewDefaultDialog)), cardSize);
    expect(
      tester.getTopLeft(find.text('Tall sheet')).dy,
      lessThan(titleTop.dy),
    );
    expect(_fade(tester, FadingScrollView.topFadeKey), 1);
  });

  testWidgets('the buttons stay on screen under a tall content', (
    tester,
  ) async {
    _useTallPhone(tester);
    await _pumpHost(tester, contentHeight: 2000, withButtons: true);
    await _open(tester);

    final done = find.text('Done');
    expect(done, findsOneWidget);
    expect(tester.getBottomLeft(done).dy, lessThanOrEqualTo(800));

    final doneTop = tester.getTopLeft(done);
    await tester.drag(find.text('content top'), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(done), doneTop);
  });

  testWidgets('a header with a close button stays pinned', (tester) async {
    _useTallPhone(tester);
    await _pumpHost(tester, contentHeight: 2000, showCloseButton: true);
    await _open(tester);

    final titleTop = tester.getTopLeft(find.text('Tall sheet'));
    final contentTop = tester.getTopLeft(find.text('content top'));

    await tester.drag(find.text('content top'), const Offset(0, -300));
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(find.text('Tall sheet')), titleTop);
    expect(
      tester.getTopLeft(find.text('content top')).dy,
      lessThan(contentTop.dy),
    );
  });

  testWidgets('a short dialog is not stretched and shows no fade', (
    tester,
  ) async {
    _useTallPhone(tester);
    await _pumpHost(tester, contentHeight: 100);
    await _open(tester);

    expect(tester.getSize(find.byType(NewDefaultDialog)).height, lessThan(400));
    expect(_fade(tester, FadingScrollView.topFadeKey), 0);
    expect(_fade(tester, FadingScrollView.bottomFadeKey), 0);
  });
}
