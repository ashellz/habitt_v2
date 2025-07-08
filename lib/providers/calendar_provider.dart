import 'package:flutter/material.dart';

class CalendarProvider extends ChangeNotifier {
  DateTime _focusedDay = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );

  DateTime get focusedDay => _focusedDay;

  void onDaySelected(DateTime day, DateTime focusedDay) {
    _focusedDay = day;
    notifyListeners();
  }

  void resetFocusedDay() {
    _focusedDay = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    notifyListeners();
  }
}
