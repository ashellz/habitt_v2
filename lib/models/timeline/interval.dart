import 'package:habitt/models/timeline/primary_habit_config.dart';

class Interval {
  Interval.habit({
    required this.habit,
    required this.startY,
    required this.endY,
    required this.height,
  }) : kind = 'habit',
       primary = null;

  Interval.primary({
    required this.primary,
    required this.startY,
    required this.endY,
    required this.height,
  }) : kind = 'primary',
       habit = null;

  final String kind;
  final dynamic habit;
  final PrimaryHabitConfig? primary;
  final double startY;
  final double endY;
  final double height;
  int? columnIndex;
}
