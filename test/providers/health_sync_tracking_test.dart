import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitt/hive/hive_adapters.dart';
import 'package:habitt/hive/hive_registrar.g.dart';
import 'package:habitt/models/day.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/models/health_metric_type.dart';
import 'package:habitt/models/health_session_detail.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:hive_ce/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../fixtures/habit_factory.dart';

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
}
