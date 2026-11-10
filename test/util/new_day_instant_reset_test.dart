import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:habitt/hive/hive_adapters.dart';
import 'package:habitt/hive/hive_registrar.g.dart';
import 'package:habitt/models/day.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/providers/stats_provider.dart';
import 'package:habitt/services/backup_service.dart';
import 'package:habitt/util/date_key.dart';
import 'package:habitt/util/update_last_date.dart';
import 'package:hive_ce/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

// On a new day today's habits are cleared right away, without waiting for a
// running sync; only what writes day records waits. The last opened day's
// record is never rebuilt from the live habits, and today's record keeps
// whatever was changed today (a merge from another device, a tap), whichever
// order the sync and the reset run in.

DateTime _n(DateTime d) => DateTime(d.year, d.month, d.day);
String _k(DateTime d) => _n(d).toIso8601String().split('T').first;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final today = _n(DateTime.now());
  final yesterday = addCalendarDays(today, -1);
  // yesterday's completions were stamped yesterday
  final yesterdayStamp = yesterday.add(const Duration(hours: 18)).toUtc();
  final todayStamp = DateTime.now().toUtc();

  var registered = false;
  late Directory dir;
  late Box<Habit> habitBox;
  late Box<Day> daysBox;
  late HabitProvider p;
  late StateProvider sp;
  late StatsProvider st;

  Habit habit(int id, {bool completed = true}) => Habit(
    id: id,
    name: 'habit $id',
    iconPath: '',
    categoryId: 1,
    createdAt: addCalendarDays(today, -60),
    completed: completed,
    timestamps: {if (completed) 'completed': yesterdayStamp},
  );

  /// Live habits 1 and 2 completed yesterday, recorded in yesterday's day;
  /// the app was last opened yesterday. [extraLive] are live but missing from
  /// yesterday's record.
  Future<void> boot({
    List<Habit> extraLive = const [],
    DateTime? lastOpened,
  }) async {
    dir = await Directory.systemTemp.createTemp('instant_reset');
    Hive.init(dir.path);
    if (!registered) {
      registered = true;
      Hive.registerAdapters();
      Hive.registerAdapter(ScheduleTypeAdapter());
      Hive.registerAdapter(PremadeHabitTypeAdapter());
      Hive.registerAdapter(HabitTrackingTypeAdapter());
      Hive.registerAdapter(HabitNotificationTimeAdapter());
      Hive.registerAdapter(LegacyHabitTrackingTypeAdapter());
    }
    habitBox = await Hive.openBox<Habit>('habits');
    daysBox = await Hive.openBox<Day>('days');
    SharedPreferences.setMockInitialValues({
      'lastNotificationSyncDate': _k(today),
      'daySnapshotsSanitized_v1': true,
      'lastOpenedDate':
          (lastOpened ?? yesterday.add(const Duration(hours: 20))).toString(),
    });
    final live = [habit(1), habit(2), ...extraLive];
    for (final h in live) {
      await habitBox.add(h);
    }
    for (var i = 5; i >= 1; i--) {
      final d = addCalendarDays(today, -i);
      await daysBox.put(
        _k(d),
        Day(
          date: d,
          habits: [habit(1).forDay(), habit(2).forDay()],
          timestamp: yesterdayStamp,
        ),
      );
    }
    NewDayGate.reset();
    p = HabitProvider();
    final deadline = DateTime.now().add(const Duration(seconds: 10));
    while (!p.isInitialized) {
      if (DateTime.now().isAfter(deadline)) fail('init timed out');
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    final prefs = await SharedPreferences.getInstance();
    sp = StateProvider(prefs);
    st = StatsProvider(prefs: prefs);
  }

  tearDown(() async {
    NewDayGate.reset();
    await Hive.close();
    await dir.delete(recursive: true);
  });

  Habit live(int id) => habitBox.values.firstWhere((h) => h.id == id);
  Habit? recorded(DateTime day, int id) {
    for (final h in daysBox.get(_k(day))?.habits ?? const <Habit>[]) {
      if (h.id == id) return h;
    }
    return null;
  }

  Future<String?> lastOpenedPref() async =>
      (await SharedPreferences.getInstance()).getString('lastOpenedDate');

  /// A sync from before midnight, still running; ends when completed.
  Completer<void> runningSync() {
    final sync = Completer<void>();
    NewDayGate.syncStarted(sync.future, idleFor: () => Duration.zero);
    return sync;
  }

  test('today is cleared right away while a sync still runs', () async {
    await boot();
    final sync = runningSync();

    final check = updateLastOpenedDate(p, sp, st);
    await pumpEventQueue();

    // cleared without waiting for the sync
    expect(live(1).completed, isFalse);
    expect(live(2).completed, isFalse);
    expect(p.todaysHabits.where((h) => h.completed), isEmpty);
    // no stamp: the reset never wins a merge
    expect(live(1).timestamps['completed'], yesterdayStamp);
    // the rest still waits
    expect(await lastOpenedPref(), isNot(contains(_k(today))));

    sync.complete();
    await check;

    expect(await lastOpenedPref(), contains(_k(today)));
    expect(recorded(today, 1)?.completed, isFalse);
    expect(recorded(today, 2)?.completed, isFalse);
    // yesterday kept as recorded
    expect(recorded(yesterday, 1)?.completed, isTrue);
    expect(recorded(yesterday, 2)?.completed, isTrue);
  });

  test('a completion merged in before the reset is kept', () async {
    await boot();
    // another device completed habit 1 today; a sync merged it before the
    // check ran
    await daysBox.put(
      _k(today),
      Day(
        date: today,
        habits: [
          (habit(1)..timestamps['completed'] = todayStamp).forDay(),
          habit(2, completed: false).forDay(),
        ],
        timestamp: todayStamp,
      ),
    );

    await updateLastOpenedDate(p, sp, st);

    expect(live(1).completed, isTrue);
    expect(live(2).completed, isFalse);
    expect(recorded(today, 1)?.completed, isTrue);
    expect(recorded(today, 2)?.completed, isFalse);
  });

  test('a completion merged in after the reset is kept', () async {
    await boot();
    final sync = runningSync();
    final check = updateLastOpenedDate(p, sp, st);
    await pumpEventQueue();
    expect(live(1).completed, isFalse);

    // the running sync merges another device's completion of today, then
    // rehydrates today, as _mergeBackupData does
    await daysBox.put(
      _k(today),
      Day(
        date: today,
        habits: [(habit(1)..timestamps['completed'] = todayStamp).forDay()],
        timestamp: todayStamp,
      ),
    );
    await BackupService.rehydrateTodayFromSnapshot(keepNewerLocal: true);
    expect(live(1).completed, isTrue);

    sync.complete();
    await check;

    expect(live(1).completed, isTrue);
    expect(recorded(today, 1)?.completed, isTrue);
    expect(recorded(today, 2)?.completed, isFalse);
  });

  test('a tap between the reset and saving today is kept', () async {
    await boot();
    final sync = runningSync();
    final check = updateLastOpenedDate(p, sp, st);
    await pumpEventQueue();

    final h =
        live(2)
          ..completed = true
          ..timestamps['completed'] = DateTime.now().toUtc();
    await p.updateHabitInDB(h);

    sync.complete();
    await check;

    expect(live(2).completed, isTrue);
    expect(recorded(today, 2)?.completed, isTrue);
    expect(recorded(today, 1)?.completed, isFalse);
  });

  test('a habit missing from yesterday is added before the reset', () async {
    // created yesterday, completed, but missing from yesterday's record
    await boot(extraLive: [habit(3)]);

    await updateLastOpenedDate(p, sp, st);

    expect(recorded(yesterday, 3)?.completed, isTrue);
    expect(recorded(yesterday, 1)?.completed, isTrue);
    expect(live(3).completed, isFalse);
  });

  test('a check cut short after the reset leaves yesterday intact', () async {
    await boot();
    // the app is killed after the instant part
    await p.startNewDay(yesterday);
    expect(live(1).completed, isFalse);

    // the next open runs the whole check again; before, it rebuilt
    // yesterday from the half-reset live habits
    await updateLastOpenedDate(p, sp, st);

    expect(recorded(yesterday, 1)?.completed, isTrue);
    expect(recorded(yesterday, 2)?.completed, isTrue);
    expect(live(1).completed, isFalse);
    expect(await lastOpenedPref(), contains(_k(today)));
  });

  test('the clock moving backwards still restores today', () async {
    final tomorrow = addCalendarDays(today, 1);
    await boot(lastOpened: tomorrow.add(const Duration(hours: 9)));
    // today's real progress was recorded before the clock moved ahead
    await daysBox.put(
      _k(today),
      Day(
        date: today,
        habits: [habit(1).forDay(), habit(2, completed: false).forDay()],
        timestamp: yesterdayStamp,
      ),
    );
    // the live habits hold the "future" day
    live(1).completed = false;
    live(2).completed = true;

    await updateLastOpenedDate(p, sp, st);

    expect(live(1).completed, isTrue);
    expect(live(2).completed, isFalse);
    expect(await lastOpenedPref(), contains(_k(today)));
  });
}
