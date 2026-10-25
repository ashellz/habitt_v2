import 'package:flutter_test/flutter_test.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/util/build_plan_sections.dart';

import '../fixtures/habit_factory.dart';

int _m(int hour, [int minute = 0]) => hour * 60 + minute;

Habit _timed(
  int id, {
  required int start,
  required int end,
  int categoryId = 1,
  int order = 0,
  bool enabled = true,
}) {
  return buildTestHabit(id: id)
    ..timeIntervalEnabled = enabled
    ..timeIntervalStart = start
    ..timeIntervalEnd = end
    ..categoryId = categoryId
    ..order = order;
}

List<List<int>> _ids(List<PlanSection> sections) =>
    sections.map((s) => s.entries.map((e) => e.habit.id).toList()).toList();

List<int> _titles(List<PlanSection> sections) =>
    sections.map((s) => s.start).toList();

void main() {
  test('skips habits without a time interval', () {
    final sections = buildPlanSections(
      habits: [
        _timed(1, start: _m(8), end: _m(9), enabled: false),
        _timed(2, start: _m(10), end: _m(11)),
      ],
    );

    expect(_ids(sections), [
      [2],
    ]);
  });

  test('back-to-back habits get their own sections', () {
    final sections = buildPlanSections(
      habits: [
        _timed(2, start: _m(7, 30), end: _m(8)),
        _timed(1, start: _m(7), end: _m(7, 30)),
      ],
    );

    expect(_titles(sections), [_m(7), _m(7, 30)]);
    expect(_ids(sections), [
      [1],
      [2],
    ]);
  });

  test('a long habit shares its section and later habits split off', () {
    final sections = buildPlanSections(
      habits: [
        _timed(1, start: _m(8), end: _m(20)), // water
        _timed(2, start: _m(9), end: _m(9, 30)), // read
        _timed(3, start: _m(18), end: _m(19)), // gym
      ],
    );

    expect(_titles(sections), [_m(8), _m(18)]);
    expect(_ids(sections), [
      [1, 2],
      [3],
    ]);
  });

  test('same start orders the sooner end first', () {
    final sections = buildPlanSections(
      habits: [
        _timed(1, start: _m(9), end: _m(11)),
        _timed(2, start: _m(9), end: _m(10)),
      ],
    );

    expect(_ids(sections), [
      [2, 1],
    ]);
  });

  test('identical times fall back to category order, then order', () {
    final sections = buildPlanSections(
      habits: [
        _timed(1, start: _m(9), end: _m(10), categoryId: 3, order: 1),
        _timed(2, start: _m(9), end: _m(10), categoryId: 2, order: 2),
        _timed(3, start: _m(9), end: _m(10), categoryId: 2, order: 1),
      ],
      categoryRank: {2: 0, 3: 1},
    );

    expect(_ids(sections), [
      [3, 2, 1],
    ]);
  });

  test('a zero-length habit does not create a duplicate title', () {
    final sections = buildPlanSections(
      habits: [
        _timed(1, start: _m(9), end: _m(9)),
        _timed(2, start: _m(9), end: _m(10)),
      ],
    );

    expect(_titles(sections), [_m(9)]);
  });

  test('an end of 00:00 runs until midnight', () {
    final sections = buildPlanSections(
      habits: [
        _timed(1, start: _m(22), end: 0),
        _timed(2, start: _m(23), end: _m(23, 30)),
      ],
      nowMinutes: _m(23, 45),
    );

    expect(_ids(sections), [
      [1, 2],
    ]);
    expect(sections.single.entries.first.end, _m(24));
    expect(sections.single.entries.first.isCurrent, isTrue);
    expect(sections.single.entries.last.isCurrent, isFalse);
  });

  group('habits crossing midnight', () {
    Habit night() => _timed(1, start: _m(22), end: _m(2));

    test('show under their start before they begin', () {
      final sections = buildPlanSections(
        habits: [night()],
        nowMinutes: _m(21),
        scheduledYesterdayIds: {1},
      );

      expect(_titles(sections), [_m(22)]);
      expect(sections.single.entries.single.isCurrent, isFalse);
    });

    test('show under 00:00 while last night\'s run is going', () {
      final sections = buildPlanSections(
        habits: [night(), _timed(2, start: _m(8), end: _m(9))],
        nowMinutes: _m(1),
        scheduledYesterdayIds: {1},
      );

      expect(_titles(sections), [0, _m(8)]);
      expect(sections.first.entries.single.isCurrent, isTrue);
    });

    test('ignore last night when not scheduled yesterday', () {
      final sections = buildPlanSections(habits: [night()], nowMinutes: _m(1));

      expect(_titles(sections), [_m(22)]);
      expect(sections.single.entries.single.isCurrent, isFalse);
    });

    test('move back to their start once last night\'s run ends', () {
      final sections = buildPlanSections(
        habits: [night()],
        nowMinutes: _m(3),
        scheduledYesterdayIds: {1},
      );

      expect(_titles(sections), [_m(22)]);
    });

    test('are current after they start', () {
      final sections = buildPlanSections(habits: [night()], nowMinutes: _m(23));

      expect(sections.single.entries.single.isCurrent, isTrue);
    });
  });

  test('no highlight when the day is not today', () {
    final sections = buildPlanSections(
      habits: [_timed(1, start: 0, end: _m(23, 59))],
    );

    expect(sections.single.entries.single.isCurrent, isFalse);
  });

  test('highlights every habit whose interval contains now', () {
    final sections = buildPlanSections(
      habits: [
        _timed(1, start: _m(8), end: _m(20)),
        _timed(2, start: _m(9), end: _m(9, 30)),
        _timed(3, start: _m(18), end: _m(19)),
      ],
      nowMinutes: _m(9, 15),
    );

    final current = [
      for (final s in sections)
        for (final e in s.entries)
          if (e.isCurrent) e.habit.id,
    ];
    expect(current, [1, 2]);
  });
}
