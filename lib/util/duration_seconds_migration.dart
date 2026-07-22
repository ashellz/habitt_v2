import 'package:habitt/models/day.dart';
import 'package:habitt/models/habit.dart';
import 'package:hive_ce/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

const int kDurationSecondsDataVersion = 1;

// shared prefs keys that tell the app if minutes to seconds migration has been completed
const String _habitsMigratedKey = 'durationSecondsMigrated_habits_v1';
const String _daysMigratedKey = 'durationSecondsMigrated_days_v1';

void _toSeconds(Habit h) {
  h.duration *= 60;
  h.durationCompleted *= 60;
}

Future<void> migrateDurationToSeconds({
  required Box<Habit> habitBox,
  required Box<Day> daysBox,
  required SharedPreferences prefs,
}) async {
  if (!(prefs.getBool(_habitsMigratedKey) ?? false)) {
    final updates = <dynamic, Habit>{};
    for (final key in habitBox.keys) {
      final habit = habitBox.get(key);
      if (habit == null) continue;
      _toSeconds(habit);
      updates[key] = habit;
    }
    await habitBox.putAll(updates);
    await prefs.setBool(_habitsMigratedKey, true);
  }

  if (!(prefs.getBool(_daysMigratedKey) ?? false)) {
    final updates = <dynamic, Day>{};
    for (final key in daysBox.keys) {
      final day = daysBox.get(key);
      if (day == null) continue;
      for (final habit in day.habits) {
        _toSeconds(habit);
      }
      updates[key] = day;
    }
    await daysBox.putAll(updates);
    await prefs.setBool(_daysMigratedKey, true);
  }
}
