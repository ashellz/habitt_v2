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

import '../fixtures/habit_factory.dart';

// A habit's copies in past day snapshots only count on days the live habit
// existed and wasn't paused (pause history + createdAt), whoever wrote them:
// rollover filling the days the app wasn't opened, a past day created on
// demand, or a sync from another device.

DateTime _n(DateTime d) => DateTime(d.year, d.month, d.day);
String _k(DateTime d) => _n(d).toIso8601String().split('T').first;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Box<Habit> habitBox;
  late Box<Day> daysBox;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('unpaused_past_days');
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

  setUp(NewDayGate.reset);

  final today = _n(DateTime.now());
  DateTime ago(int days) => addCalendarDays(today, -days);
  final unpausedAt = DateTime.now().toUtc();

  Habit regular() => buildTestHabit(
    id: 1,
    name: 'regular',
    trackingType: null,
    createdAt: ago(30),
  );

  // paused 10 days ago, unpaused today
  Habit unpaused() => buildTestHabit(
    id: 2,
    name: 'unpaused',
    trackingType: null,
    createdAt: ago(30),
    timestamps: {'isPaused': unpausedAt},
  )
    ..isPaused = false
    ..pausedRanges = [ago(10).add(const Duration(hours: 9)).toUtc(), unpausedAt];

  Future<void> boot(
    List<Habit> habits, {
    Map<String, Object> prefs = const {},
  }) async {
    SharedPreferences.setMockInitialValues({
      'lastNotificationSyncDate': _k(today),
      'daySnapshotsSanitized_v1': true,
      ...prefs,
    });
    await habitBox.clear();
    await daysBox.clear();
    for (final h in habits) {
      await habitBox.add(h);
    }
  }

  Future<void> putDay(DateTime d, List<Habit> habits) => daysBox.put(
    _k(d),
    Day(date: d, habits: habits, timestamp: DateTime.now().toUtc()),
  );

  Future<HabitProvider> startProvider() async {
    final p = HabitProvider();
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (!p.isInitialized) {
      if (DateTime.now().isAfter(deadline)) fail('HabitProvider.init timed out');
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    return p;
  }

  List<int> ids(List<Habit> habits) => habits.map((h) => h.id).toList();

  test('a copy on a day in the pause history does not count', () async {
    await boot([regular(), unpaused()]);
    final p = await startProvider();

    // inside the paused stretch
    expect(
      ids(p.habitsCountingForDay(ago(3), [regular().forDay(), unpaused().forDay()])),
      [1],
    );
    // the day it was paused on
    expect(ids(p.habitsCountingForDay(ago(10), [unpaused().forDay()])), isEmpty);
    // before the pause it counts as usual, misses included
    expect(ids(p.habitsCountingForDay(ago(12), [unpaused().forDay()])), [2]);
    // today it counts again
    expect(
      ids(p.habitsCountingForDay(today, [regular().forDay(), unpaused().forDay()])),
      containsAll([1, 2]),
    );
    // a real completion logged on a paused day is never dropped
    final done = unpaused().forDay()..completed = true;
    expect(ids(p.habitsCountingForDay(ago(3), [done])), [2]);
  });

  test('a copy before the habit was created does not count', () async {
    final young = buildTestHabit(
      id: 3,
      name: 'young',
      trackingType: null,
      createdAt: ago(2),
    );
    await boot([regular(), young]);
    final p = await startProvider();

    expect(ids(p.habitsCountingForDay(ago(5), [young.forDay()])), isEmpty);
    expect(ids(p.habitsCountingForDay(ago(1), [young.forDay()])), [3]);
    final done = young.forDay()..completed = true;
    expect(ids(p.habitsCountingForDay(ago(5), [done])), [3]);
  });

  test('day snapshots never hold the pause history', () async {
    await boot([regular(), unpaused()]);
    final p = await startProvider();
    await p.saveHabitDay(ago(20));
    final live = p.habits.firstWhere((h) => h.id == 2);
    await p.updateHabitInDB(live);

    for (final key in [_k(ago(20)), _k(today)]) {
      final copy = daysBox.get(key)!.habits.firstWhere((h) => h.id == 2);
      expect(copy.pausedRanges, isEmpty, reason: key);
      expect(identical(copy, live), isFalse, reason: key);
    }
    expect(live.pausedRanges, hasLength(2));
    final dayMap = daysBox.get(_k(today))!.toMap();
    final habitMaps = (dayMap['habits'] as List).cast<Map<String, dynamic>>();
    expect(habitMaps.any((m) => m.containsKey('pausedRanges')), isFalse);
  });

  test('rollover keeps synced gap days and leaves out the paused habit',
      () async {
    final lastOpened = ago(5);
    await boot(
      [regular(), unpaused()],
      prefs: {
        'lastOpenedDate': lastOpened.add(const Duration(hours: 20)).toString(),
        'dateJoined': ago(30).toIso8601String(),
      },
    );

    // the days the app wasn't opened on were synced in from another device,
    // the habit was paused there so they don't list it
    for (var i = 4; i >= 1; i--) {
      await putDay(ago(i), [regular().forDay()..completed = true]);
    }

    final p = await startProvider();
    final prefs = await SharedPreferences.getInstance();
    await updateLastOpenedDate(
      p,
      StateProvider(prefs),
      StatsProvider(prefs: prefs),
    );

    for (var i = 5; i >= 1; i--) {
      final day = daysBox.get(_k(ago(i)))!;
      expect(
        ids(day.habits),
        isNot(contains(2)),
        reason: '${_k(ago(i))} must not list the habit paused that day',
      );
      if (i <= 4) {
        expect(
          ids(day.habits.where((h) => h.completed).toList()),
          [1],
          reason: '${_k(ago(i))} must keep its synced completion',
        );
      }
    }
  });

  test('createdAt moves earlier only to a day with progress', () async {
    final habit = buildTestHabit(
      id: 4,
      name: 'h',
      trackingType: null,
      createdAt: ago(3),
    );
    await boot([habit]);
    // an empty copy before createdAt (a later fill) proves nothing
    await putDay(ago(9), [habit.forDay()]);
    // a completion does
    await putDay(ago(6), [habit.forDay()..completed = true]);
    final p = await startProvider();
    expect(_n(p.habits.single.createdAt.toLocal()), ago(6));
  });

  test('createdAt pulled back before the id time goes back to it', () async {
    final created = DateTime.now().toUtc().subtract(const Duration(days: 4));
    final id = created.microsecondsSinceEpoch;
    final habit = buildTestHabit(
      id: id,
      name: 'pulled back',
      trackingType: null,
      createdAt: ago(40),
    );
    await boot([habit]);
    await putDay(ago(40), [habit.forDay()]);
    await putDay(ago(2), [habit.forDay()..completed = true]);
    final p = await startProvider();
    expect(p.habits.single.createdAt, created);

    // logged before the id time (an imported habit): left alone
    final imported = buildTestHabit(
      id: id,
      name: 'imported',
      trackingType: null,
      createdAt: ago(40),
    );
    await boot([imported]);
    await putDay(ago(30), [imported.forDay()..completed = true]);
    final p2 = await startProvider();
    expect(_n(p2.habits.single.createdAt.toLocal()), ago(40));
  });

  test('pause history is seeded from the days for an earlier unpause',
      () async {
    final habit = buildTestHabit(
      id: 5,
      name: 'seeded',
      trackingType: null,
      createdAt: ago(30),
      timestamps: {'isPaused': unpausedAt},
    )..isPaused = false;
    await boot([regular(), habit]);
    await putDay(ago(12), [regular().forDay(), habit.forDay()..completed = true]);
    // missed before the pause
    for (var i = 11; i >= 8; i--) {
      await putDay(ago(i), [regular().forDay(), habit.forDay()]);
    }
    // paused: left out of the days
    for (var i = 7; i >= 4; i--) {
      await putDay(ago(i), [regular().forDay()]);
    }
    // filled in later from the active habit
    for (var i = 3; i >= 1; i--) {
      await putDay(ago(i), [regular().forDay(), habit.forDay()]);
    }
    final p = await startProvider();
    final live = p.habits.firstWhere((h) => h.id == 5);
    expect(live.pausedRanges, hasLength(2));
    expect(_n(live.pausedRanges.first.toLocal()), ago(7));

    expect(ids(p.habitsCountingForDay(ago(2), [habit.forDay()])), isEmpty);
    expect(ids(p.habitsCountingForDay(ago(9), [habit.forDay()])), [5]);

    // never really paused (only a stamp): no stretch, misses stay
    final stamped = buildTestHabit(
      id: 6,
      name: 'stamped',
      trackingType: null,
      createdAt: ago(30),
      timestamps: {'isPaused': unpausedAt},
    )..isPaused = false;
    await boot([stamped]);
    await putDay(ago(6), [stamped.forDay()..completed = true]);
    for (var i = 5; i >= 1; i--) {
      await putDay(ago(i), [stamped.forDay()]);
    }
    final p2 = await startProvider();
    expect(p2.habits.single.pausedRanges, isEmpty);
  });

  group('Habit pause history', () {
    test('unpausing records the stretch', () async {
      final h = buildTestHabit(id: 7, trackingType: null);
      await h.pauseHabit();
      final since = h.timestamps['isPaused']!;
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await h.unpauseHabit();
      expect(h.pausedRanges, [since, h.timestamps['isPaused']]);
      expect(h.forDay().pausedRanges, isEmpty);
      expect(h.copy().pausedRanges, h.pausedRanges);
    });

    test('an edit that unpauses records the stretch', () async {
      final h = buildTestHabit(id: 7, trackingType: null);
      await h.pauseHabit();
      await Future<void>.delayed(const Duration(milliseconds: 5));
      h.updateHabit(h.copy()..isPaused = false);
      expect(h.pausedRanges, hasLength(2));
      expect(h.isPaused, isFalse);
    });

    test('merge unions both sides and survives a round trip', () {
      final a = buildTestHabit(id: 8, trackingType: null)
        ..pausedRanges = [DateTime.utc(2026, 1, 1), DateTime.utc(2026, 1, 5)];
      final b = buildTestHabit(id: 8, trackingType: null)
        ..pausedRanges = [DateTime.utc(2026, 3, 1), DateTime.utc(2026, 3, 9)];
      final merged = a.merge(b);
      expect(merged.pausedRanges, [
        DateTime.utc(2026, 1, 1),
        DateTime.utc(2026, 1, 5),
        DateTime.utc(2026, 3, 1),
        DateTime.utc(2026, 3, 9),
      ]);
      expect(Habit.fromMap(merged.toMap()).pausedRanges, merged.pausedRanges);
    });

    test('an unpause from an older app version gets its stretch', () {
      final pausedSince = DateTime.now().toUtc().subtract(
        const Duration(days: 6),
      );
      final unpausedOn = DateTime.now().toUtc().subtract(
        const Duration(hours: 1),
      );
      final local = buildTestHabit(
        id: 9,
        trackingType: null,
        timestamps: {'isPaused': pausedSince},
      )..isPaused = true;
      final incoming = buildTestHabit(
        id: 9,
        trackingType: null,
        timestamps: {'isPaused': unpausedOn},
      )..isPaused = false;
      final merged = local.merge(incoming);
      expect(merged.isPaused, isFalse);
      expect(merged.pausedRanges, [pausedSince, unpausedOn]);
    });
  });

  group('NewDayGate', () {
    test('a sync waits until the new-day check has run', () async {
      await boot([regular()], prefs: {
        'lastOpenedDate': ago(1).add(const Duration(hours: 20)).toString(),
        'dateJoined': ago(30).toIso8601String(),
      });
      final p = await startProvider();
      // nothing ran the check yet: the sync is put off
      expect(await NewDayGate.readyForSync(), isFalse);

      final prefs = await SharedPreferences.getInstance();
      await updateLastOpenedDate(
        p,
        StateProvider(prefs),
        StatsProvider(prefs: prefs),
      );
      expect(await NewDayGate.readyForSync(), isTrue);
    });

    test('a due check runs before the sync goes on', () async {
      await boot([regular()], prefs: {
        'lastOpenedDate': ago(1).add(const Duration(hours: 20)).toString(),
        'dateJoined': ago(30).toIso8601String(),
      });
      final p = await startProvider();
      final prefs = await SharedPreferences.getInstance();
      final sp = StateProvider(prefs);
      final st = StatsProvider(prefs: prefs);
      // registers the runner, then pretend the app stayed open past midnight
      await updateLastOpenedDate(p, sp, st);
      await prefs.setString(
        'lastOpenedDate',
        ago(1).add(const Duration(hours: 20)).toString(),
      );
      expect(await NewDayGate.readyForSync(), isTrue);
      expect(daysBox.get(_k(ago(1))), isNotNull);
    });

    test('the new-day check waits for a running sync', () async {
      await boot([regular()], prefs: {
        'lastOpenedDate': ago(1).add(const Duration(hours: 20)).toString(),
        'dateJoined': ago(30).toIso8601String(),
      });
      final p = await startProvider();
      final prefs = await SharedPreferences.getInstance();
      final sync = Completer<void>();
      NewDayGate.syncStarted(sync.future);

      var checkDone = false;
      final check = updateLastOpenedDate(
        p,
        StateProvider(prefs),
        StatsProvider(prefs: prefs),
      ).then((_) => checkDone = true);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(checkDone, isFalse);
      sync.complete();
      await check;
      expect(checkDone, isTrue);
    });
  });
}
