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

DateTime _normalize(DateTime date) =>
    DateTime(date.year, date.month, date.day);

String _dayKey(DateTime date) =>
    _normalize(date).toIso8601String().split('T').first;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Box<Habit> habitBox;
  late Box<Day> daysBox;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('day_progress_cache_test');
    Hive.init(tempDir.path);
    // Same registration set as main.dart.
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
    // Short-circuit init() side effects: notification sync already ran today,
    // day snapshots already sanitized.
    SharedPreferences.setMockInitialValues({
      'lastNotificationSyncDate': _dayKey(today),
      'daySnapshotsSanitized_v1': true,
      'dateJoined':
          today.subtract(const Duration(days: 60)).toIso8601String(),
    });
    await habitBox.clear();
    await daysBox.clear();
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  /// Seeds a past-day snapshot with a single amount habit at
  /// [amountCompleted]/10 progress.
  Future<void> seedDay(DateTime date, {required int amountCompleted}) async {
    await daysBox.put(
      _dayKey(date),
      Day(
        date: _normalize(date),
        habits: [buildTestHabit(amountCompleted: amountCompleted)],
        timestamp: DateTime.now().toUtc(),
      ),
    );
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

  group('day progress cache', () {
    test('dayProgress computes from the day snapshot and caches it', () async {
      final pastDay = _normalize(
        DateTime.now().subtract(const Duration(days: 10)),
      );
      await seedDay(pastDay, amountCompleted: 5);
      final provider = await createInitializedProvider();

      expect(provider.cachedDayProgress(pastDay), isNull);
      expect(provider.dayProgress(pastDay), closeTo(0.5, 0.0001));
      expect(provider.cachedDayProgress(pastDay), closeTo(0.5, 0.0001));
    });

    test('priming one day caches its whole week', () async {
      final pastDay = _normalize(
        DateTime.now().subtract(const Duration(days: 10)),
      );
      await seedDay(pastDay, amountCompleted: 5);
      final provider = await createInitializedProvider();

      provider.primeDayProgress([pastDay]);

      final weekStart = pastDay.subtract(
        Duration(days: pastDay.weekday - 1),
      );
      for (int i = 0; i < 7; i++) {
        final day = DateTime(
          weekStart.year,
          weekStart.month,
          weekStart.day + i,
        );
        expect(
          provider.cachedDayProgress(day),
          isNotNull,
          reason: 'whole week of $pastDay should be cached, missing $day',
        );
      }
    });

    test('dataVersion bump clears the cache', () async {
      final pastDay = _normalize(
        DateTime.now().subtract(const Duration(days: 10)),
      );
      await seedDay(pastDay, amountCompleted: 5);
      final provider = await createInitializedProvider();

      expect(provider.dayProgress(pastDay), closeTo(0.5, 0.0001));

      provider.dataVersion++;

      expect(provider.cachedDayProgress(pastDay), isNull);
      // Recomputes on demand after invalidation.
      expect(provider.dayProgress(pastDay), closeTo(0.5, 0.0001));
    });

    test(
      'refreshDayProgress recomputes changed data without a version bump',
      () async {
        final pastDay = _normalize(
          DateTime.now().subtract(const Duration(days: 10)),
        );
        await seedDay(pastDay, amountCompleted: 5);
        final provider = await createInitializedProvider();

        expect(provider.dayProgress(pastDay), closeTo(0.5, 0.0001));

        // Change the underlying snapshot; the cache must still hold the old
        // value until an explicit refresh.
        await seedDay(pastDay, amountCompleted: 10);
        expect(provider.cachedDayProgress(pastDay), closeTo(0.5, 0.0001));

        expect(provider.refreshDayProgress(pastDay), closeTo(1.0, 0.0001));
        expect(provider.cachedDayProgress(pastDay), closeTo(1.0, 0.0001));
      },
    );

    test('future days are cached as zero progress', () async {
      final provider = await createInitializedProvider();
      final tomorrow = _normalize(
        DateTime.now().add(const Duration(days: 1)),
      );

      expect(provider.dayProgress(tomorrow), 0.0);
    });
  });
}
