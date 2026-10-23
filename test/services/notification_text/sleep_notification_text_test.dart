import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/models/health_metric_type.dart';
import 'package:habitt/models/premade_habit_type.dart';
import 'package:habitt/services/habit_notification_text_builder.dart';
import 'package:habitt/services/notification_text/sleep_notification_text.dart';

import '../../fixtures/habit_factory.dart';

void main() {
  final en = lookupAppLocalizations(const Locale('en'));

  HabitNotificationContext contextFor(
    Habit habit,
    DateTime scheduledAt, {
    AppLocalizations? l10n,
  }) {
    return HabitNotificationContext(
      habit: habit,
      scheduledAt: scheduledAt,
      appearsOnDay: (_, __) => true,
      localizations: l10n ?? en,
      now: scheduledAt.subtract(const Duration(hours: 1)),
    );
  }

  Habit bedtimeHabit({int amount = 22 * 60}) => buildTestHabit(
    trackingType: HabitTrackingType.timeOfDay,
    healthMetric: HealthMetricType.bedtime,
    amount: amount,
  );

  group('formatSleepDuration', () {
    test('speaks minutes as hours and minutes', () {
      expect(SleepNotificationText.formatSleepDuration(en, 15), '15 minutes');
      expect(SleepNotificationText.formatSleepDuration(en, 1), '1 minute');
      expect(SleepNotificationText.formatSleepDuration(en, 60), '1 hour');
      expect(
        SleepNotificationText.formatSleepDuration(en, 61),
        '1 hour and 1 minute',
      );
      expect(SleepNotificationText.formatSleepDuration(en, 8 * 60), '8 hours');
      expect(
        SleepNotificationText.formatSleepDuration(en, 7 * 60 + 30),
        '7 hours and 30 minutes',
      );
    });

    test('uses the right plural forms in other languages', () {
      final de = lookupAppLocalizations(const Locale('de'));
      final bs = lookupAppLocalizations(const Locale('bs'));

      expect(
        SleepNotificationText.formatSleepDuration(de, 61),
        '1 Stunde und 1 Minute',
      );
      expect(
        SleepNotificationText.formatSleepDuration(de, 8 * 60),
        '8 Stunden',
      );
      expect(SleepNotificationText.formatSleepDuration(bs, 2 * 60), '2 sata');
      expect(SleepNotificationText.formatSleepDuration(bs, 5 * 60), '5 sati');
      expect(SleepNotificationText.formatSleepDuration(bs, 21), '21 minuta');
    });
  });

  group('formatClock', () {
    test('uses 12-hour time in English and wraps bedtimes past midnight', () {
      expect(SleepNotificationText.formatClock(en, 22 * 60), '10:00 PM');
      expect(SleepNotificationText.formatClock(en, 7 * 60), '7:00 AM');
      expect(SleepNotificationText.formatClock(en, 24 * 60 + 15), '12:15 AM');
      expect(SleepNotificationText.formatClock(en, 24 * 60 + 75), '1:15 AM');
    });

    test('uses 24-hour time in other languages', () {
      final de = lookupAppLocalizations(const Locale('de'));
      expect(SleepNotificationText.formatClock(de, 22 * 60), '22:00');
    });
  });

  group('metricFor', () {
    test('only claims the three sleep habits', () {
      expect(
        SleepNotificationText.metricFor(bedtimeHabit()),
        HealthMetricType.bedtime,
      );
      expect(
        SleepNotificationText.metricFor(
          buildTestHabit(healthMetric: HealthMetricType.sleep, amount: 480),
        ),
        HealthMetricType.sleep,
      );
      expect(
        SleepNotificationText.metricFor(buildTestHabit(amount: 10)),
        isNull,
      );
      expect(
        SleepNotificationText.metricFor(
          buildTestHabit(healthMetric: HealthMetricType.steps, amount: 6000),
        ),
        isNull,
      );
    });

    test('falls back to the premade type when Health sync is off', () {
      final habit = buildTestHabit(
        trackingType: HabitTrackingType.timeOfDay,
        amount: 7 * 60,
        premadeHabitType: PremadeHabitType.wakeUpEarly,
      );
      expect(SleepNotificationText.metricFor(habit), HealthMetricType.wakeTime);
    });
  });

  group('build', () {
    test('bedtime reminder shortly before bedtime says how long is left', () {
      final text = SleepNotificationText.build(
        contextFor(bedtimeHabit(), DateTime(2026, 10, 21, 21, 45)),
        random: math.Random(1),
      );

      expect(text, isNotNull);
      expect(text, contains('15 minutes'));
      expect(text, isNot(contains('times')));
    });

    test('bedtime countdown converts to hours', () {
      final text = SleepNotificationText.build(
        contextFor(bedtimeHabit(), DateTime(2026, 10, 21, 20, 30)),
        random: math.Random(2),
      );

      expect(text, contains('1 hour and 30 minutes'));
    });

    test('bedtime reminder far from bedtime uses the general wording', () {
      final text =
          SleepNotificationText.build(
            contextFor(bedtimeHabit(), DateTime(2026, 10, 21, 12, 0)),
            random: math.Random(3),
          )!;

      expect(text, isNot(contains('in 10 hours')));
      expect(text, isNot(matches(RegExp(r'\d+ (hours?|minutes?)'))));
    });

    test('wake up reminders show the target as a clock time', () {
      final habit = buildTestHabit(
        trackingType: HabitTrackingType.timeOfDay,
        healthMetric: HealthMetricType.wakeTime,
        amount: 7 * 60,
      );

      final texts = [
        for (var seed = 0; seed < 20; seed++)
          SleepNotificationText.build(
            contextFor(habit, DateTime(2026, 10, 21, 7, 0)),
            random: math.Random(seed),
          )!,
      ];

      // not every variant names the time, but those that do format it
      expect(texts.any((t) => t.contains('7:00 AM')), isTrue);
      expect(texts.any((t) => t.contains('420')), isFalse);
    });

    test('sleep time reminder mentions the goal in hours, not raw minutes', () {
      final habit = buildTestHabit(
        healthMetric: HealthMetricType.sleep,
        amount: 8 * 60,
      );

      for (var seed = 0; seed < 8; seed++) {
        final text =
            SleepNotificationText.build(
              contextFor(habit, DateTime(2026, 10, 21, 21, 0)),
              random: math.Random(seed),
            )!;

        expect(text, contains('8 hours'));
        expect(text, isNot(contains('480')));
      }
    });

    test(
      'sleep time reminder with hand-logged sleep shows progress as durations',
      () {
        final habit = buildTestHabit(
          premadeHabitType: PremadeHabitType.sleepTime,
          amount: 8 * 60,
          amountCompleted: 61,
        );

        for (var seed = 0; seed < 8; seed++) {
          final text =
              SleepNotificationText.build(
                contextFor(habit, DateTime(2026, 10, 21, 9, 0)),
                random: math.Random(seed),
              )!;

          expect(text, contains('1 hour and 1 minute'));
          expect(text, contains('8 hours'));
          expect(text, isNot(contains('61')));
        }
      },
    );

    test('Health-linked sleep never quotes its stale progress', () {
      final habit = buildTestHabit(
        healthMetric: HealthMetricType.sleep,
        amount: 8 * 60,
        amountCompleted: 61,
      );

      for (var seed = 0; seed < 8; seed++) {
        final text =
            SleepNotificationText.build(
              contextFor(habit, DateTime(2026, 10, 21, 9, 0)),
              random: math.Random(seed),
            )!;

        expect(text, contains('8 hours'));
        expect(text, isNot(contains('1 hour and 1 minute')));
      }
    });

    test('regular habits are left to the generic templates', () {
      final habit = buildTestHabit(amount: 10);

      expect(
        SleepNotificationText.build(
          contextFor(habit, DateTime(2026, 10, 21, 9)),
        ),
        isNull,
      );
    });
  });

  test('the full builder uses sleep wording for a sleep habit', () {
    final habit = buildTestHabit(
      healthMetric: HealthMetricType.sleep,
      amount: 8 * 60,
      amountCompleted: 61,
    );

    final text = HabitNotificationTextBuilder.build(
      contextFor(habit, DateTime(2026, 10, 21, 9, 0)),
    );

    expect(text.evaluatedChecks, contains('combined.sleep'));
    expect(text.description, contains('8 hours'));
    expect(text.description, isNot(contains('times')));
  });
}
