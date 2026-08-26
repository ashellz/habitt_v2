import 'package:habitt/models/day.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/models/premade_habit_type.dart';
import 'package:hive_ce/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

// shared prefs key that tells the app if the running/walk/gym premade types
// have been converted into their Workouts-section equivalents
const String _premadeWorkoutTypesMigratedKey = 'premadeWorkoutTypesMigrated_v1';

const Map<PremadeHabitType, PremadeHabitType> _premadeTypeReplacements = {
  PremadeHabitType.running: PremadeHabitType.workoutRunning,
  PremadeHabitType.walk: PremadeHabitType.workoutWalking,
  PremadeHabitType.gym: PremadeHabitType.workoutCombined,
};

bool _retypeIfNeeded(Habit h) {
  final replacement = _premadeTypeReplacements[h.premadeHabitType];
  if (replacement == null) return false;
  h.premadeHabitType = replacement;
  h.timestamps['premadeHabitType'] = DateTime.now().toUtc();
  return true;
}

Future<void> migratePremadeWorkoutTypes({
  required Box<Habit> habitBox,
  required Box<Day> daysBox,
  required SharedPreferences prefs,
}) async {
  if (prefs.getBool(_premadeWorkoutTypesMigratedKey) ?? false) {
    return;
  }

  final habitUpdates = <dynamic, Habit>{};
  for (final key in habitBox.keys) {
    final habit = habitBox.get(key);
    if (habit == null) continue;
    if (_retypeIfNeeded(habit)) {
      habitUpdates[key] = habit;
    }
  }
  if (habitUpdates.isNotEmpty) {
    await habitBox.putAll(habitUpdates);
  }

  final dayUpdates = <dynamic, Day>{};
  for (final key in daysBox.keys) {
    final day = daysBox.get(key);
    if (day == null) continue;
    var changed = false;
    for (final habit in day.habits) {
      if (_retypeIfNeeded(habit)) {
        changed = true;
      }
    }
    if (changed) {
      dayUpdates[key] = day;
    }
  }
  if (dayUpdates.isNotEmpty) {
    await daysBox.putAll(dayUpdates);
  }

  await prefs.setBool(_premadeWorkoutTypesMigratedKey, true);
}
