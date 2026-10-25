import 'package:habitt/models/habit.dart';
import 'package:habitt/models/health_metric_type.dart';
import 'package:habitt/models/health_workout_type.dart';
import 'package:habitt/models/premade_habit_type.dart';
import 'package:habitt/util/amount_label_preset.dart';

// Category ids match the app's default seeded categories:
// 1 = Any time, 2 = Morning, 3 = Afternoon, 4 = Evening.
//
// Ids are negative so they can never collide with a real, persisted habit id
// (HabitProvider/Hive ids come from getUniqueId(), always positive) — demo
// habits are never written into HabitProvider or the `habits` Hive box, they
// only exist for display in demo-mode UI.
//
// Time intervals cover the plan view's cases: back-to-back habits (push ups,
// then studying), a long habit others start during (studying), two habits
// with the same start (workouts), and one crossing midnight (sleep).
final List<Habit> demoHabits = [
  // Regular habit — no amount/duration goal, just a daily checkbox. Shown
  // already completed.
  Habit(
    id: -1,
    timeIntervalEnabled: true,
    timeIntervalStart: 21 * 60 + 30,
    timeIntervalEnd: 22 * 60,
    name: 'Brush teeth',
    iconPath: '🪥',
    categoryId: 4,
    completed: true,
    premadeHabitType: PremadeHabitType.brushTeeth,
  ),

  // Amount habit — a target number of reps, partially completed.
  Habit(
    id: -2,
    timeIntervalEnabled: true,
    timeIntervalStart: 7 * 60,
    timeIntervalEnd: 7 * 60 + 30,
    name: 'Push ups',
    iconPath: '💪',
    categoryId: 2,
    amount: 30,
    amountCompleted: 18,
    amountLabel: AmountLabelPreset.times.plural,
    trackingType: HabitTrackingType.amount,
  ),

  // Duration habit — a target number of minutes, partially completed.
  Habit(
    id: -3,
    timeIntervalEnabled: true,
    timeIntervalStart: 7 * 60 + 30,
    timeIntervalEnd: 20 * 60,
    name: 'Studying',
    iconPath: '📚',
    categoryId: 3,
    duration: 45 * 60,
    durationCompleted: 20 * 60,
    trackingType: HabitTrackingType.duration,
    premadeHabitType: PremadeHabitType.studying,
  ),

  // Sleep time habit — amount tracking, linked to Health's bedtime
  // metric. Not yet hit.
  Habit(
    id: -4,
    timeIntervalEnabled: true,
    timeIntervalStart: 22 * 60,
    timeIntervalEnd: 6 * 60,
    name: 'Sleep time',
    iconPath: '🛌',
    categoryId: 4,
    amount: 8 * 60,
    amountCompleted: 7 * 60,
    toleranceMinutes: 60,
    trackingType: HabitTrackingType.amount,
    healthMetric: HealthMetricType.sleep,
    premadeHabitType: PremadeHabitType.sleepTime,
  ),

  // Health workout habit, tracked by duration — a target number of minutes
  // of a specific workout type. Shown fully completed.
  Habit(
    id: -5,
    timeIntervalEnabled: true,
    timeIntervalStart: 9 * 60,
    timeIntervalEnd: 10 * 60,
    name: 'Running workout',
    iconPath: '🏃',
    categoryId: 1,
    duration: 30 * 60,
    durationCompleted: 30 * 60,
    completed: true,
    trackingType: HabitTrackingType.duration,
    healthMetric: HealthMetricType.workouts,
    healthWorkoutFilter: HealthWorkoutType.running,
    premadeHabitType: PremadeHabitType.workoutRunning,
  ),

  // Health workout habit, tracked by amount — a target number of logged
  // sessions instead of minutes (workouts/mindfulness are the only metrics
  // that support this Amount-vs-Duration choice; no filter = any workout).
  // Shown fully completed.
  Habit(
    id: -6,
    timeIntervalEnabled: true,
    timeIntervalStart: 9 * 60,
    timeIntervalEnd: 9 * 60 + 30,
    name: 'Workout sessions',
    iconPath: '🏋️',
    categoryId: 1,
    amount: 1,
    amountCompleted: 1,
    completed: true,
    amountLabel: AmountLabelPreset.times.plural,
    trackingType: HabitTrackingType.amount,
    healthMetric: HealthMetricType.workouts,
    premadeHabitType: PremadeHabitType.workoutCombined,
  ),
];
