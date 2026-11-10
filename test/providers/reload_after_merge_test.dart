import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:habitt/hive/hive_adapters.dart';
import 'package:habitt/hive/hive_registrar.g.dart';
import 'package:habitt/models/day.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:hive_ce/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../fixtures/habit_factory.dart';

// A sync merging delta files reloads the habits lightly after each merge and
// runs HabitProvider.init once at the end. The light reload still has to pick
// up habits the merge added (the reminder resync reads the habit list) and
// what it changed on today's habits, and redraw.

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Box<Habit> habitBox;
  late Box<Day> daysBox;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('reload_after_merge');
    Hive.init(tempDir.path);
    Hive.registerAdapters();
    Hive.registerAdapter(ScheduleTypeAdapter());
    Hive.registerAdapter(PremadeHabitTypeAdapter());
    Hive.registerAdapter(HabitTrackingTypeAdapter());
    Hive.registerAdapter(HabitNotificationTimeAdapter());
    Hive.registerAdapter(LegacyHabitTrackingTypeAdapter());
    habitBox = await Hive.openBox<Habit>('habits');
    daysBox = await Hive.openBox<Day>('days');
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  Future<HabitProvider> startProvider() async {
    SharedPreferences.setMockInitialValues({
      'lastNotificationSyncDate': today.toIso8601String().split('T').first,
      'daySnapshotsSanitized_v1': true,
    });
    await habitBox.clear();
    await daysBox.clear();
    await habitBox.add(buildTestHabit(id: 1, name: 'read', createdAt: today));
    final p = HabitProvider();
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (!p.isInitialized) {
      if (DateTime.now().isAfter(deadline)) fail('init timed out');
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    return p;
  }

  test('picks up a habit the merge added and redraws', () async {
    final p = await startProvider();
    var notified = 0;
    p.addListener(() => notified++);
    final versionBefore = p.dataVersion;

    // what the merge's master-record loop does for a habit new to this device
    await habitBox.add(buildTestHabit(id: 2, name: 'walk', createdAt: today));
    expect(p.habits.map((h) => h.id), [1]);

    p.reloadAfterMerge();

    expect(p.habits.map((h) => h.id), unorderedEquals([1, 2]));
    expect(p.todaysHabits.map((h) => h.id), unorderedEquals([1, 2]));
    expect(p.dataVersion, greaterThan(versionBefore));
    expect(notified, 1);
  });

  test('today shows what the merge put on the live habit', () async {
    final p = await startProvider();
    final live = habitBox.values.single;

    // rehydrate copies a completion merged from the other device
    live.completed = true;
    p.reloadAfterMerge();

    expect(p.todaysHabits.single.completed, isTrue);
  });
}
