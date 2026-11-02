import 'package:flutter_test/flutter_test.dart';
import 'package:habitt/util/health_sync_range.dart';

void main() {
  final today = DateTime(2026, 11, 1);
  DateTime ago(int days) => DateTime(today.year, today.month, today.day - days);

  group('healthCatchUpDays', () {
    test('no cursor (just linked) reads only the sync day', () {
      expect(healthCatchUpDays(syncDay: today), [today]);
    });

    test('cursor on the sync day reads only the sync day again', () {
      expect(healthCatchUpDays(syncDay: today, cursor: today), [today]);
    });

    test('cursor yesterday: sync day first, then yesterday is read once more', () {
      expect(healthCatchUpDays(syncDay: today, cursor: ago(1)), [
        today,
        ago(1),
      ]);
    });

    test('missed days come after the sync day, oldest to newest', () {
      expect(healthCatchUpDays(syncDay: today, cursor: ago(3)), [
        today,
        ago(3),
        ago(2),
        ago(1),
      ]);
    });

    test('is cut to the cap before the sync day', () {
      final days = healthCatchUpDays(syncDay: today, cursor: ago(40));
      expect(days.first, today);
      // today plus kHealthBackfillMaxDays earlier days
      expect(days, hasLength(kHealthBackfillMaxDays + 1));
      expect(days[1], ago(kHealthBackfillMaxDays));
      expect(days.last, ago(1));
    });

    test('a custom cap is respected', () {
      final days = healthCatchUpDays(
        syncDay: today,
        cursor: ago(40),
        maxDays: 3,
      );
      expect(days, [today, ago(3), ago(2), ago(1)]);
    });

    test('never goes before the floor', () {
      final days = healthCatchUpDays(
        syncDay: today,
        cursor: ago(10),
        floor: ago(2),
      );
      expect(days, [today, ago(2), ago(1)]);
    });

    test('a floor on the sync day leaves just the sync day', () {
      expect(
        healthCatchUpDays(syncDay: today, cursor: ago(5), floor: today),
        [today],
      );
    });

    test('cursor after the sync day (bedtime switched to day before) reads only it', () {
      expect(healthCatchUpDays(syncDay: ago(1), cursor: today), [ago(1)]);
    });

    test('times of day are ignored', () {
      final days = healthCatchUpDays(
        syncDay: today.add(const Duration(hours: 15)),
        cursor: ago(1).add(const Duration(hours: 22)),
      );
      expect(days, [today, ago(1)]);
    });

    test('crosses month and year ends', () {
      final days = healthCatchUpDays(
        syncDay: DateTime(2027, 1, 2),
        cursor: DateTime(2026, 12, 30),
      );
      expect(days, [
        DateTime(2027, 1, 2),
        DateTime(2026, 12, 30),
        DateTime(2026, 12, 31),
        DateTime(2027, 1, 1),
      ]);
    });
  });

  group('healthBackfillFloor', () {
    test('is the creation day when never paused', () {
      final created = DateTime(2026, 10, 20, 14, 30);
      expect(
        healthBackfillFloor(createdAt: created.toUtc()),
        DateTime(2026, 10, 20),
      );
    });

    test('a pause change after creation moves the floor to that day', () {
      expect(
        healthBackfillFloor(
          createdAt: DateTime(2026, 10, 1),
          pauseChangedAt: DateTime(2026, 10, 28, 9),
        ),
        DateTime(2026, 10, 28),
      );
    });

    test('an old pause change does not move the floor back', () {
      expect(
        healthBackfillFloor(
          createdAt: DateTime(2026, 10, 20),
          pauseChangedAt: DateTime(2026, 10, 5),
        ),
        DateTime(2026, 10, 20),
      );
    });
  });
}
