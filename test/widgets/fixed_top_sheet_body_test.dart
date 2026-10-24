import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitt/providers/color_provider.dart';
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
}

double _fadeOpacity(WidgetTester tester) =>
    tester
        .widget<AnimatedOpacity>(
          find.descendant(
            of: find.byType(FixedTopSheetBody),
            matching: find.byType(AnimatedOpacity),
          ),
        )
        .opacity;

void main() {
  testWidgets('the top bar stays put while the content scrolls', (
    tester,
  ) async {
    await _pump(tester, contentHeight: 2000);

    final barTop = tester.getTopLeft(find.text('top bar'));
    final contentTop = tester.getTopLeft(find.text('content top'));

    await tester.drag(find.text('content top'), const Offset(0, -300));
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(find.text('top bar')), barTop);
    expect(
      tester.getTopLeft(find.text('content top')).dy,
      lessThan(contentTop.dy),
    );
  });

  testWidgets('the edge fade only shows once the content has scrolled', (
    tester,
  ) async {
    await _pump(tester, contentHeight: 2000);
    expect(_fadeOpacity(tester), 0);

    await tester.drag(find.text('content top'), const Offset(0, -100));
    await tester.pumpAndSettle();
    expect(_fadeOpacity(tester), 1);

    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, 400));
    await tester.pumpAndSettle();
    expect(_fadeOpacity(tester), 0);
  });

  testWidgets('short content does not scroll and shows no fade', (
    tester,
  ) async {
    await _pump(tester, contentHeight: 50);

    await tester.drag(find.text('content top'), const Offset(0, -100));
    await tester.pumpAndSettle();

    expect(_fadeOpacity(tester), 0);
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

    expect(_fadeOpacity(tester), 0);
  });
}
