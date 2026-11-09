import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:habitt/hive/hive_adapters.dart';
import 'package:habitt/hive/hive_registrar.g.dart';
import 'package:habitt/models/day.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/services/backup_service.dart';
import 'package:hive_ce/hive.dart';

import '../fixtures/habit_factory.dart';

// After a sync merge, today's live habits are rebuilt from today's day
// snapshot. A tap made while the merge ran is on the live habit before it
// reaches the snapshot, so the merge's rebuild must not copy the older snapshot
// state back over it. A local file restore still takes the file's state as is.

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Box<Habit> habitBox;
  late Box<Day> daysBox;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('rehydrate_today');
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
  final todayKey = today.toIso8601String().split('T').first;
  final earlier = DateTime.now().toUtc().subtract(const Duration(minutes: 5));
  final later = DateTime.now().toUtc();

  Habit habit({required bool completed, DateTime? completedAt, int id = 1}) =>
      buildTestHabit(
        id: id,
        trackingType: null,
        createdAt: today,
        timestamps: {if (completedAt != null) 'completed': completedAt},
      )..completed = completed;

  /// Puts [live] in the habits box and [snapshot] in today's day.
  Future<Habit> boot(Habit live, Habit snapshot) async {
    await habitBox.clear();
    await daysBox.clear();
    await habitBox.add(live);
    await daysBox.put(
      todayKey,
      Day(date: today, habits: [snapshot.forDay()], timestamp: earlier),
    );
    return live;
  }

  group('sync merge (keepNewerLocal)', () {
    test('keeps a completion made after the snapshot', () async {
      final live = await boot(
        habit(completed: true, completedAt: later),
        habit(completed: false, completedAt: earlier),
      );

      await BackupService.rehydrateTodayFromSnapshot(keepNewerLocal: true);

      expect(live.completed, isTrue);
      expect(habitBox.values.single.completed, isTrue);
      expect(live.timestamps['completed'], later);
    });

    test('keeps an undo made after the snapshot', () async {
      final live = await boot(
        habit(completed: false, completedAt: later),
        habit(completed: true, completedAt: earlier),
      );

      await BackupService.rehydrateTodayFromSnapshot(keepNewerLocal: true);

      expect(live.completed, isFalse);
    });

    test('takes a newer state from the snapshot', () async {
      // completed on the other device after this one last touched it
      final live = await boot(
        habit(completed: false, completedAt: earlier),
        habit(completed: true, completedAt: later),
      );

      await BackupService.rehydrateTodayFromSnapshot(keepNewerLocal: true);

      expect(live.completed, isTrue);
      expect(live.timestamps['completed'], later);
    });

    test(
      'takes the snapshot when the live habit has no day timestamps',
      () async {
        final live = await boot(
          habit(completed: false),
          habit(completed: true, completedAt: earlier),
        );

        await BackupService.rehydrateTodayFromSnapshot(keepNewerLocal: true);

        expect(live.completed, isTrue);
      },
    );

    test('takes the snapshot for a habit the merge just added', () async {
      // its live state is the other device's dateless value, not a tap
      final live = await boot(
        habit(completed: true, completedAt: later),
        habit(completed: false, completedAt: earlier),
      );

      await BackupService.rehydrateTodayFromSnapshot(
        keepNewerLocal: true,
        adoptAlways: {live.id},
      );

      expect(live.completed, isFalse);
    });
  });

  test('a local file restore takes the snapshot as is', () async {
    final live = await boot(
      habit(completed: true, completedAt: later),
      habit(completed: false, completedAt: earlier),
    );

    await BackupService.rehydrateTodayFromSnapshot();

    expect(live.completed, isFalse);
    expect(live.timestamps['completed'], earlier);
  });

  group('hasNewerDayStateThan', () {
    test('compares the newest day-state timestamp', () {
      final a = habit(completed: true, completedAt: later);
      final b = habit(completed: false, completedAt: earlier);
      expect(a.hasNewerDayStateThan(b), isTrue);
      expect(b.hasNewerDayStateThan(a), isFalse);
      expect(a.hasNewerDayStateThan(a.copy()), isFalse);
    });

    test('no day-state timestamp is never newer', () {
      final none = habit(completed: true);
      final some = habit(completed: false, completedAt: earlier);
      expect(none.hasNewerDayStateThan(some), isFalse);
      expect(some.hasNewerDayStateThan(none), isTrue);
    });
  });
}
