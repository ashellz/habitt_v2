// Generates Android string resources from the ARB files, which stay the
// source of truth: the home screen widgets' (picker names and descriptions,
// the look before the first snapshot) and the Wear OS app's own texts (shown
// before the first snapshot, or when an older phone app didn't send them).
// Run after changing any of the keys below:
//
//   dart run tool/gen_android_widget_strings.dart
//
// Writes android/app/src/main/res/values[-<lang>]/widget_strings.xml and
// android/wear/src/main/res/values[-<lang>]/wear_strings.xml. ICU
// placeholders (`{name}`) become `%1$s`. See docs/home_widgets.md and
// docs/watch_app.md.
import 'dart:convert';
import 'dart:io';

/// ARB key → Android string name, for the home screen widgets.
const keys = {
  'widgetStreakName': 'widget_streak_name',
  'widgetStreakDescription': 'widget_streak_description',
  'widgetStreakWeekName': 'widget_streak_week_name',
  'widgetStreakWeekDescription': 'widget_streak_week_description',
  'widgetTodayRingName': 'widget_today_ring_name',
  'widgetTodayRingDescription': 'widget_today_ring_description',
  'widgetUpNextName': 'widget_up_next_name',
  'widgetUpNextDescription': 'widget_up_next_description',
  // the widgets' look before the app wrote its first snapshot: no habits, 0 streak
  'youHaventAddedAnyHabitsYet': 'widget_no_habits',
  'dayStreakLabel': 'widget_day_streak',
  'daysStreakLabel': 'widget_days_streak',
  'day': 'widget_day',
  'days': 'widget_days',
  'widgetStartStreak': 'widget_start_streak',
};

/// ARB key → Android string name, for the Wear OS app. Keep in sync with
/// `WearText` in android/wear (the snapshot key it falls back from).
const wearKeys = {
  'today': 'wear_today',
  'anyTime': 'wear_any_time',
  'morning': 'wear_morning',
  'afternoon': 'wear_afternoon',
  'evening': 'wear_evening',
  'optional': 'wear_optional',
  'wearOpenOnPhone': 'wear_open_on_phone',
  'watchOpenOnIPhoneBody': 'wear_open_on_phone_body',
  'watchUpdateNeeded': 'wear_update_needed',
  'wearUpdateNeededBody': 'wear_update_needed_body',
  'wearHealthNote': 'wear_health_note',
  'wearLogOnPhone': 'wear_log_on_phone',
  'watchShowHabits': 'wear_show_habits',
  'watchOfTarget': 'wear_of_target',
  'watchCompleteHabit': 'wear_complete_habit',
  'watchUncompleteHabit': 'wear_uncomplete_habit',
  'watchLess': 'wear_less',
  'watchMore': 'wear_more',
  'youHaventAddedAnyHabitsYet': 'wear_no_habits',
  'widgetNothingToday': 'wear_nothing_today',
};

const _template = 'en';
const _targets = [
  (res: 'android/app/src/main/res', file: 'widget_strings.xml', keys: keys),
  (res: 'android/wear/src/main/res', file: 'wear_strings.xml', keys: wearKeys),
];

void main() {
  final arbs =
      Directory('lib/l10n')
          .listSync()
          .whereType<File>()
          .where((f) => RegExp(r'app_[a-z]{2}\.arb$').hasMatch(f.path))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  for (final arb in arbs) {
    final lang =
        RegExp(r'app_([a-z]{2})\.arb$').firstMatch(arb.path)!.group(1)!;
    final data = jsonDecode(arb.readAsStringSync()) as Map<String, dynamic>;
    for (final target in _targets) {
      final buffer =
          StringBuffer()
            ..writeln('<?xml version="1.0" encoding="utf-8"?>')
            ..writeln(
              '<!-- Generated from lib/l10n/app_$lang.arb by tool/gen_android_widget_strings.dart. Do not edit. -->',
            )
            ..writeln('<resources>');
      var count = 0;
      for (final entry in target.keys.entries) {
        final value = data[entry.key];
        if (value is! String) {
          if (lang == _template) {
            stderr.writeln('Missing ${entry.key} in ${arb.path}');
            exitCode = 1;
          }
          continue; // falls back to the English values/ string
        }
        buffer.writeln(
          '    <string name="${entry.value}">${_placeholders(_escape(value))}</string>',
        );
        count++;
      }
      buffer.writeln('</resources>');

      final dir = Directory(
        lang == _template
            ? '${target.res}/values'
            : '${target.res}/values-$lang',
      )..createSync(recursive: true);
      File('${dir.path}/${target.file}').writeAsStringSync(buffer.toString());
      stdout.writeln('${dir.path}/${target.file}: $count strings');
    }
  }
}

/// ICU placeholders (`{name}`) → positional format args (`%1$s`, `%2$s`).
String _placeholders(String s) {
  final names = <String>[];
  return s.replaceAllMapped(RegExp(r'\{(\w+)\}'), (m) {
    final name = m.group(1)!;
    if (!names.contains(name)) names.add(name);
    return '%${names.indexOf(name) + 1}\$s';
  });
}

/// Android string resource escaping.
String _escape(String s) => s
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll(r'\', r'\\')
    .replaceAll("'", r"\'")
    .replaceAll('"', r'\"')
    .replaceAll('@', r'\@')
    .replaceAll('?', r'\?');
