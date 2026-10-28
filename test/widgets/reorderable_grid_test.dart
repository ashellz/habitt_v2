import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitt/widgets/default/reorderable_grid.dart';

// 2 columns of 100px squares with a 10px gap: slot centres at 50 and 160
Future<List<(int, int)>> _pumpGrid(
  WidgetTester tester, {
  int count = 4,
  VoidCallback? onTapFirst,
}) async {
  final reorders = <(int, int)>[];
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: ReorderableGrid(
            itemSize: 100,
            onReorder:
                (oldIndex, newIndex) => reorders.add((oldIndex, newIndex)),
            children: [
              for (int i = 0; i < count; i++)
                GestureDetector(
                  key: ValueKey(i),
                  onTap: i == 0 ? onTapFirst : null,
                  child: ColoredBox(color: Colors.blue, child: Text('$i')),
                ),
            ],
          ),
        ),
      ),
    ),
  );
  return reorders;
}

Future<void> _drag(WidgetTester tester, Offset from, Offset to) async {
  final gesture = await tester.startGesture(from);
  await tester.pump(const Duration(milliseconds: 350));
  const steps = 12;
  for (int i = 0; i < steps; i++) {
    await gesture.moveBy((to - from) / steps.toDouble());
    await tester.pump(const Duration(milliseconds: 16));
  }
  await gesture.up();
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('dragging the first item onto the last slot reports 0 → 3', (
    tester,
  ) async {
    final reorders = await _pumpGrid(tester);
    await _drag(tester, const Offset(50, 50), const Offset(160, 160));
    expect(reorders, [(0, 3)]);
  });

  testWidgets('dragging the last item to the front reports 3 → 0', (
    tester,
  ) async {
    final reorders = await _pumpGrid(tester);
    await _drag(tester, const Offset(160, 160), const Offset(50, 50));
    expect(reorders, [(3, 0)]);
  });

  testWidgets('dropping back on its own slot reports nothing', (tester) async {
    final reorders = await _pumpGrid(tester);
    await _drag(tester, const Offset(50, 50), const Offset(70, 60));
    expect(reorders, isEmpty);
  });

  testWidgets('the moved item settles into its new slot', (tester) async {
    await _pumpGrid(tester);
    await _drag(tester, const Offset(50, 50), const Offset(160, 50));
    expect(tester.getTopLeft(find.text('0')), const Offset(110, 0));
    expect(tester.getTopLeft(find.text('1')), Offset.zero);
  });

  testWidgets('a tap still reaches the item', (tester) async {
    int taps = 0;
    final reorders = await _pumpGrid(tester, onTapFirst: () => taps++);
    await tester.tapAt(const Offset(50, 50));
    await tester.pumpAndSettle();
    expect(taps, 1);
    expect(reorders, isEmpty);
  });
}
