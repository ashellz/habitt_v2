import 'package:habitt/services/goal_check_in_analyzer.dart';

/// [values] oldest first, one per day ending the day before [today].
List<GoalDayRecord> goalHistory(
  List<int> values, {
  required int goal,
  DateTime? today,
  Set<int> lighterIndexes = const {},
  Set<int> skippedIndexes = const {},
  Map<int, int> goalOverrides = const {},
}) {
  final end = today ?? DateTime(2026, 11, 25);
  return [
    for (var i = 0; i < values.length; i++)
      GoalDayRecord(
        date: DateTime(
          end.year,
          end.month,
          end.day,
        ).subtract(Duration(days: values.length - i)),
        goal: goalOverrides[i] ?? goal,
        value: values[i],
        lighter: lighterIndexes.contains(i),
        skipped: skippedIndexes.contains(i),
      ),
  ];
}

/// Minutes to seconds, for duration histories.
List<int> minutes(List<int> m) => [for (final v in m) v * 60];
