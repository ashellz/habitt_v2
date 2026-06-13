import 'package:habitt/models/habit.dart';
import 'package:hive_ce/hive.dart';

class Day extends HiveObject {
  final DateTime date;
  final List<Habit> habits;
  final DateTime? timestamp;

  /// True when this day was created locally by the day-rollover or backfill
  /// logic — not by a real user action. Auto-created days always lose the
  /// merge against incoming backup/delta data regardless of timestamps, so
  /// that Drive data (with actual completions) is never rejected in favour of
  /// a blank reset snapshot with a newer wall-clock stamp.
  final bool isAutoCreated;

  Day({
    required this.date,
    required this.habits,
    required this.timestamp,
    this.isAutoCreated = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'date':
          '${date.year.toString().padLeft(4, '0')}-'
          '${date.month.toString().padLeft(2, '0')}-'
          '${date.day.toString().padLeft(2, '0')}',
      'habits': habits.map((h) => h.toMap()).toList(),
      'timestamp': timestamp?.toIso8601String(),
      // isAutoCreated intentionally omitted — local-only flag, never synced
    };
  }

  factory Day.fromMap(Map<String, dynamic> m) {
    final habits =
        (m['habits'] as List<dynamic>? ?? [])
            .map((e) => Habit.fromMap(Map<String, dynamic>.from(e)))
            .toList();

    final rawTimestamp = m['timestamp'];
    final parsedTimestamp =
        rawTimestamp is String
            ? DateTime.tryParse(rawTimestamp)
            : rawTimestamp is DateTime
            ? rawTimestamp
            : null;

    return Day(
      date: DateTime.parse(m['date'] as String),
      habits: habits,
      timestamp: (parsedTimestamp ?? DateTime.now()).toUtc(),
    );
  }
}
