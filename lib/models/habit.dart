import 'package:hive_ce_flutter/hive_flutter.dart';

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
  });

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
      duration: duration,
      durationCompleted: durationCompleted,
      longestStreak: longestStreak,
      skipped: skipped,
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
}
