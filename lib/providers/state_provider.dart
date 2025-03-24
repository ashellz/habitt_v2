import 'package:flutter/material.dart';

class StateProvider extends ChangeNotifier {
  int _habitAmount = 0;
  Duration _habitDuration = Duration.zero;
  TextEditingController nameController = TextEditingController();
  TextEditingController descController = TextEditingController();

  set habitAmount(int value) {
    _habitAmount = value;
    notifyListeners();
  }

  set habitDuration(Duration value) {
    _habitDuration = value;
    notifyListeners();
  }

  set name(String value) {
    nameController.text = value;
    notifyListeners();
  }

  set desc(String value) {
    descController.text = value;
    notifyListeners();
  }

  void reset() {
    _habitAmount = 0;
    _habitDuration = Duration.zero;
    nameController.clear();
    descController.clear();
    notifyListeners();
  }

  int get habitAmount => _habitAmount;
  Duration get habitDuration => _habitDuration;
  String get name => nameController.text;
  String get desc => descController.text;
}
