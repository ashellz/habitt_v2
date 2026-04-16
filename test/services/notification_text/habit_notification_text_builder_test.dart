import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/services/habit_notification_text_builder.dart';

import '../../fixtures/habit_factory.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));

  HabitNotificationContext buildContext(
    Habit habit, {
    required DateTime scheduledAt,
    required HabitAppearsOnDay appearsOnDay,
  }) {
    return HabitNotificationContext(
      habit: habit,
      scheduledAt: scheduledAt,
      appearsOnDay: appearsOnDay,
      localizations: l10n,
      now: scheduledAt.subtract(const Duration(hours: 1)),
    );
  }

  test('evaluates all checks and composes concise body', () {
    final scheduledAt = DateTime(2026, 4, 16, 9, 0);
    final habit = buildTestHabit(
      amount: 10,
      amountCompleted: 8,
      amountLabel: 'dl',
      optional: true,
      trackingType: HabitTrackingType.amount,
      createdAt: DateTime(2026, 4, 13),
    );

    final text = HabitNotificationTextBuilder.build(
      buildContext(
        habit,
        scheduledAt: scheduledAt,
        appearsOnDay: (_, __) => true,
      ),
      maxSegments: 3,
    );

    expect(
      text.evaluatedChecks,
      containsAll(<String>[
        'premadeType',
        'progress',
        'schedule',
        'freshness',
        'amountLabel',
        'optional',
      ]),
    );
    expect(text.selectedSegmentCategories.length, lessThanOrEqualTo(3));
    expect(text.progressState, HabitNotificationProgressState.almostDone);
    expect(text.scheduleState, HabitNotificationScheduleState.daily);
    expect(text.description, contains('Hydrate now'));
  });

  test('uses fallback title when habit name is empty', () {
    final scheduledAt = DateTime(2026, 4, 16, 9, 0);
    final habit = buildTestHabit(name: '   ');

    final text = HabitNotificationTextBuilder.build(
      buildContext(
        habit,
        scheduledAt: scheduledAt,
        appearsOnDay: (_, __) => true,
      ),
    );

    expect(text.title, l10n.notificationFallbackTitle);
  });
}
