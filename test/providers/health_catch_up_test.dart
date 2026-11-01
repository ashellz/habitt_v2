import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitt/hive/hive_adapters.dart';
import 'package:habitt/hive/hive_registrar.g.dart';
import 'package:habitt/models/day.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/models/health_metric_type.dart';
import 'package:habitt/models/health_session_detail.dart';
import 'package:habitt/models/health_workout_type.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/providers/health_provider.dart';
import 'package:habitt/services/health_service.dart';
import 'package:habitt/util/health_value_guard.dart';
import 'package:hive_ce/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../fixtures/habit_factory.dart';

/// Health stand-in that answers each day from [valueFor] and records the days
/// it was asked about, in order.
class _PerDayHealthService extends HealthService {
  _PerDayHealthService(this.valueFor);

  final int? Function(DateTime day) valueFor;
  final List<DateTime> reads = [];

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<bool> hasPermissions() async => true;

  @override
  bool isMetricSupported(HealthMetricType metric) => true;

  @override
  Future<HealthDayReading?> fetchDay(
    HealthMetricType metric,
    DateTime day, {
    HabitTrackingType? trackingType,
    HealthWorkoutType? workoutFilter,
    bool bedtimeDayBefore = false,
  }) async {
    reads.add(DateTime(day.year, day.month, day.day));
    final v = valueFor(day);
    return v == null ? null : HealthDayReading(v, const []);
  }
}

DateTime _normalize(DateTime date) => DateTime(date.year, date.month, date.day);

String _dayKey(DateTime date) =>
    _normalize(date).toIso8601String().split('T').first;

DateTime _ago(int days) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day - days);
}

const _notificationsChannel = MethodChannel('awesome_notifications');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Box<Habit> habitBox;
  late Box<Day> daysBox;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('health_catch_up_test');
    Hive.init(tempDir.path);
    Hive.registerAdapters();
    Hive.registerAdapter(ScheduleTypeAdapter());
    Hive.registerAdapter(PremadeHabitTypeAdapter());
    Hive.registerAdapter(HabitTrackingTypeAdapter());
    Hive.registerAdapter(HabitNotificationTimeAdapter());
    Hive.registerAdapter(LegacyHabitTrackingTypeAdapter());
    habitBox = await Hive.openBox<Habit>('habits');
    daysBox = await Hive.openBox<Day>('days');

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_notificationsChannel, (call) async {
          final method = call.method.toLowerCase();
          if (method.contains('list')) return <Object>[];
          if (method.contains('isnotificationallowed')) return false;
          return true;
        });
  });

  Future<void> seedPrefs({Map<int, DateTime> cursors = const {}}) async {
    final today = _normalize(DateTime.now());
    SharedPreferences.setMockInitialValues({
      'lastNotificationSyncDate': _dayKey(today),
      'daySnapshotsSanitized_v1': true,
      'durationSecondsMigrated_habits_v1': true,
      'durationSecondsMigrated_days_v1': true,
      'dateJoined': today.subtract(const Duration(days: 60)).toIso8601String(),
      if (cursors.isNotEmpty)
        'healthSyncCursors': jsonEncode({
          for (final e in cursors.entries) '${e.key}': _dayKey(e.value),
        }),
    });
  }

  setUp(() async {
    await seedPrefs();
    await habitBox.clear();
    await daysBox.clear();
  });

  tearDownAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_notificationsChannel, null);
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

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

  Habit stepsHabit({
    required int id,
    DateTime? createdAt,
    int amountCompleted = 0,
  }) => buildTestHabit(
    id: id,
    trackingType: HabitTrackingType.amount,
    healthMetric: HealthMetricType.steps,
    amount: 6000,
    amountLabel: 'steps',
    amountCompleted: amountCompleted,
    createdAt: createdAt ?? _ago(40),
  );

  Future<Map<int, String>> storedCursors() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('healthSyncCursors');
    if (raw == null) return {};
    return {
      for (final e in (jsonDecode(raw) as Map).entries)
        int.parse(e.key as String): e.value as String,
    };
  }

  group('syncNow catch-up', () {
    test('a habit with no cursor only syncs today and sets its cursor', () async {
      await habitBox.put(1, stepsHabit(id: 1));
      final habitProvider = await createInitializedProvider();
      final service = _PerDayHealthService((_) => 4000);
      final health = HealthProvider(service: service)
        ..attachHabitProvider(habitProvider);

      await health.syncNow();

      expect(service.reads, [_ago(0)]);
      expect((await storedCursors())[1], _dayKey(_ago(0)));
    });

    test('catches up on the days since the cursor, today first', () async {
      await seedPrefs(cursors: {1: _ago(3)});
      await habitBox.put(1, stepsHabit(id: 1));
      final habitProvider = await createInitializedProvider();
      final service = _PerDayHealthService((day) => 1000 * (_ago(0).difference(_normalize(day)).inDays + 1));
      final health = HealthProvider(service: service)
        ..attachHabitProvider(habitProvider);

      await health.syncNow();

      expect(service.reads, [_ago(0), _ago(3), _ago(2), _ago(1)]);
      for (final back in [3, 2, 1]) {
        final snapshot = habitProvider.habitForDay(1, day: _ago(back));
        expect(snapshot?.amountCompleted, 1000 * (back + 1), reason: '$back days ago');
      }
      expect(
        habitProvider.habits.firstWhere((h) => h.id == 1).amountCompleted,
        1000,
      );
      expect((await storedCursors())[1], _dayKey(_ago(0)));
    });

    test('goes back at most 14 days', () async {
      await seedPrefs(cursors: {1: _ago(30)});
      await habitBox.put(1, stepsHabit(id: 1));
      final habitProvider = await createInitializedProvider();
      final service = _PerDayHealthService((_) => 3000);
      final health = HealthProvider(service: service)
        ..attachHabitProvider(habitProvider);

      await health.syncNow();

      expect(service.reads.first, _ago(0));
      expect(service.reads, hasLength(15));
      expect(service.reads[1], _ago(14));
      expect(service.reads, isNot(contains(_ago(15))));
    });

    test('a habit created yesterday never backfills before that day', () async {
      await seedPrefs(cursors: {1: _ago(6)});
      await habitBox.put(1, stepsHabit(id: 1, createdAt: _ago(1)));
      final habitProvider = await createInitializedProvider();
      final service = _PerDayHealthService((_) => 3000);
      final health = HealthProvider(service: service)
        ..attachHabitProvider(habitProvider);

      await health.syncNow();

      expect(service.reads, [_ago(0), _ago(1)]);
    });

    test('a paused habit is skipped and loses its cursor, so unpausing does not backfill', () async {
      await seedPrefs(cursors: {1: _ago(5)});
      final habit = stepsHabit(id: 1)..isPaused = true;
      await habitBox.put(1, habit);
      final habitProvider = await createInitializedProvider();
      final service = _PerDayHealthService((_) => 3000);
      final health = HealthProvider(service: service)
        ..attachHabitProvider(habitProvider);

      await health.syncNow();
      expect(service.reads, isEmpty);
      expect(await storedCursors(), isEmpty);

      habitProvider.habits.firstWhere((h) => h.id == 1).isPaused = false;
      await health.syncNow();
      expect(service.reads, [_ago(0)]);
    });

    test('an unlinked habit loses its cursor', () async {
      await seedPrefs(cursors: {1: _ago(5), 2: _ago(2)});
      await habitBox.put(1, stepsHabit(id: 1));
      await habitBox.put(2, buildTestHabit(id: 2)); // no healthMetric
      final habitProvider = await createInitializedProvider();
      final health = HealthProvider(service: _PerDayHealthService((_) => 3000))
        ..attachHabitProvider(habitProvider);

      await health.syncNow();

      expect((await storedCursors()).keys, [1]);
    });

    test('a failed read keeps the cursor on that day so it is retried', () async {
      await seedPrefs(cursors: {1: _ago(3)});
      await habitBox.put(1, stepsHabit(id: 1));
      final habitProvider = await createInitializedProvider();
      final service = _PerDayHealthService(
        (day) => _normalize(day) == _ago(2) ? null : 3000,
      );
      final health = HealthProvider(service: service)
        ..attachHabitProvider(habitProvider);

      await health.syncNow();

      expect((await storedCursors())[1], _dayKey(_ago(2)));
      // the day that failed stays untouched, the others were still written
      expect(habitProvider.habitForDay(1, day: _ago(2))?.amountCompleted, 0);
      expect(habitProvider.habitForDay(1, day: _ago(1))?.amountCompleted, 3000);
    });

    test('a past day flipping to complete is saved', () async {
      await seedPrefs(cursors: {1: _ago(2)});
      await habitBox.put(1, stepsHabit(id: 1));
      final habitProvider = await createInitializedProvider();
      final health = HealthProvider(service: _PerDayHealthService((_) => 8000))
        ..attachHabitProvider(habitProvider);

      await health.syncNow();

      expect(habitProvider.habitForDay(1, day: _ago(2))?.completed, isTrue);
      expect(habitProvider.habitForDay(1, day: _ago(1))?.completed, isTrue);
    });

    test('a hand-edited past day keeps its progress during catch-up', () async {
      await seedPrefs(cursors: {1: _ago(2)});
      await habitBox.put(1, stepsHabit(id: 1));
      final habitProvider = await createInitializedProvider();
      // snapshot of 2 days ago, edited by hand
      final dayHabits = habitProvider.getHabitsFromDay(
        _ago(2),
        hydrateMissing: true,
      );
      final snapshot = dayHabits.firstWhere((h) => h.id == 1)
        ..amountCompleted = 7777
        ..healthManualOverride = true;
      await habitProvider.updateHabitInDB(snapshot, day: _ago(2));
      final health = HealthProvider(service: _PerDayHealthService((_) => 100))
        ..attachHabitProvider(habitProvider);

      await health.syncNow();

      expect(
        habitProvider.habitForDay(1, day: _ago(2))?.amountCompleted,
        7777,
      );
    });
  });

  group('empty and corrupt reads', () {
    test('an empty read does not wipe today', () async {
      await habitBox.put(1, stepsHabit(id: 1, amountCompleted: 5200));
      final habitProvider = await createInitializedProvider();
      final health = HealthProvider(service: _PerDayHealthService((_) => 0))
        ..attachHabitProvider(habitProvider);

      await health.syncNow();

      expect(
        habitProvider.habits.firstWhere((h) => h.id == 1).amountCompleted,
        5200,
      );
    });

    test('a corrupt read does not overwrite today', () async {
      await habitBox.put(1, stepsHabit(id: 1, amountCompleted: 5200));
      final habitProvider = await createInitializedProvider();
      final health = HealthProvider(
        service: _PerDayHealthService((_) => 9999999),
      )..attachHabitProvider(habitProvider);

      await health.syncNow();

      expect(
        habitProvider.habits.firstWhere((h) => h.id == 1).amountCompleted,
        5200,
      );
    });

    test('a lower but real value is followed', () async {
      await habitBox.put(1, stepsHabit(id: 1, amountCompleted: 5200));
      final habitProvider = await createInitializedProvider();
      final health = HealthProvider(service: _PerDayHealthService((_) => 3100))
        ..attachHabitProvider(habitProvider);

      await health.syncNow();

      expect(
        habitProvider.habits.firstWhere((h) => h.id == 1).amountCompleted,
        3100,
      );
    });

    test('an empty read on an empty day is still a normal sync', () async {
      await habitBox.put(1, stepsHabit(id: 1));
      final habitProvider = await createInitializedProvider();
      final health = HealthProvider(service: _PerDayHealthService((_) => 0))
        ..attachHabitProvider(habitProvider);

      await health.syncNow();

      expect(health.lastSyncedAt, isNotNull);
      expect(
        habitProvider.habits.firstWhere((h) => h.id == 1).amountCompleted,
        0,
      );
    });

    test('a discarded read is reported as discarded by syncHabitFromHealth', () async {
      await habitBox.put(1, stepsHabit(id: 1, amountCompleted: 5200));
      final habitProvider = await createInitializedProvider();

      final outcome = await habitProvider.syncHabitFromHealth(
        1,
        HealthMetricType.steps,
        0,
        day: DateTime.now(),
      );

      expect(outcome.status, HealthApplyStatus.discarded);
    });
  });

  group('a sync that changes nothing', () {
    List<HealthSessionDetail> sessionsAt(int hour) => [
      HealthSessionDetail(
        start: DateTime(2026, 1, 1, hour),
        end: DateTime(2026, 1, 1, hour + 1),
      ),
    ];

    test('writes nothing: no notify, no timestamp bump', () async {
      await habitBox.put(1, stepsHabit(id: 1));
      final habitProvider = await createInitializedProvider();
      await habitProvider.syncHabitFromHealth(
        1,
        HealthMetricType.steps,
        4000,
        day: DateTime.now(),
        sessions: sessionsAt(8),
      );
      final habit = habitProvider.habits.firstWhere((h) => h.id == 1);
      final stamp = habit.timestamps['amountCompleted'];
      var notified = 0;
      habitProvider.addListener(() => notified++);

      final outcome = await habitProvider.syncHabitFromHealth(
        1,
        HealthMetricType.steps,
        4000,
        day: DateTime.now(),
        sessions: sessionsAt(8),
      );

      expect(outcome.status, HealthApplyStatus.applied);
      expect(outcome.completionChanged, isFalse);
      expect(notified, 0);
      expect(habit.timestamps['amountCompleted'], stamp);
    });

    test('a different value is still written', () async {
      await habitBox.put(1, stepsHabit(id: 1));
      final habitProvider = await createInitializedProvider();
      await habitProvider.syncHabitFromHealth(
        1,
        HealthMetricType.steps,
        4000,
        day: DateTime.now(),
      );
      var notified = 0;
      habitProvider.addListener(() => notified++);

      await habitProvider.syncHabitFromHealth(
        1,
        HealthMetricType.steps,
        4500,
        day: DateTime.now(),
      );

      expect(notified, greaterThan(0));
      expect(
        habitProvider.habits.firstWhere((h) => h.id == 1).amountCompleted,
        4500,
      );
    });

    test('same value but new sessions is still written', () async {
      await habitBox.put(1, stepsHabit(id: 1));
      final habitProvider = await createInitializedProvider();
      await habitProvider.syncHabitFromHealth(
        1,
        HealthMetricType.steps,
        4000,
        day: DateTime.now(),
        sessions: sessionsAt(8),
      );

      await habitProvider.syncHabitFromHealth(
        1,
        HealthMetricType.steps,
        4000,
        day: DateTime.now(),
        sessions: sessionsAt(9),
      );

      expect(
        habitProvider.habits
            .firstWhere((h) => h.id == 1)
            .healthSessions
            .single
            .start,
        DateTime(2026, 1, 1, 9),
      );
    });

    test('a hand-edited day with the same sessions is left alone', () async {
      final habit = stepsHabit(id: 1)..healthManualOverride = true;
      await habitBox.put(1, habit);
      final habitProvider = await createInitializedProvider();
      await habitProvider.syncHabitFromHealth(
        1,
        HealthMetricType.steps,
        4000,
        day: DateTime.now(),
        sessions: sessionsAt(8),
      );
      var notified = 0;
      habitProvider.addListener(() => notified++);

      await habitProvider.syncHabitFromHealth(
        1,
        HealthMetricType.steps,
        4000,
        day: DateTime.now(),
        sessions: sessionsAt(8),
      );

      expect(notified, 0);
    });

    test('syncNow cursors are not rewritten when they did not change', () async {
      await seedPrefs(cursors: {1: _ago(0)});
      await habitBox.put(1, stepsHabit(id: 1));
      final habitProvider = await createInitializedProvider();
      final health = HealthProvider(service: _PerDayHealthService((_) => 4000))
        ..attachHabitProvider(habitProvider);

      await health.syncNow();

      expect((await storedCursors())[1], _dayKey(_ago(0)));
    });
  });

  group('syncHabit (a habit that was just added)', () {
    test('sets the cursor to the link day so later syncs never go before it', () async {
      await habitBox.put(1, stepsHabit(id: 1));
      final habitProvider = await createInitializedProvider();
      final health = HealthProvider(service: _PerDayHealthService((_) => 4200))
        ..attachHabitProvider(habitProvider);

      await health.syncHabit(habitProvider.habits.firstWhere((h) => h.id == 1));

      expect((await storedCursors())[1], _dayKey(_ago(0)));
    });
  });
}
