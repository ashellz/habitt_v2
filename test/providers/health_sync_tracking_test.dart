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
import 'package:hive_ce/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../fixtures/habit_factory.dart';

/// Health stand-in that always reports [value] seconds and one session.
class _FakeHealthService extends HealthService {
  _FakeHealthService(this.value);

  final int? value;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<bool> hasPermissions() async => true;

  @override
  bool isMetricSupported(HealthMetricType metric) => true;

  @override
  Future<int?> fetchValueForDay(
    HealthMetricType metric,
    DateTime day, {
    HabitTrackingType? trackingType,
    HealthWorkoutType? workoutFilter,
    bool bedtimeDayBefore = false,
  }) async => value;

  @override
  Future<List<HealthSessionDetail>> fetchSessionsForDay(
    HealthMetricType metric,
    DateTime day, {
    HealthWorkoutType? workoutFilter,
    bool bedtimeDayBefore = false,
  }) async => _sessions(1);
}

DateTime _normalize(DateTime date) => DateTime(date.year, date.month, date.day);

String _dayKey(DateTime date) =>
    _normalize(date).toIso8601String().split('T').first;

/// `syncHabitFromHealth` can flip `Habit.completed`, which fans out into
/// `NotificationService` (real platform-channel calls via
/// `awesome_notifications`). Stub the channel so those calls resolve
/// harmlessly instead of throwing `MissingPluginException` in a unit test.
const _notificationsChannel = MethodChannel('awesome_notifications');

List<HealthSessionDetail> _sessions(int count) => List.generate(
  count,
  (i) => HealthSessionDetail(
    start: DateTime.now().subtract(Duration(minutes: 30 * (i + 1))),
    end: DateTime.now().subtract(Duration(minutes: 30 * i)),
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Box<Habit> habitBox;
  late Box<Day> daysBox;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('health_sync_tracking_test');
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

  group('syncHabitFromHealth tracking-type routing', () {
    test('Amount-mode workout habit writes amountCompleted, not durationCompleted', () async {
      await habitBox.put(
        1,
        buildTestHabit(
          id: 1,
          healthMetric: HealthMetricType.workouts,
          trackingType: HabitTrackingType.amount,
          amount: 5,
          duration: 0,
        ),
      );
      final provider = await createInitializedProvider();

      await provider.syncHabitFromHealth(
        1,
        HealthMetricType.workouts,
        2,
        day: DateTime.now(),
        sessions: _sessions(2),
      );

      final habit = provider.habits.firstWhere((h) => h.id == 1);
      expect(habit.amountCompleted, 2);
      expect(habit.durationCompleted, 0);
      expect(habit.completed, isFalse);
    });

    test('Duration-mode workout habit writes durationCompleted, not amountCompleted', () async {
      await habitBox.put(
        2,
        buildTestHabit(
          id: 2,
          healthMetric: HealthMetricType.workouts,
          trackingType: HabitTrackingType.duration,
          amount: 0,
          duration: 1200,
        ),
      );
      final provider = await createInitializedProvider();

      await provider.syncHabitFromHealth(
        2,
        HealthMetricType.workouts,
        600,
        day: DateTime.now(),
        sessions: _sessions(1),
      );

      final habit = provider.habits.firstWhere((h) => h.id == 2);
      expect(habit.durationCompleted, 600);
      expect(habit.amountCompleted, 0);
      expect(habit.completed, isFalse);
    });

    test('activity habit writes durationCompleted and completes', () async {
      await habitBox.put(
        4,
        buildTestHabit(
          id: 4,
          healthMetric: HealthMetricType.activity,
          trackingType: HabitTrackingType.duration,
          amount: 0,
          duration: 30, // minutes: the seconds migration runs on init
        ),
      );
      final provider = await createInitializedProvider();

      await provider.syncHabitFromHealth(
        4,
        HealthMetricType.activity,
        35 * 60,
        day: DateTime.now(),
        sessions: _sessions(1),
      );

      final habit = provider.habits.firstWhere((h) => h.id == 4);
      expect(habit.durationCompleted, 35 * 60);
      expect(habit.amountCompleted, 0);
      expect(habit.completed, isTrue);
    });

    test('Amount-mode mindfulness habit writes amountCompleted', () async {
      await habitBox.put(
        3,
        buildTestHabit(
          id: 3,
          healthMetric: HealthMetricType.mindfulness,
          trackingType: HabitTrackingType.amount,
          amount: 4,
          duration: 0,
        ),
      );
      final provider = await createInitializedProvider();

      await provider.syncHabitFromHealth(
        3,
        HealthMetricType.mindfulness,
        1,
        day: DateTime.now(),
        sessions: _sessions(1),
      );

      final habit = provider.habits.firstWhere((h) => h.id == 3);
      expect(habit.amountCompleted, 1);
      expect(habit.durationCompleted, 0);
    });

    test('a metric with a fixed tracking type ignores habit.trackingType', () {
      // Steps never lets the user choose a tracking mode — even if a habit
      // somehow carries a mismatched trackingType, sync must still route by
      // the metric's fixed mapping (amount), not the habit's stray value.
      expect(HealthMetricType.steps.supportsTrackingChoice, isFalse);
    });

    test('non-dual metric routes by its fixed mapping regardless of habit.trackingType', () async {
      await habitBox.put(
        4,
        buildTestHabit(
          id: 4,
          healthMetric: HealthMetricType.steps,
          // Contrived mismatch: steps' fixed mapping is `amount`, so this
          // stray `duration` value must be ignored by the routing fix.
          trackingType: HabitTrackingType.duration,
          amount: 0,
          duration: 500,
        ),
      );
      final provider = await createInitializedProvider();

      await provider.syncHabitFromHealth(
        4,
        HealthMetricType.steps,
        50,
        day: DateTime.now(),
      );

      final habit = provider.habits.firstWhere((h) => h.id == 4);
      expect(habit.amountCompleted, 50);
      expect(habit.durationCompleted, 0);
    });
  });

  group('syncHabitFromHealth zero-target completion', () {
    test('Amount-mode workout habit with no target and no sessions stays incomplete', () async {
      await habitBox.put(
        5,
        buildTestHabit(
          id: 5,
          healthMetric: HealthMetricType.workouts,
          trackingType: HabitTrackingType.amount,
          amount: 0,
          duration: 0,
        ),
      );
      final provider = await createInitializedProvider();

      await provider.syncHabitFromHealth(
        5,
        HealthMetricType.workouts,
        0,
        day: DateTime.now(),
        sessions: const [],
      );

      final habit = provider.habits.firstWhere((h) => h.id == 5);
      expect(habit.completed, isFalse);
    });

    test('Amount-mode workout habit with no target completes once a session is logged', () async {
      await habitBox.put(
        6,
        buildTestHabit(
          id: 6,
          healthMetric: HealthMetricType.workouts,
          trackingType: HabitTrackingType.amount,
          amount: 0,
          duration: 0,
        ),
      );
      final provider = await createInitializedProvider();

      await provider.syncHabitFromHealth(
        6,
        HealthMetricType.workouts,
        2,
        day: DateTime.now(),
        sessions: _sessions(2),
      );

      final habit = provider.habits.firstWhere((h) => h.id == 6);
      expect(habit.completed, isTrue);
    });

    test('Duration-mode mindfulness habit with no target completes once a session is logged', () async {
      await habitBox.put(
        7,
        buildTestHabit(
          id: 7,
          healthMetric: HealthMetricType.mindfulness,
          trackingType: HabitTrackingType.duration,
          amount: 0,
          duration: 0,
        ),
      );
      final provider = await createInitializedProvider();

      await provider.syncHabitFromHealth(
        7,
        HealthMetricType.mindfulness,
        600,
        day: DateTime.now(),
        sessions: _sessions(1),
      );

      final habit = provider.habits.firstWhere((h) => h.id == 7);
      expect(habit.completed, isTrue);
    });

    test('a nonzero target still uses the normal >= comparison, both ways', () async {
      await habitBox.put(
        8,
        buildTestHabit(
          id: 8,
          healthMetric: HealthMetricType.workouts,
          trackingType: HabitTrackingType.amount,
          amount: 3,
          duration: 0,
        ),
      );
      final provider = await createInitializedProvider();

      await provider.syncHabitFromHealth(
        8,
        HealthMetricType.workouts,
        3,
        day: DateTime.now(),
        sessions: _sessions(3),
      );
      expect(provider.habits.firstWhere((h) => h.id == 8).completed, isTrue);

      await provider.syncHabitFromHealth(
        8,
        HealthMetricType.workouts,
        2,
        day: DateTime.now(),
        sessions: _sessions(2),
      );
      expect(provider.habits.firstWhere((h) => h.id == 8).completed, isFalse);
    });
  });

  group('syncHabitFromHealth manual override', () {
    // the habits are written in seconds already, so skip the one-time
    // minutes-to-seconds migration that would otherwise scale them by 60
    setUp(() {
      final today = _normalize(DateTime.now());
      SharedPreferences.setMockInitialValues({
        'lastNotificationSyncDate': _dayKey(today),
        'daySnapshotsSanitized_v1': true,
        'dateJoined':
            today.subtract(const Duration(days: 60)).toIso8601String(),
        'durationSecondsMigrated_habits_v1': true,
        'durationSecondsMigrated_days_v1': true,
      });
    });

    Habit overriddenWorkout({required int id}) =>
        buildTestHabit(
            id: id,
            healthMetric: HealthMetricType.workouts,
            trackingType: HabitTrackingType.duration,
            amount: 0,
            duration: 3000,
            durationCompleted: 3300, // user typed 55m over a synced 30m
          )
          ..completed = true
          ..healthManualOverride = true;

    test('a hand-edited day keeps its progress when Health reports less', () async {
      await habitBox.put(9, overriddenWorkout(id: 9));
      final provider = await createInitializedProvider();

      await provider.syncHabitFromHealth(
        9,
        HealthMetricType.workouts,
        1800,
        day: DateTime.now(),
        sessions: _sessions(1),
      );

      final habit = provider.habits.firstWhere((h) => h.id == 9);
      expect(habit.durationCompleted, 3300);
      expect(habit.completed, isTrue);
      expect(habit.healthManualOverride, isTrue);
    });

    test('a hand-edited day still refreshes its session list', () async {
      await habitBox.put(10, overriddenWorkout(id: 10));
      final provider = await createInitializedProvider();

      await provider.syncHabitFromHealth(
        10,
        HealthMetricType.workouts,
        1800,
        day: DateTime.now(),
        sessions: _sessions(2),
      );

      final habit = provider.habits.firstWhere((h) => h.id == 10);
      expect(habit.healthSessions, hasLength(2));
      expect(habit.durationCompleted, 3300);
    });

    test('clearing the override lets the next sync write Health values again', () async {
      await habitBox.put(11, overriddenWorkout(id: 11));
      final provider = await createInitializedProvider();

      await provider.clearHealthManualOverride(11, day: DateTime.now());
      await provider.syncHabitFromHealth(
        11,
        HealthMetricType.workouts,
        1800,
        day: DateTime.now(),
        sessions: _sessions(1),
      );

      final habit = provider.habits.firstWhere((h) => h.id == 11);
      expect(habit.healthManualOverride, isFalse);
      expect(habit.durationCompleted, 1800);
      expect(habit.completed, isFalse);
    });

    test('using Health values re-syncs the day and refreshes the last-synced state', () async {
      await habitBox.put(12, overriddenWorkout(id: 12));
      final habitProvider = await createInitializedProvider();
      final health = HealthProvider(service: _FakeHealthService(1800))
        ..attachHabitProvider(habitProvider);
      final habit = habitProvider.habits.firstWhere((h) => h.id == 12);

      final syncingStates = <bool>[];
      health.addListener(() => syncingStates.add(health.isSyncing));
      expect(health.lastSyncedAt, isNull);

      await health.useHealthValues(habit, DateTime.now());

      final synced = habitProvider.habits.firstWhere((h) => h.id == 12);
      expect(synced.healthManualOverride, isFalse);
      expect(synced.durationCompleted, 1800);
      expect(synced.healthSessions, hasLength(1));
      expect(health.lastSyncedAt, isNotNull);
      expect(health.isSyncing, isFalse);
      // went through a visible "syncing" state and ended on idle
      expect(syncingStates, contains(true));
      expect(syncingStates.last, isFalse);
    });

    test('no Health value: override is cleared but last-synced stays untouched', () async {
      await habitBox.put(13, overriddenWorkout(id: 13));
      final habitProvider = await createInitializedProvider();
      final health = HealthProvider(service: _FakeHealthService(null))
        ..attachHabitProvider(habitProvider);
      final habit = habitProvider.habits.firstWhere((h) => h.id == 13);

      await health.useHealthValues(habit, DateTime.now());

      final after = habitProvider.habits.firstWhere((h) => h.id == 13);
      expect(after.healthManualOverride, isFalse);
      expect(after.durationCompleted, 3300);
      expect(health.lastSyncedAt, isNull);
      expect(health.isSyncing, isFalse);
    });
  });

  group('syncHabit (a habit that was just added)', () {
    Habit stepsHabit({required int id}) => buildTestHabit(
      id: id,
      trackingType: HabitTrackingType.amount,
      healthMetric: HealthMetricType.steps,
      amount: 6000,
      amountLabel: 'steps',
    );

    test('pulls today\'s Health value instead of starting at 0', () async {
      await habitBox.put(20, stepsHabit(id: 20));
      final habitProvider = await createInitializedProvider();
      final health = HealthProvider(service: _FakeHealthService(4200))
        ..attachHabitProvider(habitProvider);
      final habit = habitProvider.habits.firstWhere((h) => h.id == 20);
      expect(habit.amountCompleted, 0);

      await health.syncHabit(habit);

      final synced = habitProvider.habits.firstWhere((h) => h.id == 20);
      expect(synced.amountCompleted, 4200);
      expect(synced.completed, isFalse);
      expect(health.lastSyncedAt, isNotNull);
    });

    test('completes the habit when Health is already past the goal', () async {
      await habitBox.put(21, stepsHabit(id: 21));
      final habitProvider = await createInitializedProvider();
      final health = HealthProvider(service: _FakeHealthService(8000))
        ..attachHabitProvider(habitProvider);

      await health.syncHabit(habitProvider.habits.firstWhere((h) => h.id == 21));

      expect(habitProvider.habits.firstWhere((h) => h.id == 21).completed, isTrue);
    });

    test('no Health value leaves the habit at 0', () async {
      await habitBox.put(22, stepsHabit(id: 22));
      final habitProvider = await createInitializedProvider();
      final health = HealthProvider(service: _FakeHealthService(null))
        ..attachHabitProvider(habitProvider);

      await health.syncHabit(habitProvider.habits.firstWhere((h) => h.id == 22));

      expect(habitProvider.habits.firstWhere((h) => h.id == 22).amountCompleted, 0);
      expect(health.lastSyncedAt, isNull);
    });

    test('a habit without a Health metric is ignored', () async {
      await habitBox.put(23, buildTestHabit(id: 23));
      final habitProvider = await createInitializedProvider();
      final health = HealthProvider(service: _FakeHealthService(4200))
        ..attachHabitProvider(habitProvider);

      await health.syncHabit(habitProvider.habits.firstWhere((h) => h.id == 23));

      expect(habitProvider.habits.firstWhere((h) => h.id == 23).amountCompleted, 0);
    });
  });
}
