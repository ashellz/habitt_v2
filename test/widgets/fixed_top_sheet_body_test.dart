import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/widgets/default/scroll_edge_fade.dart';
import 'package:habitt/widgets/default/fixed_top_sheet_body.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pump(
  WidgetTester tester, {
  required double contentHeight,
  Widget? extra,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ChangeNotifierProvider(
      create: (_) => ColorProvider(prefs),
      child: MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 500),
              child: FixedTopSheetBody(
                topBar: const SizedBox(height: 40, child: Text('top bar')),
                child: Column(
                  children: [
                    const Text('content top'),
                    SizedBox(height: contentHeight),
                    if (extra != null) extra,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  // the first scroll metrics arrive after the first layout
  await tester.pumpAndSettle();
}

double _fade(WidgetTester tester, Key key) =>
    tester.widget<TweenAnimationBuilder<double>>(find.byKey(key)).tween.end!;

double _topFade(WidgetTester tester) =>
    _fade(tester, ScrollEdgeFade.startFadeKey);

double _bottomFade(WidgetTester tester) =>
    _fade(tester, ScrollEdgeFade.endFadeKey);

Future<void> _dragSheet(WidgetTester tester, double dy) async {
  await tester.drag(find.byType(SingleChildScrollView), Offset(0, dy));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the top bar stays put while the content scrolls', (
    tester,
  ) async {
    await _pump(tester, contentHeight: 2000);

    final barTop = tester.getTopLeft(find.text('top bar'));
    final contentTop = tester.getTopLeft(find.text('content top'));

    await _dragSheet(tester, -300);

    expect(tester.getTopLeft(find.text('top bar')), barTop);
    expect(
      tester.getTopLeft(find.text('content top')).dy,
      lessThan(contentTop.dy),
    );
  });

  testWidgets('there is a gap between the top bar and the scrolling content', (
    tester,
  ) async {
    await _pump(tester, contentHeight: 2000);

    final barBottom =
        tester.getBottomLeft(find.widgetWithText(SizedBox, 'top bar')).dy;
    final scrollTop = tester.getTopLeft(find.byType(SingleChildScrollView)).dy;

    expect(scrollTop - barBottom, 10);
  });

  testWidgets('the fades show only on the edges that have more content', (
    tester,
  ) async {
    await _pump(tester, contentHeight: 2000);
    // at the top, more below
    expect(_topFade(tester), 0);
    expect(_bottomFade(tester), 1);

    await _dragSheet(tester, -100);
    expect(_topFade(tester), 1);
    expect(_bottomFade(tester), 1);

    await _dragSheet(tester, -5000);
    // at the very bottom
    expect(_topFade(tester), 1);
    expect(_bottomFade(tester), 0);

    await _dragSheet(tester, 5000);
    expect(_topFade(tester), 0);
    expect(_bottomFade(tester), 1);
  });

  testWidgets('short content does not scroll and shows no fade', (
    tester,
  ) async {
    await _pump(tester, contentHeight: 50);

    await _dragSheet(tester, -100);

    expect(_topFade(tester), 0);
    expect(_bottomFade(tester), 0);
    expect(
      tester.getSize(find.byType(FixedTopSheetBody)).height,
      lessThan(300),
    );
  });

  testWidgets('a scrollable inside the content does not trigger the fade', (
    tester,
  ) async {
    await _pump(
      tester,
      contentHeight: 50,
      extra: SizedBox(
        height: 60,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            for (var i = 0; i < 30; i++)
              SizedBox(width: 80, child: Text('item $i')),
          ],
        ),
      ),
    );

    await tester.drag(find.text('item 1'), const Offset(-200, 0));
    await tester.pumpAndSettle();

    expect(_topFade(tester), 0);
    expect(_bottomFade(tester), 0);
  });
}
