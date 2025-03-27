import 'package:flutter/material.dart';

class StateProvider extends ChangeNotifier {
  int _habitAmount = 0;
  Duration _habitDuration = Duration.zero;
  TextEditingController nameController = TextEditingController();
  TextEditingController descController = TextEditingController();
  String _iconPath = "";

  set iconPath(String newPath) {
    if (_iconPath != newPath) {
      Future.delayed(Duration(milliseconds: 150)).then((value) {
        _iconPath = newPath;
        notifyListeners();
      });
    }
  }

  set habitAmount(int value) {
    _habitAmount = value;
    notifyListeners();
  }

  set habitDuration(Duration value) {
    _habitDuration = value;
    notifyListeners();
  }

  void reset() {
    _habitAmount = 0;
    _habitDuration = Duration.zero;
    nameController.clear();
    descController.clear();
    _iconPath = "";
    notifyListeners();
  }

  int get habitAmount => _habitAmount;
  Duration get habitDuration => _habitDuration;
  String get iconPath => _iconPath;
}
