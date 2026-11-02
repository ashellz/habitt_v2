import 'package:flutter_test/flutter_test.dart';
import 'package:habitt/util/date_key.dart';

void main() {
  group('addCalendarDays', () {
    test('moves by calendar days and drops the time of day', () {
      expect(
        addCalendarDays(DateTime(2026, 10, 24, 18, 45), 3),
        DateTime(2026, 10, 27),
      );
      expect(addCalendarDays(DateTime(2026, 3, 1), -1), DateTime(2026, 2, 28));
      expect(addCalendarDays(DateTime(2026, 12, 31), 1), DateTime(2027, 1, 1));
    });

    // In a DST zone (e.g. TZ=Europe/Sarajevo) these are exactly the cases a
    // 24 h Duration gets wrong; in UTC they still pin the expected dates.
    test('crosses the autumn fall-back day', () {
      final start = DateTime(2026, 10, 24);
      expect(addCalendarDays(start, 1), DateTime(2026, 10, 25));
      expect(addCalendarDays(start, 2), DateTime(2026, 10, 26));
      expect(dateKey(addCalendarDays(start, 2)), '2026-10-26');
      expect(
        addCalendarDays(DateTime(2026, 10, 26), -1),
        DateTime(2026, 10, 25),
      );
    });

    test('crosses the spring-forward day', () {
      final start = DateTime(2027, 3, 29);
      expect(addCalendarDays(start, -1), DateTime(2027, 3, 28));
      expect(addCalendarDays(start, -2), DateTime(2027, 3, 27));
      expect(addCalendarDays(DateTime(2027, 3, 27), 2), DateTime(2027, 3, 29));
    });
  });

  group('calendarDaysBetween', () {
    test('counts calendar days across both DST transitions', () {
      expect(
        calendarDaysBetween(DateTime(2026, 10, 24), DateTime(2026, 10, 26)),
        2,
      );
      expect(
        calendarDaysBetween(DateTime(2027, 3, 27), DateTime(2027, 3, 29)),
        2,
      );
      expect(
        calendarDaysBetween(DateTime(2027, 1, 1), DateTime(2027, 4, 1)),
        90,
      );
    });

    test('ignores time of day and is negative backwards', () {
      expect(
        calendarDaysBetween(
          DateTime(2026, 10, 24, 23, 59),
          DateTime(2026, 10, 25, 0, 1),
        ),
        1,
      );
      expect(
        calendarDaysBetween(DateTime(2026, 10, 26), DateTime(2026, 10, 24)),
        -2,
      );
    });
  });
}
