import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/models/health_metric_type.dart';
import 'package:habitt/models/health_workout_type.dart';
import 'package:habitt/models/premade_habit_type.dart';
import 'package:habitt/services/habit_notification_text_builder.dart';
import 'package:habitt/services/notification_text/health_metric_notification_text.dart';

import '../../fixtures/habit_factory.dart';

void main() {
  final en = lookupAppLocalizations(const Locale('en'));

  HabitNotificationContext contextFor(Habit habit, {AppLocalizations? l10n}) {
    final scheduledAt = DateTime(2026, 10, 21, 18);
    return HabitNotificationContext(
      habit: habit,
      scheduledAt: scheduledAt,
      appearsOnDay: (_, __) => true,
      localizations: l10n ?? en,
      now: scheduledAt.subtract(const Duration(hours: 1)),
    );
  }

  /// Every variant the habit can produce, over many seeds.
  Set<String> variants(Habit habit, {AppLocalizations? l10n}) {
    return {
      for (var seed = 0; seed < 60; seed++)
        HealthMetricNotificationText.build(
          contextFor(habit, l10n: l10n),
          random: math.Random(seed),
        )!,
    };
  }

  // [linked] false is a hand-logged habit: same premade type, no Health sync
  Habit steps({int done = 0, String label = 'steps', bool linked = true}) =>
      buildTestHabit(
    healthMetric: linked ? HealthMetricType.steps : null,
    premadeHabitType: PremadeHabitType.steps,
    amount: 6000,
    amountCompleted: done,
    amountLabel: label,
  );

  Habit activeCalories({int done = 0, bool linked = true}) => buildTestHabit(
    healthMetric: linked ? HealthMetricType.activeCalories : null,
    premadeHabitType: PremadeHabitType.activeCalories,
    amount: 230,
    amountCompleted: done,
    amountLabel: 'calories',
  );

  Habit totalCalories({int done = 0, bool linked = true}) => buildTestHabit(
    healthMetric: linked ? HealthMetricType.totalCalories : null,
    premadeHabitType: PremadeHabitType.totalCalories,
    amount: 1700,
    amountCompleted: done,
    amountLabel: 'calories',
  );

  Habit workout({
    HealthWorkoutType? filter,
    PremadeHabitType type = PremadeHabitType.workoutCombined,
    int goalMinutes = 30,
    int doneMinutes = 0,
    bool linked = true,
  }) => buildTestHabit(
    trackingType: HabitTrackingType.duration,
    healthMetric: linked ? HealthMetricType.workouts : null,
    healthWorkoutFilter: filter,
    premadeHabitType: type,
    duration: goalMinutes * 60,
    durationCompleted: doneMinutes * 60,
  );

  Habit mindfulness({int doneMinutes = 0, bool linked = true}) =>
      buildTestHabit(
    trackingType: HabitTrackingType.duration,
    healthMetric: linked ? HealthMetricType.mindfulness : null,
    premadeHabitType: PremadeHabitType.mindfulness,
    duration: 10 * 60,
    durationCompleted: doneMinutes * 60,
  );

  Habit activity({int doneMinutes = 0, bool linked = true}) => buildTestHabit(
    trackingType: HabitTrackingType.duration,
    healthMetric: linked ? HealthMetricType.activity : null,
    premadeHabitType: PremadeHabitType.activity,
    duration: 30 * 60,
    durationCompleted: doneMinutes * 60,
  );

  group('metricFor', () {
    test('only claims the supported activity habits', () {
      expect(
        HealthMetricNotificationText.metricFor(steps()),
        HealthMetricType.steps,
      );
      expect(
        HealthMetricNotificationText.metricFor(workout()),
        HealthMetricType.workouts,
      );
      expect(
        HealthMetricNotificationText.metricFor(mindfulness()),
        HealthMetricType.mindfulness,
      );
      expect(
        HealthMetricNotificationText.metricFor(activity()),
        HealthMetricType.activity,
      );
      expect(
        HealthMetricNotificationText.metricFor(activity(linked: false)),
        HealthMetricType.activity,
      );
      expect(
        HealthMetricNotificationText.metricFor(buildTestHabit(amount: 10)),
        isNull,
      );
      expect(
        HealthMetricNotificationText.metricFor(
          buildTestHabit(healthMetric: HealthMetricType.sleep, amount: 480),
        ),
        isNull,
      );
    });

    test('falls back to the premade type when Health sync is off', () {
      final habit = buildTestHabit(
        trackingType: HabitTrackingType.duration,
        premadeHabitType: PremadeHabitType.workoutRunning,
        duration: 1800,
      );
      expect(
        HealthMetricNotificationText.metricFor(habit),
        HealthMetricType.workouts,
      );
    });

    test('workouts tracked as an amount are supported too', () {
      final habit = buildTestHabit(
        healthMetric: HealthMetricType.workouts,
        premadeHabitType: PremadeHabitType.workoutCombined,
        amount: 3,
        amountLabel: 'times',
      );
      final text = HealthMetricNotificationText.build(contextFor(habit));
      expect(text, isNotNull);
    });
  });

  group('steps and calories', () {
    test('goal is shown with a thousands separator, not a raw number', () {
      final all = variants(steps());

      expect(all.any((t) => t.contains('6,000 steps')), isTrue);
      expect(all.any((t) => t.contains('6000')), isFalse);
      expect(all.any((t) => t.contains('times')), isFalse);
    });

    test('hand-logged progress reports what is done and what is left', () {
      final all = variants(steps(done: 4000, linked: false));

      expect(all.any((t) => t.contains('4,000 steps')), isTrue);
      expect(all.any((t) => t.contains('2,000 steps')), isTrue);
    });

    test('Health-linked progress is never quoted, only the goal', () {
      // the synced value is whatever the last app open saw, which is stale by
      // the time the notification fires
      final pairs = <(Habit, Habit)>[
        (steps(done: 4000), steps()),
        (activeCalories(done: 6), activeCalories()),
        (totalCalories(done: 100), totalCalories()),
        (mindfulness(doneMinutes: 3), mindfulness()),
        (workout(goalMinutes: 30, doneMinutes: 12), workout(goalMinutes: 30)),
      ];
      for (final (withProgress, untouched) in pairs) {
        expect(
          variants(withProgress),
          equals(variants(untouched)),
          reason: '${withProgress.healthMetric}',
        );
      }

      final calories = variants(activeCalories(done: 6));
      expect(calories.any((t) => t.contains('230 calories')), isTrue);
      expect(calories.any((t) => t.contains('6 calories')), isFalse);
      expect(calories.any((t) => t.contains('224')), isFalse);
    });

    test('a generic "times" label falls back to the metric unit', () {
      final all = variants(steps(label: 'times'));
      expect(all.any((t) => t.contains('6,000 steps')), isTrue);
      expect(all.any((t) => t.contains('times')), isFalse);

      final calories = buildTestHabit(
        healthMetric: HealthMetricType.activeCalories,
        amount: 230,
        amountLabel: 'times',
      );
      expect(variants(calories).any((t) => t.contains('230 calories')), isTrue);
    });

    test('active and total calories use their own wording', () {
      final active = variants(activeCalories());
      final total = variants(totalCalories());

      expect(active.any((t) => t.contains('230 calories')), isTrue);
      expect(total.any((t) => t.contains('1,700 calories')), isTrue);
      expect(active.intersection(total), isEmpty);
    });

    test('a one-unit remainder uses the singular label', () {
      final all = variants(activeCalories(done: 229, linked: false));
      expect(all.any((t) => t.contains('1 calorie')), isTrue);
      expect(all.any((t) => t.contains('1 calories')), isFalse);
    });

    test('numbers follow the language', () {
      final de = lookupAppLocalizations(const Locale('de'));
      expect(
        variants(steps(), l10n: de).any((t) => t.contains('6.000')),
        isTrue,
      );
    });
  });

  group('workouts and mindfulness', () {
    test('durations are spoken, not shown as raw numbers', () {
      final all = variants(workout(goalMinutes: 90));

      expect(all.any((t) => t.contains('1 hour and 30 minutes')), isTrue);
      expect(all.any((t) => t.contains('5400')), isFalse);
    });

    test('hand-logged progress shows done and remaining time', () {
      final all = variants(
        workout(goalMinutes: 30, doneMinutes: 12, linked: false),
      );

      expect(all.any((t) => t.contains('12 minutes')), isTrue);
      expect(all.any((t) => t.contains('18 minutes')), isTrue);
    });

    test('remaining time never rounds down to zero', () {
      final habit = buildTestHabit(
        trackingType: HabitTrackingType.duration,
        premadeHabitType: PremadeHabitType.workoutCombined,
        duration: 1800,
        durationCompleted: 1790, // 10 seconds short
      );
      final all = variants(habit);

      expect(all.any((t) => RegExp(r'(^|\D)0 minutes').hasMatch(t)), isFalse);
      expect(all.any((t) => t.contains('1 minute')), isTrue);
    });

    test('names the specific activity', () {
      final running = variants(
        workout(
          filter: HealthWorkoutType.running,
          type: PremadeHabitType.workoutRunning,
        ),
      );
      final swimming = variants(
        workout(
          filter: HealthWorkoutType.swimming,
          type: PremadeHabitType.workoutSwimming,
        ),
      );

      expect(running.any((t) => t.contains('Running')), isTrue);
      expect(swimming.any((t) => t.contains('Swimming')), isTrue);
      // each activity also has its own nudge
      expect(running.any((t) => t.contains('run')), isTrue);
      expect(
        swimming.any((t) => t.contains('pool') || t.contains('swim')),
        isTrue,
      );
    });

    test('takes the activity from the premade type when no filter is set', () {
      final all = variants(workout(type: PremadeHabitType.workoutCycling));
      expect(all.any((t) => t.contains('Cycling')), isTrue);
    });

    test('a general workout is just called Workout', () {
      final all = variants(workout());
      expect(all.any((t) => t.contains('Workout')), isTrue);
    });

    test('mindfulness speaks its goal as time', () {
      final all = variants(mindfulness());
      expect(all.any((t) => t.contains('10 minutes')), isTrue);
    });
  });

  test('a reached goal falls back to the regular templates', () {
    expect(
      HealthMetricNotificationText.build(contextFor(steps(done: 6000))),
      isNull,
    );
    expect(
      HealthMetricNotificationText.build(contextFor(workout(doneMinutes: 30))),
      isNull,
    );
  });

  test('the full builder uses the new wording for these habits', () {
    final text = HabitNotificationTextBuilder.build(
      contextFor(steps(done: 4000)),
    );

    expect(text.evaluatedChecks, contains('combined.healthMetric'));
    expect(text.description, contains('steps'));
    expect(text.description, isNot(contains('4000')));
  });

  test('every language renders every state without leftover placeholders', () {
    final habits = <String, Habit>{
      'steps start': steps(),
      'steps progress': steps(done: 1000, linked: false),
      'active start': activeCalories(),
      'active progress': activeCalories(done: 100, linked: false),
      'total start': totalCalories(),
      'total progress': totalCalories(done: 100, linked: false),
      'mindfulness start': mindfulness(),
      'mindfulness progress': mindfulness(doneMinutes: 3, linked: false),
      'workout start': workout(),
      'workout progress': workout(doneMinutes: 10, linked: false),
      for (final type in HealthWorkoutType.values)
        'workout ${type.name} start': workout(filter: type),
      for (final type in HealthWorkoutType.values)
        'workout ${type.name} progress': workout(
          filter: type,
          doneMinutes: 10,
          linked: false,
        ),
    };

    for (final locale in AppLocalizations.supportedLocales) {
      final l10n = lookupAppLocalizations(locale);
      habits.forEach((name, habit) {
        for (final text in variants(habit, l10n: l10n)) {
          expect(text.trim(), isNotEmpty, reason: '$locale $name');
          expect(text, isNot(contains('{')), reason: '$locale $name: $text');
          expect(text, isNot(contains('}')), reason: '$locale $name: $text');
          expect(text, isNot(contains('|')), reason: '$locale $name: $text');
        }
      });
    }
  });
}
