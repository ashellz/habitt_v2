import 'package:flutter/widgets.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> updateLastOpenedDate(HabitProvider habitProvider) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  DateTime lastOpenedDate;

  debugPrint("Running _updateLastOpenedDate");

  // I check if user has lastOpenedDate
  final temp = prefs.getString("lastOpenedDate");

  debugPrint("temp: $temp");
  if (temp == null) {
    // If not, I set it to now
    lastOpenedDate = DateTime.now();
    final DateTime today = DateTime.now();
    prefs.setString("lastOpenedDate", today.toString());
  } else {
    // Else I set it to old one
    lastOpenedDate = DateTime.parse(temp);
    // I check for new day
    checkForNewDay(prefs, lastOpenedDate, habitProvider);
  }
}

void checkForNewDay(
  SharedPreferences prefs,
  DateTime lastOpenedDate,
  HabitProvider habitProvider,
) {
  DateTime today = DateTime.now();

  if (lastOpenedDate.day != today.day ||
      lastOpenedDate.month != today.month ||
      lastOpenedDate.year != today.year) {
    habitProvider.saveHabitDay(lastOpenedDate);
    habitProvider.resetCompletion();

    prefs.setString("lastOpenedDate", today.toString());
  }
}
