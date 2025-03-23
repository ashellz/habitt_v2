import 'package:flutter/material.dart';

class StateProvider extends ChangeNotifier {
  int _wheelAmount = 0;

  set wheelAmount(int value) {
    _wheelAmount = value;
    notifyListeners();
  }

  int get wheelAmount => _wheelAmount;
}
