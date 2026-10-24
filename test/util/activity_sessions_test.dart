import 'package:flutter_test/flutter_test.dart';
import 'package:habitt/models/health_session_detail.dart';
import 'package:habitt/util/activity_sessions.dart';

HealthSessionDetail _sample(int startMinute, int endMinute) =>
    HealthSessionDetail(
      start: DateTime(2026, 9, 14, 10, startMinute),
      end: DateTime(2026, 9, 14, 10, endMinute),
    );

// one-minute samples, like Apple Health's exercise time
List<HealthSessionDetail> _minutes(Iterable<int> startMinutes) => [
  for (final m in startMinutes) _sample(m, m + 1),
];

void main() {
  group('activeTimeCovered', () {
    test('sums back-to-back minute samples', () {
      final samples = _minutes(List.generate(23, (i) => i));

      expect(activeTimeCovered(samples), const Duration(minutes: 23));
    });

    test('counts overlapping samples from two sources once', () {
      final samples = [..._minutes([0, 1, 2]), ..._minutes([1, 2, 3])];

      expect(activeTimeCovered(samples), const Duration(minutes: 4));
    });

    test('does not count the gaps between samples', () {
      final samples = _minutes([0, 1, 10, 11]);

      expect(activeTimeCovered(samples), const Duration(minutes: 4));
    });

    test('is zero with no samples or empty ones', () {
      expect(activeTimeCovered(const []), Duration.zero);
      expect(activeTimeCovered([_sample(5, 5)]), Duration.zero);
    });

    test('does not depend on the order of the samples', () {
      final samples = _minutes([3, 0, 2, 1]);

      expect(activeTimeCovered(samples), const Duration(minutes: 4));
    });
  });

  group('groupActivityPeriods', () {
    test('folds 23 consecutive minutes into one period', () {
      final periods = groupActivityPeriods(
        _minutes(List.generate(23, (i) => i + 2)),
      );

      expect(periods, hasLength(1));
      expect(periods.single.start, DateTime(2026, 9, 14, 10, 2));
      expect(periods.single.end, DateTime(2026, 9, 14, 10, 25));
      expect(periods.single.duration, const Duration(minutes: 23));
    });

    test('joins samples a short gap apart', () {
      final periods = groupActivityPeriods(_minutes([0, 1, 3, 4]));

      expect(periods, hasLength(1));
      expect(periods.single.duration, const Duration(minutes: 5));
    });

    test('keeps stretches far apart separate', () {
      final periods = groupActivityPeriods(_minutes([0, 1, 2, 30, 31]));

      expect(periods, hasLength(2));
      expect(periods[0].end, DateTime(2026, 9, 14, 10, 3));
      expect(periods[1].start, DateTime(2026, 9, 14, 10, 30));
    });

    test('respects a custom gap', () {
      final samples = _minutes([0, 5]);

      expect(
        groupActivityPeriods(samples, maxGap: const Duration(minutes: 10)),
        hasLength(1),
      );
      expect(groupActivityPeriods(samples), hasLength(2));
    });

    test('is empty with no samples', () {
      expect(groupActivityPeriods(const []), isEmpty);
    });
  });
}
