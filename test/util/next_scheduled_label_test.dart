import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/util/next_scheduled_label.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting();
  });

  final today = DateTime(2026, 10, 29); // a Thursday
  final en = lookupAppLocalizations(const Locale('en'));

  String label(DateTime date, {Locale locale = const Locale('en')}) =>
      nextScheduledLabel(
        lookupAppLocalizations(locale),
        locale,
        date,
        today: today,
      );

  test('today and tomorrow', () {
    expect(label(today), en.today);
    expect(label(DateTime(2026, 10, 30)), 'Tomorrow');
  });

  test('weekday within the next week', () {
    expect(label(DateTime(2026, 11, 3)), 'Tuesday');
    expect(label(DateTime(2026, 11, 4)), 'Wednesday'); // 6 days
  });

  test('a week out or more is a date with an ordinal', () {
    expect(label(DateTime(2026, 11, 5)), '5th Nov');
    expect(label(DateTime(2026, 11, 12)), '12th Nov');
    expect(label(DateTime(2026, 11, 21)), '21st Nov');
    expect(label(DateTime(2026, 11, 22)), '22nd Nov');
    expect(label(DateTime(2026, 11, 23)), '23rd Nov');
  });

  test('next year includes the year', () {
    expect(label(DateTime(2027, 1, 2)), '2nd Jan 2027');
  });

  test('follows the language', () {
    expect(label(DateTime(2026, 10, 30), locale: const Locale('de')), 'Morgen');
    expect(
      label(DateTime(2026, 11, 3), locale: const Locale('de')),
      'Dienstag',
    );
    expect(
      label(DateTime(2026, 11, 12), locale: const Locale('de')),
      '12. Nov',
    );
  });

  test('calendarDaysBetween ignores time of day', () {
    expect(
      calendarDaysBetween(
        DateTime(2026, 10, 29, 23, 59),
        DateTime(2026, 10, 30, 0, 1),
      ),
      1,
    );
  });
}
