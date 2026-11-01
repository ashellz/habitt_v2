import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:habitt/hive/hive_adapters.dart';
import 'package:habitt/hive/hive_registrar.g.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/models/schedule_type.dart';
import 'package:habitt/util/custom_appearance.dart';
import 'package:habitt/util/date_key.dart';
import 'package:hive_ce/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Day count between two yyyy-MM-dd keys, in UTC so the test's own arithmetic
// can't be skewed by DST.
int _daysBetween(String a, String b) =>
    DateTime.parse(
      '${b}T00:00:00Z',
    ).difference(DateTime.parse('${a}T00:00:00Z')).inDays;

List<int> _gaps(List<String> keys) => [
  for (var i = 1; i < keys.length; i++) _daysBetween(keys[i - 1], keys[i]),
];

// Europe/Sarajevo clock changes around the test range.
final _fallBackDays = {DateTime(2025, 10, 26), DateTime(2026, 10, 25)};
final _springForwardDays = {DateTime(2026, 3, 29), DateTime(2027, 3, 28)};

int _sarajevoDayHours(DateTime day) {
  final d = DateTime(day.year, day.month, day.day);
  if (_fallBackDays.contains(d)) return 25;
  if (_springForwardDays.contains(d)) return 23;
  return 24;
}

/// What the old `anchor.add(Duration(days: i))` builders stored when run in
/// Europe/Sarajevo: after a fall-back the wall clock sits an hour behind
/// midnight (23:00 of the previous day) until a spring-forward cancels it.
List<String> _oldBuggyBuilder(DateTime anchor, int interval, int span) {
  final output = <String>[];
  for (var i = 0; i < span; i += interval) {
    final trueDay = DateTime(anchor.year, anchor.month, anchor.day + i);
    var hourOffset = 0;
    for (final f in _fallBackDays) {
      if (!f.isBefore(anchor) && f.isBefore(trueDay)) hourOffset -= 1;
    }
    for (final s in _springForwardDays) {
      if (!s.isBefore(anchor) && s.isBefore(trueDay)) hourOffset += 1;
    }
    final stored =
        hourOffset < 0
            ? DateTime(trueDay.year, trueDay.month, trueDay.day - 1)
            : trueDay;
    output.add(dateKey(stored));
  }
  return output;
}

void main() {
  final localZoneHasFallBack = localDayHours(DateTime(2026, 10, 25)) == 25;
  const dstSkipReason =
      'Local time zone has no DST fall-back on 2026-10-25; run with '
      'TZ=Europe/Sarajevo to exercise the real DST path.';

  group('buildCustomAppearance', () {
    test('every 3 days stays evenly spaced across the October fall-back', () {
      final keys = buildCustomAppearance(
        anchor: DateTime(2026, 10, 1),
        intervalDays: 3,
      );

      expect(keys.first, '2026-10-01');
      expect(keys, containsAll(['2026-10-25', '2026-10-28', '2026-10-31']));
      expect(keys, isNot(contains('2026-10-27')));
      expect(_gaps(keys), everyElement(3));
    });

    test('every day has no duplicates or holes across both transitions', () {
      final keys = buildCustomAppearance(
        anchor: DateTime(2026, 10, 1),
        intervalDays: 1,
      );

      expect(keys, hasLength(365));
      expect(keys.toSet(), hasLength(365));
      expect(keys, containsAll(['2026-10-25', '2026-10-26', '2027-03-28']));
      expect(_gaps(keys), everyElement(1));
      expect(keys.last, '2027-09-30');
    });

    test('works from an anchor that is not midnight', () {
      final keys = buildCustomAppearance(
        anchor: DateTime(2026, 10, 20, 23, 30),
        intervalDays: 4,
        spanDays: 30,
      );
      expect(keys, [
        '2026-10-20',
        '2026-10-24',
        '2026-10-28',
        '2026-11-01',
        '2026-11-05',
        '2026-11-09',
        '2026-11-13',
        '2026-11-17',
      ]);
    });

    test('clamps a zero interval instead of looping forever', () {
      final keys = buildCustomAppearance(
        anchor: DateTime(2026, 10, 1),
        intervalDays: 0,
        spanDays: 3,
      );
      expect(keys, ['2026-10-01', '2026-10-02', '2026-10-03']);
    });

    test('buildCustomAppearanceFromToday starts today', () {
      final keys = buildCustomAppearanceFromToday(5);
      expect(keys.first, dateKey(DateTime.now()));
      expect(keys, hasLength((kNewCustomAppearanceSpanDays / 5).ceil()));
      expect(_gaps(keys), everyElement(5));
    });

    test('Duration arithmetic really shifts keys in this zone (bug guard)', () {
      // Documents the bug the builders avoid: 27 * 24 h after midnight on
      // 1 Oct is 23:00 on 27 Oct in a zone with a 25 h 25 Oct.
      final viaDuration = DateTime(2026, 10, 1).add(const Duration(days: 27));
      expect(dateKey(viaDuration), '2026-10-27');
      expect(
        buildCustomAppearance(
          anchor: DateTime(2026, 10, 1),
          intervalDays: 27,
          spanDays: 28,
        ).last,
        '2026-10-28',
      );
    }, skip: localZoneHasFallBack ? false : dstSkipReason);
  });

  group('extendCustomAppearance', () {
    test('continues the grid from the last stored date', () {
      final stored = buildCustomAppearance(
        anchor: DateTime(2026, 4, 1),
        intervalDays: 3,
        spanDays: 180,
      );
      final extended = extendCustomAppearance(
        dates: stored,
        intervalDays: 3,
        through: DateTime(2026, 11, 1),
        // an off-grid anchor that must not be used when a list exists
        fallbackAnchor: DateTime(2026, 9, 1),
        keepFrom: DateTime(2026, 1, 1),
      );

      expect(extended.take(stored.length), stored);
      expect(_gaps(extended), everyElement(3));
      expect(extended.last.compareTo('2027-11-01') < 0, isTrue);
      expect(extended.last.compareTo('2027-10-29') >= 0, isTrue);
      final grid = buildCustomAppearance(
        anchor: DateTime(2026, 4, 1),
        intervalDays: 3,
        spanDays: 1000,
      );
      expect(grid, containsAll(extended));
    });

    test('drops dates before keepFrom', () {
      final stored = buildCustomAppearance(
        anchor: DateTime(2026, 1, 1),
        intervalDays: 2,
        spanDays: 100,
      );
      final extended = extendCustomAppearance(
        dates: stored,
        intervalDays: 2,
        through: DateTime(2026, 6, 1),
        fallbackAnchor: DateTime(2026, 1, 1),
        keepFrom: DateTime(2026, 3, 1),
      );
      expect(extended.first, '2026-03-02');
      expect(_gaps(extended), everyElement(2));
    });

    test('with no list it starts a fresh grid at the fallback anchor', () {
      final extended = extendCustomAppearance(
        dates: const [],
        intervalDays: 4,
        through: DateTime(2026, 10, 30),
        fallbackAnchor: DateTime(2026, 10, 20, 22, 15),
        keepFrom: DateTime(2026, 1, 1),
      );
      expect(extended.take(3), ['2026-10-20', '2026-10-24', '2026-10-28']);
      expect(_gaps(extended), everyElement(4));
    });
  });

  group('repairDstShiftedCustomAppearance', () {
    test('re-spaces future dates of the issue example, keeps the past', () {
      final anchor = DateTime(2026, 10, 1);
      final buggy = _oldBuggyBuilder(anchor, 3, 365);
      expect(buggy, contains('2026-10-27')); // sanity: fixture has the bug
      final correct = buildCustomAppearance(anchor: anchor, intervalDays: 3);

      final repaired = repairDstShiftedCustomAppearance(
        dates: buggy,
        intervalDays: 3,
        today: DateTime(2026, 11, 1),
        dayHours: _sarajevoDayHours,
      );

      expect(repaired, isNotNull);
      final past = repaired!.where((d) => d.compareTo('2026-11-01') < 0);
      final future = repaired.where((d) => d.compareTo('2026-11-01') >= 0);
      expect(
        past,
        buggy.where((d) => d.compareTo('2026-11-01') < 0),
        reason: 'past dates are left as stored',
      );
      expect(
        future,
        correct.where((d) => d.compareTo('2026-11-01') >= 0),
        reason: 'future dates are back on the 3-day grid',
      );
      expect(future.first, '2026-11-03');
      expect(_gaps(future.toList()), everyElement(3));
    });

    test('a date shifted to yesterday comes back as today', () {
      final anchor = DateTime(2026, 10, 1);
      final buggy = _oldBuggyBuilder(anchor, 3, 365);
      // true grid has 2026-10-31, stored as 2026-10-30
      expect(buggy, contains('2026-10-30'));

      final repaired =
          repairDstShiftedCustomAppearance(
            dates: buggy,
            intervalDays: 3,
            today: DateTime(2026, 10, 31),
            dayHours: _sarajevoDayHours,
          )!;

      expect(repaired, containsAll(['2026-10-30', '2026-10-31', '2026-11-03']));
      expect(repaired, isNot(contains('2026-11-02')));
    });

    test('every-day habit gets back the day lost at spring-forward', () {
      final anchor = DateTime(2026, 10, 1);
      final buggy = _oldBuggyBuilder(anchor, 1, 365);
      expect(buggy, isNot(contains('2027-03-28'))); // sanity

      final repaired =
          repairDstShiftedCustomAppearance(
            dates: buggy,
            intervalDays: 1,
            today: DateTime(2026, 11, 1),
            dayHours: _sarajevoDayHours,
          )!;

      final future =
          repaired.where((d) => d.compareTo('2026-11-01') >= 0).toList();
      expect(future.first, '2026-11-01');
      expect(future.last, '2027-09-30');
      expect(_gaps(future), everyElement(1));
    });

    test('grid crossing two autumns is repaired after each', () {
      final anchor = DateTime(2025, 10, 1);
      // span long enough to reach the second autumn
      final buggy = _oldBuggyBuilder(anchor, 5, 400);
      final correct = buildCustomAppearance(
        anchor: anchor,
        intervalDays: 5,
        spanDays: 400,
      );

      final repaired =
          repairDstShiftedCustomAppearance(
            dates: buggy,
            intervalDays: 5,
            today: DateTime(2025, 10, 2),
            dayHours: _sarajevoDayHours,
          )!;

      expect(repaired, correct);
    });

    test('an evenly spaced list is left alone', () {
      final keys = buildCustomAppearance(
        anchor: DateTime(2026, 10, 1),
        intervalDays: 3,
      );
      expect(
        repairDstShiftedCustomAppearance(
          dates: keys,
          intervalDays: 3,
          today: DateTime(2026, 11, 1),
          dayHours: _sarajevoDayHours,
        ),
        isNull,
      );
    });

    test('an N-1 gap away from a fall-back day is not treated as the bug', () {
      // e.g. a late completion two days after a missed "every 3 days" date
      // restarted the grid in mid-November
      final keys = [
        '2026-11-02',
        '2026-11-05',
        '2026-11-07',
        '2026-11-10',
        '2026-11-13',
      ];
      expect(
        repairDstShiftedCustomAppearance(
          dates: keys,
          intervalDays: 3,
          today: DateTime(2026, 11, 1),
          dayHours: _sarajevoDayHours,
        ),
        isNull,
      );
    });

    test('grid restarted by a late completion after the shift is kept', () {
      final anchor = DateTime(2026, 10, 1);
      final buggy = _oldBuggyBuilder(anchor, 3, 365);
      // late completion on 4 Nov keeps the old dates before it and restarts
      // the (correct, calendar-built) grid from that day
      final restarted = [
        ...buggy.where((d) => d.compareTo('2026-11-04') < 0),
        ...buildCustomAppearance(
          anchor: DateTime(2026, 11, 4),
          intervalDays: 3,
        ),
      ];

      expect(
        repairDstShiftedCustomAppearance(
          dates: restarted,
          intervalDays: 3,
          today: DateTime(2026, 11, 10),
          dayHours: _sarajevoDayHours,
        ),
        isNull,
      );
    });

    test('unparseable data is left alone', () {
      expect(
        repairDstShiftedCustomAppearance(
          dates: ['2026-10-22', 'garbage', '2026-10-27'],
          intervalDays: 3,
          today: DateTime(2026, 10, 1),
          dayHours: _sarajevoDayHours,
        ),
        isNull,
      );
    });

    test('detects the real fall-back day of the local zone', () {
      final anchor = DateTime(2026, 10, 1);
      final buggy = [
        for (var i = 0; i < 365; i += 3) dateKey(anchor.add(Duration(days: i))),
      ];
      expect(buggy, contains('2026-10-27'));
      final repaired =
          repairDstShiftedCustomAppearance(
            dates: buggy,
            intervalDays: 3,
            today: DateTime(2026, 11, 1),
          )!;
      final future =
          repaired.where((d) => d.compareTo('2026-11-01') >= 0).toList();
      expect(future.first, '2026-11-03');
      expect(_gaps(future), everyElement(3));
    }, skip: localZoneHasFallBack ? false : dstSkipReason);
  });

  group('migrateDstShiftedCustomAppearance', () {
    late Directory tempDir;
    late Box<Habit> habitBox;

    setUpAll(() async {
      tempDir = await Directory.systemTemp.createTemp('custom_appearance_dst');
      Hive.init(tempDir.path);
      Hive.registerAdapters();
      Hive.registerAdapter(ScheduleTypeAdapter());
      Hive.registerAdapter(PremadeHabitTypeAdapter());
      Hive.registerAdapter(HabitTrackingTypeAdapter());
      Hive.registerAdapter(HabitNotificationTimeAdapter());
      Hive.registerAdapter(LegacyHabitTrackingTypeAdapter());
      habitBox = await Hive.openBox<Habit>('habits');
    });

    setUp(() async {
      await habitBox.clear();
      SharedPreferences.setMockInitialValues({});
    });

    tearDownAll(() async {
      await Hive.close();
      await tempDir.delete(recursive: true);
    });

    Habit habit(int id, ScheduleType type, List<String> appearance) => Habit(
      id: id,
      name: 'habit $id',
      iconPath: '',
      categoryId: 0,
      scheduleType: type,
      customIntervalDays: 3,
      customAppearance: appearance,
    );

    test('repairs custom habits once and sets the flag', () async {
      final buggy = _oldBuggyBuilder(DateTime(2026, 10, 1), 3, 365);
      await habitBox.put(1, habit(1, ScheduleType.custom, buggy));
      await habitBox.put(2, habit(2, ScheduleType.daily, buggy));
      final prefs = await SharedPreferences.getInstance();

      await migrateDstShiftedCustomAppearance(
        habitBox: habitBox,
        prefs: prefs,
        today: DateTime(2026, 11, 1),
        dayHours: _sarajevoDayHours,
      );

      final custom = habitBox.get(1)!;
      final future =
          custom.customAppearance
              .where((d) => d.compareTo('2026-11-01') >= 0)
              .toList();
      expect(future.first, '2026-11-03');
      expect(_gaps(future), everyElement(3));
      expect(custom.timestamps['customAppearance'], isNotNull);

      // non-custom habits keep whatever stale list they had
      expect(habitBox.get(2)!.customAppearance, buggy);
      expect(prefs.getBool(customAppearanceDstRepairedKey), isTrue);

      // second run is a no-op
      await habitBox.put(3, habit(3, ScheduleType.custom, buggy));
      await migrateDstShiftedCustomAppearance(
        habitBox: habitBox,
        prefs: prefs,
        today: DateTime(2026, 11, 1),
        dayHours: _sarajevoDayHours,
      );
      expect(habitBox.get(3)!.customAppearance, buggy);
    });
  });
}
