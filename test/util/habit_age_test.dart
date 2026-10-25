import 'package:flutter_test/flutter_test.dart';
import 'package:habitt/l10n/app_localizations_en.dart';
import 'package:habitt/util/habit_age.dart';

void main() {
  HabitAge age(DateTime start, DateTime today) => habitAge(start, today);

  test('started today is new', () {
    final a = age(DateTime(2026, 3, 10, 22, 30), DateTime(2026, 3, 10, 8));
    expect(a.isNew, isTrue);
    expect(a.days, 0);
  });

  test('a start date in the future counts as new', () {
    expect(age(DateTime(2026, 3, 12), DateTime(2026, 3, 10)).isNew, isTrue);
  });

  test('counts total days for young habits', () {
    final a = age(DateTime(2026, 3, 1), DateTime(2026, 3, 9));
    expect(a.days, 8);
    expect(a.months, 0);
    expect(a.years, 0);
  });

  test('a month is only complete once the day of month is reached', () {
    expect(age(DateTime(2026, 1, 15), DateTime(2026, 2, 14)).months, 0);
    expect(age(DateTime(2026, 1, 15), DateTime(2026, 2, 15)).months, 1);
  });

  test('splits into years and remaining months', () {
    final a = age(DateTime(2024, 1, 20), DateTime(2026, 4, 20));
    expect(a.years, 2);
    expect(a.months, 3);
  });

  test('exactly one year', () {
    final a = age(DateTime(2025, 6, 1), DateTime(2026, 6, 1));
    expect(a.years, 1);
    expect(a.months, 0);
  });

  test('extraDays is what is left after years and months', () {
    final a = age(DateTime(2024, 1, 20), DateTime(2026, 4, 25));
    expect(a.years, 2);
    expect(a.months, 3);
    expect(a.extraDays, 5);
  });

  test('extraDays clamps the month end instead of going negative', () {
    final a = age(DateTime(2026, 1, 31), DateTime(2026, 3, 1));
    expect(a.months, 1);
    expect(a.extraDays, 1);
  });

  test('milestone follows the total days', () {
    HabitAgeMilestone at(int days) =>
        HabitAge(years: 0, months: 0, days: days).milestone;

    expect(at(0), HabitAgeMilestone.startedToday);
    expect(at(1), HabitAgeMilestone.starting);
    expect(at(7), HabitAgeMilestone.rhythm);
    expect(at(30), HabitAgeMilestone.routine);
    expect(at(90), HabitAgeMilestone.impressive);
    expect(at(180), HabitAgeMilestone.outstanding);
    expect(at(365), HabitAgeMilestone.dedication);
    expect(at(730), HabitAgeMilestone.legendary);
  });

  test('age card strings take years, months, days in that order', () {
    final loc = AppLocalizationsEn();
    expect(loc.habitAgeCardYearsMonthsDays(2, 1, 6), '2y 1m 6d');
  });
}
