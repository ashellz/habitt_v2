import 'package:habitt/models/habit.dart';
import 'package:habitt/models/premade_habit_type.dart';
import 'package:habitt/models/schedule_type.dart';

Habit buildTestHabit({
  int id = 1,
  String name = 'Drink water',
  int amount = 10,
  int amountCompleted = 0,
  String amountLabel = 'dl',
  int duration = 0,
  int durationCompleted = 0,
  HabitTrackingType? trackingType = HabitTrackingType.amount,
  ScheduleType scheduleType = ScheduleType.daily,
  int weeklyTarget = 1,
  int monthlyTarget = 1,
  int timesCompletedThisWeek = 0,
  int timesCompletedThisMonth = 0,
  bool optional = false,
  PremadeHabitType? premadeHabitType = PremadeHabitType.drinkWater,
  DateTime? createdAt,
  Map<String, DateTime>? timestamps,
}) {
  return Habit(
    id: id,
    name: name,
    iconPath: 'assets/images/icons/water.png',
    categoryId: 1,
    amount: amount,
    amountCompleted: amountCompleted,
    amountLabel: amountLabel,
    duration: duration,
    durationCompleted: durationCompleted,
    trackingType: trackingType,
    scheduleType: scheduleType,
    weeklyTarget: weeklyTarget,
    monthlyTarget: monthlyTarget,
    timesCompletedThisWeek: timesCompletedThisWeek,
    timesCompletedThisMonth: timesCompletedThisMonth,
    optional: optional,
    premadeHabitType: premadeHabitType,
    createdAt: createdAt,
    timestamps: timestamps,
  );
}
