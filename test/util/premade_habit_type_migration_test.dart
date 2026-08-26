import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:habitt/hive/hive_adapters.dart';
import 'package:habitt/hive/hive_registrar.g.dart';
import 'package:habitt/models/day.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/models/premade_habit_type.dart';
import 'package:habitt/util/premade_habit_type_migration.dart';
import 'package:hive_ce/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../fixtures/habit_factory.dart';

const _migratedKey = 'premadeWorkoutTypesMigrated_v1';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Box<Habit> habitBox;
  late Box<Day> daysBox;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('premade_type_migration');
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
    await migratePremadeWorkoutTypes(
      habitBox: habitBox,
      daysBox: daysBox,
      prefs: prefs,
    );
    return prefs;
  }

  test('fresh install with no data sets flag and does not crash', () async {
    final prefs = await run();
    expect(prefs.getBool(_migratedKey), isTrue);
  });

  test('running/walk/gym retype to their Workouts equivalents', () async {
    final running = buildTestHabit(
      id: 1,
      premadeHabitType: PremadeHabitType.running,
    );
    final walk = buildTestHabit(id: 2, premadeHabitType: PremadeHabitType.walk);
    final gym = buildTestHabit(id: 3, premadeHabitType: PremadeHabitType.gym);
    final untouched = buildTestHabit(
      id: 4,
      premadeHabitType: PremadeHabitType.drinkWater,
    );
    await habitBox.addAll([running, walk, gym, untouched]);

    await run();

    expect(habitBox.getAt(0)!.premadeHabitType, PremadeHabitType.workoutRunning);
    expect(habitBox.getAt(1)!.premadeHabitType, PremadeHabitType.workoutWalking);
    expect(habitBox.getAt(2)!.premadeHabitType, PremadeHabitType.workoutCombined);
    expect(habitBox.getAt(3)!.premadeHabitType, PremadeHabitType.drinkWater);
  });

  test('retypes habits embedded in day snapshots', () async {
    await daysBox.put(
      '2026-07-18',
      Day(
        date: DateTime(2026, 7, 18),
        habits: [
          buildTestHabit(id: 5, premadeHabitType: PremadeHabitType.gym),
        ],
        timestamp: DateTime.utc(2026, 7, 18),
      ),
    );

    await run();

    expect(
      daysBox.get('2026-07-18')!.habits.first.premadeHabitType,
      PremadeHabitType.workoutCombined,
    );
  });

  test('second run is a no-op', () async {
    final gym = buildTestHabit(id: 6, premadeHabitType: PremadeHabitType.gym);
    await habitBox.add(gym);

    await run();
    // Manually revert to simulate a type that would only exist due to a bug
    // re-applying the migration; the flag must prevent a second pass.
    habitBox.getAt(0)!.premadeHabitType = PremadeHabitType.gym;
    await habitBox.getAt(0)!.save();

    await run();

    expect(habitBox.getAt(0)!.premadeHabitType, PremadeHabitType.gym);
  });
}
