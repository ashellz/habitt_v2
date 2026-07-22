import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:habitt/hive/hive_adapters.dart';
import 'package:habitt/hive/hive_registrar.g.dart';
import 'package:habitt/models/day.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/util/duration_seconds_migration.dart';
import 'package:hive_ce/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../fixtures/habit_factory.dart';

const _habitsKey = 'durationSecondsMigrated_habits_v1';
const _daysKey = 'durationSecondsMigrated_days_v1';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Box<Habit> habitBox;
  late Box<Day> daysBox;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('duration_seconds_test');
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

  setUp(() async {
    await habitBox.clear();
    await daysBox.clear();
    SharedPreferences.setMockInitialValues({});
  });

  tearDownAll(() async {
    await habitBox.close();
    await daysBox.close();
    await tempDir.delete(recursive: true);
  });

  Future<SharedPreferences> run() async {
    final prefs = await SharedPreferences.getInstance();
    await migrateDurationToSeconds(
      habitBox: habitBox,
      daysBox: daysBox,
      prefs: prefs,
    );
    return prefs;
  }

  test('fresh install with no data sets flags and does not crash', () async {
    final prefs = await run();
    expect(prefs.getBool(_habitsKey), isTrue);
    expect(prefs.getBool(_daysKey), isTrue);
  });

  test('legacy minutes convert once to seconds (habits + day snapshots)',
      () async {
    final habit = buildTestHabit(
      id: 7,
      duration: 30,
      durationCompleted: 5,
      trackingType: HabitTrackingType.duration,
    );
    await habitBox.add(habit);

    final daySnapshotHabit = buildTestHabit(
      id: 7,
      duration: 30,
      durationCompleted: 12,
      trackingType: HabitTrackingType.duration,
    );
    await daysBox.put(
      '2026-07-18',
      Day(
        date: DateTime(2026, 7, 18),
        habits: [daySnapshotHabit],
        timestamp: DateTime.utc(2026, 7, 18),
      ),
    );

    await run();

    expect(habitBox.getAt(0)!.duration, 1800);
    expect(habitBox.getAt(0)!.durationCompleted, 300);
    expect(daysBox.get('2026-07-18')!.habits.first.duration, 1800);
    expect(daysBox.get('2026-07-18')!.habits.first.durationCompleted, 720);
  });

  test('second run is a no-op (does not multiply again)', () async {
    final habit = buildTestHabit(
      id: 1,
      duration: 30,
      durationCompleted: 5,
      trackingType: HabitTrackingType.duration,
    );
    await habitBox.add(habit);

    await run(); // 30 → 1800
    await run(); // must stay 1800

    expect(habitBox.getAt(0)!.duration, 1800);
    expect(habitBox.getAt(0)!.durationCompleted, 300);
  });

  test('interrupted run (days flag unset) does not re-multiply habits',
      () async {
    final habit = buildTestHabit(
      id: 1,
      duration: 30,
      durationCompleted: 0,
      trackingType: HabitTrackingType.duration,
    );
    await habitBox.add(habit);
    await daysBox.put(
      '2026-07-18',
      Day(
        date: DateTime(2026, 7, 18),
        habits: [
          buildTestHabit(
            id: 1,
            duration: 30,
            durationCompleted: 0,
            trackingType: HabitTrackingType.duration,
          ),
        ],
        timestamp: DateTime.utc(2026, 7, 18),
      ),
    );

    // Simulate a prior run that finished the habits box but crashed before
    // the days box: habits already converted + flagged, days still legacy.
    habitBox.getAt(0)!
      ..duration = 1800
      ..durationCompleted = 0;
    await habitBox.getAt(0)!.save();
    SharedPreferences.setMockInitialValues({_habitsKey: true});

    await run();

    // Habits untouched (already seconds), days now converted.
    expect(habitBox.getAt(0)!.duration, 1800);
    expect(daysBox.get('2026-07-18')!.habits.first.duration, 1800);
  });
}
