import 'dart:ui';

import 'package:habitt/widgets/habit_details/select_habit_time_page/select_habit_time_body.dart';

class PrimaryHabitConfig {
  const PrimaryHabitConfig({
    required this.enabled,
    required this.timeType,
    required this.startHour,
    this.durationHours,
    this.endHour,
    required this.iconPath,
    required this.name,
    required this.containerColor,
    required this.lineColor,
  });

  final bool enabled;
  final TimeType timeType;
  final double startHour; // in hours
  final double? durationHours; // used for regular type
  final double? endHour; // used for overday/midnight extra segment
  final String iconPath;
  final String name;
  final Color containerColor;
  final Color lineColor;
}
