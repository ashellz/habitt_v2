import 'package:hive_ce_flutter/hive_flutter.dart';

class Habit extends HiveObject {
  final int id;
  String name;
  String description;
  String iconPath;
  int categoryId; // Any time, Morning, Afternoon, Evening
  String tag; // Custom tags
  bool completed;
  String amountLabel;
  int amount; // Number of times to do
  int amountCompleted; // Number of times completed
  int duration; // How long to do
  int durationCompleted; // How long has been done
  int streak;

  Habit({
    required this.id,
    required this.name,
    this.description = "",
    required this.iconPath,
    required this.categoryId,
    this.amountLabel = "times",
    this.tag = "No tag",
    this.completed = false,
    this.amount = 0,
    this.amountCompleted = 0,
    this.duration = 0,
    this.durationCompleted = 0,
    this.streak = 0,
  });

  void updateHabit(Habit habit) {
    name = habit.name;
    description = habit.description;
    iconPath = habit.iconPath;
    categoryId = habit.categoryId;
    tag = habit.tag;
    completed = habit.completed;
    amount = habit.amount;
    amountCompleted = habit.amountCompleted;
    duration = habit.duration;
    durationCompleted = habit.durationCompleted;
    streak = habit.streak;
  }

  void completeHabit() {
    completed = !completed;
    amountCompleted = completed ? amount : 0;
    durationCompleted = completed ? duration : 0;
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

  void resetCompletion() {
    completed = false;
    amountCompleted = 0;
    durationCompleted = 0;
  }
}
