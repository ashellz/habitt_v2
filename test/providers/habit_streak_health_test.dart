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

DateTime _normalize(DateTime date) => DateTime(date.year, date.month, date.day);

String _dayKey(DateTime date) =>
    _normalize(date).toIso8601String().split('T').first;

/// How a seeded day went for the habit.
enum _Outcome { completed, miss, partial }

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Box<Habit> habitBox;
  late Box<Day> daysBox;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('habit_streak_health_test');
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
    final today = _normalize(DateTime.now());
    SharedPreferences.setMockInitialValues({
      'lastNotificationSyncDate': _dayKey(today),
      'daySnapshotsSanitized_v1': true,
      'dateJoined': today.subtract(const Duration(days: 60)).toIso8601String(),
    });
    await habitBox.clear();
    await daysBox.clear();
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  Habit snapshot(int id, _Outcome outcome) {
    return buildTestHabit(
      id: id,
      amountCompleted: switch (outcome) {
        _Outcome.completed => 10,
        _Outcome.partial => 4,
        _Outcome.miss => 0,
      },
    )..completed = outcome == _Outcome.completed;
  }

  /// Seeds [history] (oldest → newest) onto the days immediately before today,
  /// so the newest entry lands on yesterday.
  Future<void> seedHistory(List<_Outcome> history, {int habitId = 1}) async {
    await habitBox.put(habitId, buildTestHabit(id: habitId));

    final today = _normalize(DateTime.now());
    for (int i = 0; i < history.length; i++) {
      final daysAgo = history.length - i;
      final date = today.subtract(Duration(days: daysAgo));
      await daysBox.put(
        _dayKey(date),
        Day(
          date: date,
          habits: [snapshot(habitId, history[i])],
          timestamp: DateTime.now().toUtc(),
        ),
      );
    }
  }

  Future<HabitProvider> createInitializedProvider() async {
    final provider = HabitProvider();
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (!provider.isInitialized) {
      if (DateTime.now().isAfter(deadline)) {
        fail('HabitProvider.init did not complete');
      }
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    return provider;
  }

  group('per-habit tail misses', () {
    test('completions more recent than the misses → tail is clean', () async {
      // The raw consecutiveMisses variable ends this walk holding 2, because it
      // resets on completion and then counts the older misses. The tail is 0.
      await seedHistory([
        _Outcome.miss,
        _Outcome.miss,
        _Outcome.completed,
        _Outcome.completed,
      ]);
      final provider = await createInitializedProvider();
      await provider.assignStreaks();

      expect(provider.consecutiveMissesFor(1), 0);
    });

    test('misses since the last completion are counted', () async {
      await seedHistory([
        _Outcome.completed,
        _Outcome.miss,
        _Outcome.miss,
      ]);
      final provider = await createInitializedProvider();
      await provider.assignStreaks();

      expect(provider.consecutiveMissesFor(1), 2);
    });

    test('three trailing misses → tolerance fully spent', () async {
      await seedHistory([
        _Outcome.completed,
        _Outcome.miss,
        _Outcome.miss,
        _Outcome.miss,
      ]);
      final provider = await createInitializedProvider();
      await provider.assignStreaks();

      expect(provider.consecutiveMissesFor(1), 3);
      expect(habitBox.get(1)!.streak, 0);
    });

    test('an unbroken run spends nothing', () async {
      await seedHistory([
        _Outcome.completed,
        _Outcome.completed,
        _Outcome.completed,
      ]);
      final provider = await createInitializedProvider();
      await provider.assignStreaks();

      expect(provider.consecutiveMissesFor(1), 0);
      expect(habitBox.get(1)!.streak, 3);
    });

    test(
      'partial progress resets the tail under current per-habit semantics',
      () async {
        // Divergent from the perfect-days rule by design; the freeze point is
        // tied to what actually resets tolerance so the badge never claims a
        // risk the engine would not act on. Unification is a separate change.
        await seedHistory([
          _Outcome.completed,
          _Outcome.miss,
          _Outcome.partial,
        ]);
        final provider = await createInitializedProvider();
        await provider.assignStreaks();

        expect(provider.consecutiveMissesFor(1), 0);
      },
    );

    test('unknown habit ids read as healthy', () async {
      await seedHistory([_Outcome.completed]);
      final provider = await createInitializedProvider();
      await provider.assignStreaks();

      expect(provider.consecutiveMissesFor(9999), 0);
    });

    test('single-habit recalculation leaves other entries intact', () async {
      final today = _normalize(DateTime.now());
      await habitBox.put(1, buildTestHabit(id: 1));
      await habitBox.put(2, buildTestHabit(id: 2));

      // Habit 1 has two trailing misses, habit 2 is clean.
      for (int daysAgo = 1; daysAgo <= 2; daysAgo++) {
        final date = today.subtract(Duration(days: daysAgo));
        await daysBox.put(
          _dayKey(date),
          Day(
            date: date,
            habits: [
              snapshot(1, _Outcome.miss),
              snapshot(2, _Outcome.completed),
            ],
            timestamp: DateTime.now().toUtc(),
          ),
        );
      }

      final provider = await createInitializedProvider();
      await provider.assignStreaks();
      expect(provider.consecutiveMissesFor(1), 2);
      expect(provider.consecutiveMissesFor(2), 0);

      // Recalculating habit 2 alone must not disturb habit 1's entry.
      await provider.assignStreaks(2);
      expect(provider.consecutiveMissesFor(1), 2);
      expect(provider.consecutiveMissesFor(2), 0);
    });
  });
}
