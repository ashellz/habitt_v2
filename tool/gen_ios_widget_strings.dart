// Generates the iOS home screen widget strings (picker names and
// descriptions, the look before the first snapshot) from the ARB files,
// which stay the source of truth. Run after changing any of the keys below:
//
//   dart run tool/gen_ios_widget_strings.dart
//
// Writes ios/HabittWidgets/<lang>.lproj/Localizable.strings, keyed by the ARB
// key names. Languages missing a key fall back to the English value.
// See docs/home_widgets.md.
import 'dart:convert';
import 'dart:io';

const keys = [
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
];

const _template = 'en';
const _out = 'ios/HabittWidgets';

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

  for (final arb in arbs) {
    final lang =
        RegExp(r'app_([a-z]{2})\.arb$').firstMatch(arb.path)!.group(1)!;
    final data = read(arb);
    final buffer =
        StringBuffer()
          ..writeln(
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
      buffer.writeln('"$key" = "${_escape(value)}";');
    }

    final dir = Directory('$_out/$lang.lproj')..createSync(recursive: true);
    File(
      '${dir.path}/Localizable.strings',
    ).writeAsStringSync(buffer.toString());
    stdout.writeln(
      '${dir.path}/Localizable.strings: $count of ${keys.length} strings',
    );
  }
}

/// `.strings` escaping.
String _escape(String s) => s
    .replaceAll(r'\', r'\\')
    .replaceAll('"', r'\"')
    .replaceAll('\n', r'\n');
