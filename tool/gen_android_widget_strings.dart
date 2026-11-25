// Generates the Android home screen widget strings (picker names and
// descriptions, the look before the first snapshot) from the ARB files,
// which stay the source of truth. Run after changing any of the keys below:
//
//   dart run tool/gen_android_widget_strings.dart
//
// Writes android/app/src/main/res/values[-<lang>]/widget_strings.xml.
// See docs/home_widgets.md.
import 'dart:convert';
import 'dart:io';

/// ARB key → Android string name.
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

const _template = 'en';
const _res = 'android/app/src/main/res';

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
    final buffer =
        StringBuffer()
          ..writeln('<?xml version="1.0" encoding="utf-8"?>')
          ..writeln(
            '<!-- Generated from lib/l10n/app_$lang.arb by tool/gen_android_widget_strings.dart. Do not edit. -->',
          )
          ..writeln('<resources>');
    var count = 0;
    for (final entry in keys.entries) {
      final value = data[entry.key];
      if (value is! String) {
        if (lang == _template) {
          stderr.writeln('Missing ${entry.key} in ${arb.path}');
          exitCode = 1;
        }
        continue; // falls back to the English values/ string
      }
      buffer.writeln(
        '    <string name="${entry.value}">${_escape(value)}</string>',
      );
      count++;
    }
    buffer.writeln('</resources>');

    final dir = Directory(
      lang == _template ? '$_res/values' : '$_res/values-$lang',
    )..createSync(recursive: true);
    File('${dir.path}/widget_strings.xml').writeAsStringSync(buffer.toString());
    stdout.writeln('${dir.path}/widget_strings.xml: $count strings');
  }
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
