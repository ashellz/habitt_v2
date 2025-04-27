import 'package:flutter/material.dart';
import 'package:habitt/models/day.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:hive_ce/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DataProvider extends ChangeNotifier {
  DateTime? _lastOpenedDate;
  final daysBox = Hive.box<Day>('days');
  HabitProvider? habitProvider;

  DataProvider({required HabitProvider newHabitProvider}) {
    _init(newHabitProvider);
  }

  Future<void> _init(HabitProvider newHabitProvider) async {
    habitProvider = newHabitProvider;
    _updateLastOpenedDate();
  }

  Future<void> _updateLastOpenedDate() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    // I check if user has lastOpenedDate
    final temp = prefs.getString("lastOpenedDate");
    if (temp == null) {
      // If not, I set it to now
      _lastOpenedDate = DateTime.now();
    } else {
      // Else I set it to old one
      _lastOpenedDate = DateTime.parse(temp);
      // I check for new day
      checkForNewDay(prefs);
    }
  }

  void checkForNewDay(SharedPreferences prefs) {
    final DateTime today = DateTime.now();

    if (_lastOpenedDate!.day != today.day) {
      // Before updating lastOpenedDate, I update daysBox with that date
      _saveHabitDay(today);

      //Now we reset habit status (completion, amountCompleted, durationCompleted)
      habitProvider!.resetCompletion();
      // If new day, we now can update lastOpenedDate
      _lastOpenedDate = today;
      prefs.setString("lastOpenedDate", today.toString());

      notifyListeners();
    }
  }

  void _saveHabitDay(DateTime day) {
    final DateTime todaySimple = DateTime(day.year, day.month, day.day);

    for (final day in daysBox.values) {
      debugPrint(day.date.toString());
      daysBox.put(todaySimple, day);
    }
  }

  DateTime get lastOpenedDate => _lastOpenedDate ?? DateTime.now();
}
