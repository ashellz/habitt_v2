import 'package:flutter/material.dart';

class CalendarProvider extends ChangeNotifier {
  int _selectedCategoryId = 0;

  int get selectedCategoryId => _selectedCategoryId;

  void selectCategory(int index) {
    _selectedCategoryId = index;
    notifyListeners();
  }

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
