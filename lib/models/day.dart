import 'package:habitt/models/habit.dart';
import 'package:hive_ce/hive.dart';

class Day extends HiveObject {
  final DateTime date;
  final List<Habit> habits;
  final DateTime? timestamp;

  Day({required this.date, required this.habits, required this.timestamp});

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'habits': habits.map((h) => h.toMap()).toList(),
      'timestamp': timestamp?.toIso8601String(),
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
