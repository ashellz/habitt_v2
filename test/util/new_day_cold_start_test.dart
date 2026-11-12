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
import 'package:habitt/util/date_key.dart';
import 'package:habitt/util/update_last_date.dart';
import 'package:hive_ce/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

// At a cold start the home page runs the new-day check right after the first
// frame, while HabitProvider.init may still be loading the habits. The check
// used to reset the empty list, save today as checked, and leave the habits
// loaded right after with yesterday's progress on today for good. It now
// waits for the first load, and a launch on an already-checked day clears
// progress an earlier reset left behind.

DateTime _n(DateTime d) => DateTime(d.year, d.month, d.day);
String _k(DateTime d) => _n(d).toIso8601String().split('T').first;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final today = _n(DateTime.now());
  final yesterday = addCalendarDays(today, -1);
  final tomorrow = addCalendarDays(today, 1);
  final yesterdayStamp = yesterday.add(const Duration(hours: 18)).toUtc();
  final todayStamp = DateTime.now().toUtc();

  var registered = false;
  late Directory dir;
  late Box<Habit> habitBox;
  late Box<Day> daysBox;
  late HabitProvider p;
  late StateProvider sp;
  late StatsProvider st;

  Habit habit(int id, {bool completed = true, DateTime? stamp}) => Habit(
    id: id,
    name: 'habit $id',
    iconPath: '',
    categoryId: 1,
    createdAt: addCalendarDays(today, -60),
    completed: completed,
    timestamps: {if (completed) 'completed': stamp ?? yesterdayStamp},
  );

  /// Live [live] habits, each recorded in the last five days as is. Doesn't
  /// wait for HabitProvider.init unless [waitForInit].
  Future<void> boot({
    required List<Habit> live,
    required DateTime lastOpened,
    Day? todayRecord,
    bool waitForInit = true,
  }) async {
    dir = await Directory.systemTemp.createTemp('new_day_cold_start');
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
      'lastOpenedDate': lastOpened.toString(),
    });
    for (final h in live) {
      await habitBox.add(h);
    }
    for (var i = 5; i >= 1; i--) {
      final d = addCalendarDays(today, -i);
      await daysBox.put(
        _k(d),
        Day(
          date: d,
          habits: [for (final h in live) h.forDay()],
          timestamp: yesterdayStamp,
        ),
      );
    }
    if (todayRecord != null) await daysBox.put(_k(today), todayRecord);
    NewDayGate.reset();
    final prefs = await SharedPreferences.getInstance();
    sp = StateProvider(prefs);
    st = StatsProvider(prefs: prefs);
    p = HabitProvider();
    if (!waitForInit) return;
    final deadline = DateTime.now().add(const Duration(seconds: 10));
    while (!p.isInitialized) {
      if (DateTime.now().isAfter(deadline)) fail('init timed out');
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
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

  test('a check started before the habits load still resets them', () async {
    await boot(
      live: [habit(1), habit(2)],
      lastOpened: yesterday.add(const Duration(hours: 20)),
      waitForInit: false,
    );
    // what the home page does right after the first frame
    expect(p.isInitialized, isFalse);
    await updateLastOpenedDate(p, sp, st);

    expect(p.isInitialized, isTrue);
    expect(live(1).completed, isFalse);
    expect(live(2).completed, isFalse);
    expect(p.todaysHabits.where((h) => h.completed), isEmpty);
    expect(recorded(today, 1)?.completed, isFalse);
    expect(recorded(today, 2)?.completed, isFalse);
    expect(recorded(yesterday, 1)?.completed, isTrue);
    expect(await lastOpenedPref(), contains(_k(today)));
  });

  test('a check whose habits never load is postponed', () async {
    await boot(
      live: [habit(1)],
      lastOpened: yesterday.add(const Duration(hours: 20)),
    );
    NewDayGate.firstLoadLimit = const Duration(milliseconds: 50);
    final notLoaded = _NeverLoaded();
    await updateLastOpenedDate(notLoaded, sp, st);
    expect(await lastOpenedPref(), isNot(contains(_k(today))));
    expect(live(1).completed, isTrue);
    await notLoaded.realFirstLoad;
  });

  test('progress an earlier reset left on today is cleared', () async {
    await boot(
      live: [
        habit(1), // carried over from yesterday
        habit(2, stamp: todayStamp), // completed today
        habit(3, completed: false),
        habit(4, stamp: tomorrow.toUtc()), // clock moved backwards
        habit(5), // carried over, but its record changed today
      ],
      // today's check already ran (the broken reset)
      lastOpened: today.add(const Duration(minutes: 5)),
      todayRecord: Day(
        date: today,
        habits: [
          habit(2, stamp: todayStamp).forDay(),
          // undone on another device today, merge not applied yet
          (habit(5, completed: false)
                ..timestamps['completed'] = todayStamp)
              .forDay(),
        ],
        timestamp: todayStamp,
      ),
    );
    expect(live(1).completed, isTrue);

    await updateLastOpenedDate(p, sp, st);

    expect(live(1).completed, isFalse);
    // no stamp, like the new-day reset
    expect(live(1).timestamps['completed'], yesterdayStamp);
    expect(live(2).completed, isTrue);
    expect(live(4).completed, isTrue);
    expect(live(5).completed, isFalse);
    expect(p.todaysHabits.firstWhere((h) => h.id == 1).completed, isFalse);
    expect(recorded(today, 1)?.completed, isFalse);
    expect(recorded(today, 2)?.completed, isTrue);
    expect(recorded(today, 3)?.completed, isFalse);
    expect(recorded(today, 5)?.completed, isFalse);
    expect(recorded(today, 5)?.timestamps['completed'], todayStamp);
    // yesterday untouched
    expect(recorded(yesterday, 1)?.completed, isTrue);
  });

  test('the repair runs once a launch', () async {
    await boot(
      live: [habit(1)],
      lastOpened: today.add(const Duration(minutes: 5)),
    );
    await updateLastOpenedDate(p, sp, st);
    expect(live(1).completed, isFalse);

    // completed on a later call stays, even with an old stamp
    live(1).completed = true;
    await updateLastOpenedDate(p, sp, st);
    expect(live(1).completed, isTrue);
  });
}

/// A provider whose first load never reports done.
class _NeverLoaded extends HabitProvider {
  Future<void> get realFirstLoad => super.firstLoadDone;

  @override
  Future<void> get firstLoadDone => Completer<void>().future;
}
