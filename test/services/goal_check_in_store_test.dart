import 'package:flutter_test/flutter_test.dart';
import 'package:habitt/services/goal_check_in_analyzer.dart';
import 'package:habitt/services/goal_check_in_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late DateTime now;
  late SharedPreferences prefs;
  GoalCheckInStore store() => GoalCheckInStore(prefs, clock: () => now);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    now = DateTime(2026, 11, 25, 9);
  });

  test('weekly sheet is due when never shown, then after 7 days', () async {
    expect(store().weeklyDue, isTrue);
    await store().markShown();
    now = now.add(const Duration(days: 3));
    expect(store().weeklyDue, isFalse);
    now = now.add(const Duration(days: 4));
    expect(store().weeklyDue, isTrue);
  });

  test('not now blocks one direction for 14 days', () async {
    await store().startCooldown(1, [GoalDirection.lower]);
    expect(store().blocked(1), {GoalDirection.lower});
    expect(store().blocked(2), isEmpty);
    now = now.add(const Duration(days: 15));
    expect(store().blocked(1), isEmpty);
  });

  test('undo clears a cooldown', () async {
    await store().startCooldown(1, GoalDirection.values);
    await store().clearCooldown(1, GoalDirection.values);
    expect(store().blocked(1), isEmpty);
  });

  test('lighter-day sheet is shown once per habit per day', () async {
    expect(store().lighterShownToday(1), isFalse);
    await store().markLighterShown(1);
    expect(store().lighterShownToday(1), isTrue);
    now = now.add(const Duration(days: 1));
    expect(store().lighterShownToday(1), isFalse);
  });
}
