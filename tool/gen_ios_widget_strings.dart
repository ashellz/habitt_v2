// Generates the iOS home screen widget strings (picker names and
// descriptions, the look before the first snapshot) and the Apple Watch app's
// own UI strings from the ARB files, which stay the source of truth. Run
// after changing any of the keys below:
//
//   dart run tool/gen_ios_widget_strings.dart
//
// Writes ios/HabittWidgets/<lang>.lproj/Localizable.strings and
// ios/HabittWatch/<lang>.lproj/Localizable.strings, keyed by the ARB key
// names. ARB placeholders (`{name}`) become `%@`. Languages missing a key fall
// back to the English value. See docs/home_widgets.md and docs/watch_app.md.
import 'dart:convert';
import 'dart:io';

const widgetKeys = [
  'widgetStreakName',
  'widgetStreakDescription',
  'widgetStreakWeekName',
  'widgetStreakWeekDescription',
  'widgetTodayRingName',
  'widgetTodayRingDescription',
  'widgetUpNextName',
  'widgetUpNextDescription',
  // the widgets' look before the app wrote its first snapshot: no habits, 0 streak
  'youHaventAddedAnyHabitsYet',
  'dayStreakLabel',
  'daysStreakLabel',
  'day',
  'days',
  'widgetStartStreak',
  // sample data for the widget gallery while the user has no habits
  'premadeHabitBrushTeeth',
  'premadeHabitShower',
  'premadeHabitDrinkWater',
  'premadeHabitRead',
  'premadeHabitMindfulness',
  'morning',
  'afternoon',
  'evening',
  'streakPraiseExtra2',
];

// the watch app's own UI; habit names, parts of the day and other app text
// come in the snapshot, in the app's language
const watchKeys = [
  'watchOpenOnIPhone',
  'watchOpenOnIPhoneBody',
  'watchUpdateNeeded',
  'watchUpdateNeededBody',
  'watchHealthNote',
  'watchLogOnIPhone',
  'watchShowHabits',
  'watchOfTarget',
  'watchCompleteHabit',
  'watchUncompleteHabit',
  'watchLess',
  'watchMore',
  'today',
];

const _template = 'en';
const _outputs = {
  'ios/HabittWidgets': widgetKeys,
  'ios/HabittWatch': watchKeys,
};

void main() {
  final arbs =
      Directory('lib/l10n')
          .listSync()
          .whereType<File>()
          .where((f) => RegExp(r'app_[a-z]{2}\.arb$').hasMatch(f.path))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  Map<String, dynamic> read(File f) =>
      jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
  final english = read(
    arbs.firstWhere((f) => f.path.endsWith('app_$_template.arb')),
  );

  for (final MapEntry(key: out, value: keys) in _outputs.entries) {
    for (final arb in arbs) {
      final lang =
          RegExp(r'app_([a-z]{2})\.arb$').firstMatch(arb.path)!.group(1)!;
      final data = read(arb);
      final buffer =
          StringBuffer()..writeln(
            '/* Generated from lib/l10n/app_$lang.arb by tool/gen_ios_widget_strings.dart. Do not edit. */',
          );
      var count = 0;
      for (final key in keys) {
        var value = data[key];
        if (value is! String) {
          value = english[key];
          if (value is! String) {
            stderr.writeln('Missing $key in app_$_template.arb');
            exitCode = 1;
            continue;
          }
        } else {
          count++;
        }
        buffer.writeln('"$key" = "${_escape(_placeholders(value))}";');
      }

      final dir = Directory('$out/$lang.lproj')..createSync(recursive: true);
      File(
        '${dir.path}/Localizable.strings',
      ).writeAsStringSync(buffer.toString());
      stdout.writeln(
        '${dir.path}/Localizable.strings: $count of ${keys.length} strings',
      );
    }
  }
}

/// ARB `{name}` placeholders → `%@` for `String(format:)`.
String _placeholders(String s) =>
    s.replaceAll(RegExp(r'\{[A-Za-z][A-Za-z0-9_]*\}'), '%@');

/// `.strings` escaping.
String _escape(String s) =>
    s.replaceAll(r'\', r'\\').replaceAll('"', r'\"').replaceAll('\n', r'\n');
