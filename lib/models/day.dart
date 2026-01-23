import 'package:habitt/models/habit.dart';
import 'package:hive_ce/hive.dart';

class Day extends HiveObject {
  final DateTime date;
  final List<Habit> habits;

  Day({required this.date, required this.habits});

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'habits': habits.map((h) => h.toMap()).toList(),
    };
  }

  factory Day.fromMap(Map<String, dynamic> m) {
    final habits =
        (m['habits'] as List<dynamic>? ?? [])
            .map((e) => Habit.fromMap(Map<String, dynamic>.from(e)))
            .toList();
    return Day(date: DateTime.parse(m['date'] as String), habits: habits);
  }
}
