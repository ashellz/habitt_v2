import 'package:habitt/models/habit.dart';
import 'package:hive_ce/hive.dart';

class Day extends HiveObject {
  final DateTime date;
  final List<Habit> habits;

  Day({required this.date, required this.habits});
}
