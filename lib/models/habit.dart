import 'dart:ui';

import 'package:habitt/providers/theme_provider.dart';
import 'package:habitt/util/color_converting.dart';
import 'package:habitt/widgets/habit_details/select_habit_time_page/select_habit_time_body.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:tinycolor2/tinycolor2.dart';

class Habit extends HiveObject {
  final int id;
  String name;
  String description;
  String iconPath;
  int categoryId; // Any time, Morning, Afternoon, Evening
  String tag; // Custom tags
  bool completed;
  bool skipped;
  String amountLabel;
  int amount; // Number of times to do
  int amountCompleted; // Number of times completed
  int duration; // How long to do
  int durationCompleted; // How long has been done
  int streak;
  int longestStreak;
  bool additional;
  bool timeIntervalEnabled;
  int timeIntervalStart; // In minutes
  int timeIntervalEnd; // In minutes
  String? color;

  Habit({
    required this.id,
    required this.name,
    this.description = "",
    required this.iconPath,
    required this.categoryId,
    this.amountLabel = "times",
    this.tag = "No tag",
    this.completed = false,
    this.skipped = false,
    this.amount = 0,
    this.amountCompleted = 0,
    this.duration = 0,
    this.durationCompleted = 0,
    this.streak = 0,
    this.longestStreak = 0,
    this.additional = false,
    this.timeIntervalEnabled = false,
    this.timeIntervalStart = 420,
    this.timeIntervalEnd = 450,
    this.color,
  });

  // convert to getter
  Color? get getColor {
    if (color == null) return null;
    return hexToColor(color!);
  }

  // setter for color
  set setColor(Color newColor) {
    color = colorToHex(newColor);
  }

  Habit copy() {
    return Habit(
      id: id,
      name: name,
      completed: completed,
      streak: streak,
      description: description,
      iconPath: iconPath,
      categoryId: categoryId,
      tag: tag,
      amount: amount,
      amountCompleted: amountCompleted,
      amountLabel: amountLabel,
      duration: duration,
      durationCompleted: durationCompleted,
      longestStreak: longestStreak,
      skipped: skipped,
      additional: additional,
      timeIntervalEnabled: timeIntervalEnabled,
      timeIntervalStart: timeIntervalStart,
      timeIntervalEnd: timeIntervalEnd,
      color: color,
    );
  }

  Habit copyResetCompletion() {
    return Habit(
      id: id,
      name: name,
      completed: false,
      streak: streak,
      description: description,
      iconPath: iconPath,
      categoryId: categoryId,
      tag: tag,
      amount: amount,
      amountCompleted: 0,
      amountLabel: amountLabel,
      duration: duration,
      durationCompleted: 0,
      longestStreak: longestStreak,
      skipped: false,
      additional: additional,
      timeIntervalEnabled: timeIntervalEnabled,
      timeIntervalStart: timeIntervalStart,
      timeIntervalEnd: timeIntervalEnd,
      color: color,
    );
  }

  void updateHabit(Habit habit) {
    name = habit.name;
    description = habit.description;
    iconPath = habit.iconPath;
    categoryId = habit.categoryId;
    tag = habit.tag;
    completed = habit.completed;
    skipped = habit.skipped;
    amount = habit.amount;
    amountCompleted = habit.amountCompleted;
    duration = habit.duration;
    durationCompleted = habit.durationCompleted;
    streak = habit.streak;
    longestStreak = habit.longestStreak;
    additional = habit.additional;
    timeIntervalEnabled = habit.timeIntervalEnabled;
    timeIntervalStart = habit.timeIntervalStart;
    timeIntervalEnd = habit.timeIntervalEnd;
    color = habit.color;
  }

  Future<void> completeHabit() async {
    if (skipped) {
      completed = false;
      skipped = false;
      amountCompleted = 0;
      durationCompleted = 0;
      return;
    }

    completed = !completed;
    skipped = false;
    amountCompleted = completed ? amount : 0;
    durationCompleted = completed ? duration : 0;
  }

  Future<void> skipHabit() async {
    skipped = !skipped;
  }

  void updateHabitAmountCompleted(int amountCompleted) {
    if (amountCompleted == amount) {
      completed = true;
    }
    this.amountCompleted = amountCompleted;
  }

  void updateHabitDurationCompleted(int durationCompleted) {
    if (durationCompleted == duration) {
      completed = true;
    }
    this.durationCompleted = durationCompleted;
  }

  Future<void> resetCompletion() async {
    completed = false;
    skipped = false;
    amountCompleted = 0;
    durationCompleted = 0;
  }

  /// Get the habit name color based on theme mode
  Color getNameColor(ThemeProvider tp) {
    if (tp.isDark) {
      return getColor != null
          ? getColor!.lighten(30)
          : tp.primaryColor.lighten(30);
    } else {
      return getColor != null
          ? getColor!.darken(40)
          : tp.primaryColor.darken(40);
    }
  }

  /// Get the habit container color with opacity based on theme mode
  Color getContainerColor(ThemeProvider tp, {bool isCurrentHabit = true}) {
    final opacity = isCurrentHabit ? 0.7 : 0.5;
    if (tp.isDark) {
      return getColor?.withOpacity(opacity) ??
          tp.primaryColor.darken(30).withOpacity(opacity);
    } else {
      return getColor?.withOpacity(opacity) ??
          tp.primaryColor.lighten(30).withOpacity(opacity);
    }
  }

  /// Check if habit name should be shown based on time type
  bool shouldShowName(TimeType timeType) {
    return !(timeIntervalEnd - timeIntervalStart <= 5 &&
        timeType == TimeType.regular);
  }

  /// Get the time type of the habit (regular, overday, or midnight)
  TimeType getTimeType() {
    return timeIntervalEnd == 0
        ? TimeType.midnight
        : timeIntervalStart > timeIntervalEnd
        ? TimeType.overday
        : TimeType.regular;
  }

  /// Get the duration in hours
  double getTimeDuration() {
    if (getTimeType() == TimeType.regular) {
      return timeIntervalEnd / 60 - timeIntervalStart / 60;
    } else {
      return timeIntervalEnd / 60;
    }
  }

  /// Get the start hour (0-24)
  double getStartHour() {
    return timeIntervalStart / 60;
  }
}
