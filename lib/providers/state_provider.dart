import 'package:flutter/material.dart';

class StateProvider extends ChangeNotifier {
  int _habitAmount = 0;
  Duration _habitDuration = Duration.zero;

  set habitAmount(int value) {
    _habitAmount = value;
    notifyListeners();
  }

  set habitDuration(Duration value) {
    _habitDuration = value;
    notifyListeners();
  }

  int get habitAmount => _habitAmount;
  Duration get habitDuration => _habitDuration;
}
