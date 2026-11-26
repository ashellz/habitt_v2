import 'dart:convert';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/models/health_metric_type.dart';
import 'package:habitt/providers/stats_provider.dart';
import 'package:habitt/services/theme_catalog.dart';
import 'package:habitt/services/widget_snapshot_builder.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../fixtures/habit_factory.dart';

final _now = DateTime(2026, 11, 24, 8, 30); // a Tuesday morning
final _today = DateTime(2026, 11, 24);

Habit _habit(
  int id,
  String name, {
  int category = 2,
  String emoji = '🪥',
  HabitTrackingType? type = HabitTrackingType.amount,
  int amount = 1,
  int amountCompleted = 0,
  bool completed = false,
  bool optional = false,
}) {
  final h = buildTestHabit(
    id: id,
    name: name,
    amount: amount,
    amountCompleted: amountCompleted,
    amountLabel: 'times',
    trackingType: type,
    optional: optional,
    premadeHabitType: null,
  );
  h.categoryId = category;
  h.iconPath = emoji;
  h.completed = completed;
  h.trackingType = type; // the constructor infers one when given null
  return h;
}

Map<String, dynamic> _build({
  List<Habit>? today,
  List<Habit>? tomorrow,
  Map<DateTime, DayCompletionStatus>? statuses,
  int streak = 12,
  int tailMisses = 0,
  String locale = 'en',
  bool hasHabits = true,
  List<String> watchAcks = const [],
}) {
  final todayHabits = today ?? const <Habit>[];
  return WidgetSnapshotBuilder.build(
    WidgetSnapshotInput(
      now: _now,
      todayHabits: todayHabits,
      tomorrowHabits: tomorrow ?? const <Habit>[],
      statuses:
          statuses ??
          {
            for (int i = 1; i <= 6; i++)
              _today.subtract(Duration(days: i)): DayCompletionStatus.perfect,
            _today: classifyDayStatus(todayHabits),
          },
      dayProgress: const {},
      streak: streak,
      tailMisses: tailMisses,
      loc: lookupAppLocalizations(Locale(locale)),
      localeCode: locale,
      customSingulars: const {},
      formatTime: (m) => '${m ~/ 60}:${(m % 60).toString().padLeft(2, '0')}',
      theme: ThemeCatalog.habitt,
      hasHabits: hasHabits,
      watchAcks: watchAcks,
    ),
  );
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en');
    await initializeDateFormatting('bs');
  });

  group('today block', () {
    test('counts required habits, lists optional ones, keeps app order', () {
      final snap = _build(
        today: [
          _habit(1, 'Brush teeth', completed: true, amountCompleted: 1),
          _habit(2, 'Shower', amount: 10, amountCompleted: 8),
          _habit(3, 'Stretch', optional: true),
        ],
      );
      final today = snap['today'] as Map<String, dynamic>;
      expect(today['done'], 1);
      expect(today['total'], 2);
      expect(today['perfect'], false);
      expect(today['ring'], [1, 2]);
      final habits = today['habits'] as List;
      expect(habits.map((h) => h['id']), [1, 2, 3]);
      expect(habits[0]['state'], 'done');
      expect(habits[1]['state'], 'partial');
      expect(habits[1]['progress'], 0.8);
      expect(habits[1]['progressText'], '8 / 10 times');
      expect(habits[2]['optional'], true);
    });

    test('an undone optional habit does not stop a perfect day', () {
      final snap = _build(
        today: [
          _habit(1, 'Brush teeth', completed: true, amountCompleted: 1),
          _habit(2, 'Stretch', optional: true),
        ],
      );
      final today = snap['today'] as Map<String, dynamic>;
      expect(today['perfect'], true);
      expect((today['upNext'] as Map).values, everyElement(isNull));
    });

    test(
      'a habit with no tracking type has no progress text and cannot log',
      () {
        final snap = _build(today: [_habit(1, 'Meditate', type: null)]);
        final row = (snap['today']['habits'] as List).single;
        expect(row['progressText'], '');
        expect(row['canLog'], false);
        expect(row['state'], 'todo');
      },
    );
  });

  group('progress matches the habit card', () {
    test('duration habit', () {
      final h = buildTestHabit(
        id: 1,
        name: 'Shower',
        trackingType: HabitTrackingType.duration,
        amount: 0,
        duration: 600,
        durationCompleted: 480,
        premadeHabitType: null,
      );
      final row = (_build(today: [h])['today']['habits'] as List).single;
      expect(row['progress'], 0.8);
      expect(row['progressText'], '8m / 10m');
      expect(row['state'], 'partial');
    });

    test('time-of-day habit shows the target until something is logged', () {
      final h = buildTestHabit(
        id: 1,
        name: 'Go to bed early',
        trackingType: HabitTrackingType.timeOfDay,
        amount: 22 * 60 + 30,
        premadeHabitType: null,
      );
      final row = (_build(today: [h])['today']['habits'] as List).single;
      expect(row['progress'], 0.0);
      expect(row['progressText'], '22:30');
      expect(row['state'], 'todo');
    });
  });

  group('up next', () {
    test('shows the current part, then Any time, then later parts', () {
      final snap = _build(
        today: [
          _habit(1, 'Brush teeth', category: 2, completed: true),
          _habit(2, 'Water', category: 1),
          _habit(3, 'Read', category: 4),
        ],
      );
      final upNext = snap['today']['upNext'] as Map;
      // morning has nothing left, so Any time comes next
      expect(upNext['morning']['label'], 'Any time');
      expect(upNext['morning']['habits'], [2]);
      expect(upNext['evening']['label'], 'Evening');
      expect(upNext['evening']['habits'], [3]);
    });

    test('keeps at most three rows, dropping done habits first', () {
      final snap = _build(
        today: [
          _habit(1, 'A', completed: true),
          _habit(2, 'B'),
          _habit(3, 'C', completed: true),
          _habit(4, 'D'),
          _habit(5, 'E'),
        ],
      );
      final morning = snap['today']['upNext']['morning'];
      expect(morning['label'], 'Morning');
      expect(morning['habits'], [2, 4, 5]);
    });

    test('a short section keeps its done habits for context', () {
      final snap = _build(
        today: [
          _habit(1, 'Brush teeth', completed: true),
          _habit(2, 'Shower', amount: 10, amountCompleted: 8),
        ],
      );
      expect(snap['today']['upNext']['morning']['habits'], [1, 2]);
    });
  });

  group('streak', () {
    test('today counts once it is perfect, like the streak card', () {
      final snap = _build(
        today: [_habit(1, 'A', completed: true, amountCompleted: 1)],
        streak: 12,
      );
      final streak = snap['today']['streak'];
      expect(streak['count'], 13);
      expect(streak['perfectToday'], true);
      expect(streak['health'], 'healthy');
      expect((streak['week'] as List).last['s'], 'perfect');
    });

    test('a first perfect day starts the streak instead of inviting one', () {
      final snap = _build(
        today: [_habit(1, 'A', completed: true, amountCompleted: 1)],
        streak: 0,
      );
      final streak = snap['today']['streak'];
      expect(streak['count'], 1);
      expect(streak['perfectToday'], true);
      expect(streak['health'], 'healthy');
      expect(
        streak['line'],
        isNot(lookupAppLocalizations(const Locale('en')).widgetStartStreak),
      );
    });

    test('tail misses make the streak fade, then critical', () {
      final fading = _build(today: [_habit(1, 'A')], tailMisses: 1);
      expect(fading['today']['streak']['health'], 'fading');
      final critical = _build(today: [_habit(1, 'A')], tailMisses: 2);
      expect(critical['today']['streak']['health'], 'critical');
    });

    test('a dormant streak invites the user to start one', () {
      final snap = _build(today: [_habit(1, 'A')], streak: 0);
      final streak = snap['today']['streak'];
      expect(streak['health'], 'dormant');
      expect(
        streak['line'],
        lookupAppLocalizations(const Locale('en')).widgetStartStreak,
      );
    });

    test('the week row ends today and marks each past day', () {
      final snap = _build(
        today: [_habit(1, 'A')],
        statuses: {
          _today.subtract(const Duration(days: 6)): DayCompletionStatus.perfect,
          _today.subtract(const Duration(days: 5)): DayCompletionStatus.partial,
          _today.subtract(const Duration(days: 4)): DayCompletionStatus.perfect,
          _today.subtract(const Duration(days: 3)): DayCompletionStatus.miss,
          _today.subtract(const Duration(days: 2)): DayCompletionStatus.perfect,
          _today.subtract(const Duration(days: 1)): DayCompletionStatus.perfect,
          _today: DayCompletionStatus.miss,
        },
      );
      final week = snap['today']['streak']['week'] as List;
      expect(week.map((d) => d['s']), [
        'perfect',
        'partial',
        'perfect',
        'miss',
        'perfect',
        'perfect',
        'today',
      ]);
      expect(week.last['label'], 'T'); // Tuesday
    });
  });

  group('tomorrow block', () {
    test('a perfect today carries into tomorrow\'s streak', () {
      final snap = _build(
        today: [_habit(1, 'A', completed: true, amountCompleted: 1)],
        tomorrow: [_habit(1, 'A')],
      );
      final tomorrow = snap['tomorrow'];
      // six perfect past days plus a perfect today
      expect(tomorrow['streak']['count'], 7);
      expect(tomorrow['streak']['health'], 'healthy');
      expect(tomorrow['done'], 0);
      expect(tomorrow['total'], 1);
      expect(snap['nextDayStartsAt'], DateTime(2026, 11, 25).toIso8601String());
    });

    test('a missed today makes tomorrow\'s streak fade', () {
      final snap = _build(today: [_habit(1, 'A')], tomorrow: [_habit(1, 'A')]);
      expect(snap['tomorrow']['streak']['count'], 6);
      expect(snap['tomorrow']['streak']['health'], 'fading');
    });

    test('a third miss in a row ends the streak', () {
      final snap = _build(
        today: [_habit(1, 'A')],
        statuses: {
          _today.subtract(const Duration(days: 3)): DayCompletionStatus.perfect,
          _today.subtract(const Duration(days: 2)): DayCompletionStatus.miss,
          _today.subtract(const Duration(days: 1)): DayCompletionStatus.miss,
          _today: DayCompletionStatus.miss,
        },
      );
      expect(snap['tomorrow']['streak']['health'], 'dormant');
    });
  });

  group('theme and language', () {
    test('accent follows the selected theme', () {
      Map<String, dynamic> withTheme(String id) => WidgetSnapshotBuilder.build(
        WidgetSnapshotInput(
          now: _now,
          todayHabits: const [],
          tomorrowHabits: const [],
          statuses: const {},
          dayProgress: const {},
          streak: 0,
          tailMisses: 0,
          loc: lookupAppLocalizations(const Locale('en')),
          localeCode: 'en',
          customSingulars: const {},
          formatTime: (m) => '$m',
          theme: ThemeCatalog.byId(id),
        ),
      );
      expect(withTheme('habitt')['theme']['light']['accent'], '#02D382');
      expect(withTheme('habitt')['theme']['dark']['accent'], '#11F29B');
      expect(withTheme('violet')['theme']['light']['accent'], '#955FD8');
    });

    test('strings follow the app language', () {
      final snap = _build(today: [_habit(1, 'A')], locale: 'bs');
      expect(snap['strings']['daysStreak'], 'dana streak');
      expect(snap['strings']['day'], 'dan');
      expect(snap['strings']['days'], 'dana');
      expect(snap['today']['upNext']['morning']['label'], 'Jutro');
      expect(snap['strings']['morning'], 'Jutro');
      expect(snap['strings']['today'], isNotEmpty);
      expect(snap['strings']['optional'], isNotEmpty);
      expect(snap['strings']['watchShowHabits'], 'Prikaži navike');
      expect(snap['strings']['watchOfTarget'], 'od %@');
      expect(
        snap['strings']['wearHealthNote'],
        'Ažurira se iz Health Connecta na telefonu',
      );
      expect(snap['strings']['wearLogOnPhone'], 'Ovo zabilježi na telefonu');
      expect(snap['strings']['wearUpdateNeededBody'], isNotEmpty);
    });

    test('streak labels are lower case, as on the home page card', () {
      final snap = _build(today: [_habit(1, 'A')]);
      expect(snap['strings']['dayStreak'], 'day streak');
      expect(snap['strings']['daysStreak'], 'days streak');
    });

    test('no habits at all is told apart from nothing today', () {
      final none = _build(hasHabits: false, streak: 0);
      expect(none['hasHabits'], isFalse);
      expect(none['strings']['noHabits'], 'You haven’t added any habits yet');
      expect(none['today']['total'], 0);
      expect(none['today']['streak']['count'], 0);
      expect(_build()['hasHabits'], isTrue);
    });

    test('the whole snapshot is plain JSON', () {
      final snap = _build(today: [_habit(1, 'A')], tomorrow: [_habit(1, 'A')]);
      expect(() => jsonEncode(snap), returnsNormally);
      expect(snap['v'], WidgetSnapshotBuilder.version);
      expect(snap['dayKey'], '2026-11-24');
    });
  });

  test('Up next leaves optional habits out', () {
    final snap = _build(
      today: [
        _habit(1, 'Required', category: 2),
        _habit(2, 'Optional', category: 2, optional: true),
        _habit(3, 'Only optional', category: 4, optional: true),
      ],
    );
    final upNext = snap['today']['upNext'] as Map<String, dynamic>;
    expect(upNext['morning']['habits'], [1]);
    // evening has only an optional habit: falls back to morning
    expect(upNext['evening']['habits'], [1]);
  });

  group('watch fields', () {
    Map<String, dynamic> row(Habit h) =>
        (_build(today: [h])['today']['habits'] as List).first
            as Map<String, dynamic>;

    test('amount habit carries target, value, unit and step', () {
      final r = row(_habit(1, 'Read', amount: 10, amountCompleted: 3));
      expect(r['completed'], isFalse);
      expect(r['log'], {
        'type': 'amount',
        'target': 10,
        'value': 3,
        'unit': 'times',
        'step': 1,
        'healthLinked': false,
        'watchLoggable': true,
      });
    });

    test("a lighter day's goal is the target", () {
      final h = _habit(1, 'Read', amount: 10, amountCompleted: 3)..dayGoal = 5;
      final r = row(h);
      expect(r['log']['target'], 5);
      expect(r['progressText'], contains('/ 5'));
    });

    test('duration habit is in seconds with a one minute step', () {
      final h = buildTestHabit(
        id: 2,
        name: 'Meditate',
        trackingType: HabitTrackingType.duration,
        duration: 600,
        durationCompleted: 240,
        premadeHabitType: null,
      )..trackingType = HabitTrackingType.duration;
      final log = row(h)['log'] as Map<String, dynamic>;
      expect(log['type'], 'duration');
      expect(log['target'], 600);
      expect(log['value'], 240);
      expect(log['step'], 60);
      expect(log['unit'], '');
      expect(log['watchLoggable'], isTrue);
    });

    test('time of day and no tracking type cannot be logged', () {
      final tod = row(_habit(1, 'Bedtime', type: HabitTrackingType.timeOfDay));
      expect(tod['log']['type'], 'timeOfDay');
      expect(tod['log']['watchLoggable'], isFalse);

      final plain = row(_habit(2, 'Make bed', type: null));
      expect(plain['log']['type'], isNull);
      expect(plain['log']['watchLoggable'], isFalse);
    });

    test('a Health-linked habit is read-only on the watch', () {
      final h = _habit(1, 'Steps', amount: 8000, amountCompleted: 6240)
        ..healthMetric = HealthMetricType.steps;
      final log = row(h)['log'] as Map<String, dynamic>;
      expect(log['healthLinked'], isTrue);
      expect(log['watchLoggable'], isFalse);
    });

    test('completed flag follows the habit', () {
      final r = row(_habit(1, 'A', completed: true, amountCompleted: 1));
      expect(r['completed'], isTrue);
      expect(r['state'], 'done');
    });

    test('watchAcks pass through, keeping the newest 50', () {
      expect(_build()['watchAcks'], isEmpty);
      expect(_build(watchAcks: ['a', 'b'])['watchAcks'], ['a', 'b']);
      final many = [for (int i = 0; i < 60; i++) 'id$i'];
      final acks = _build(watchAcks: many)['watchAcks'] as List;
      expect(acks.length, 50);
      expect(acks.first, 'id10');
      expect(acks.last, 'id59');
    });
  });
}
