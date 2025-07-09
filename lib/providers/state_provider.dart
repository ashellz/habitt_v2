import 'package:flutter/material.dart';
import 'package:habitt/generated/assets.gen.dart';

class StateProvider extends ChangeNotifier {
  int _habitCategoryId = 1;
  int _habitAmount = 0;
  Duration _habitDuration = Duration.zero;
  TextEditingController habitAmountLabelController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  TextEditingController descController = TextEditingController();
  String _iconPath = "";
  bool _isAdditional = false;

  bool _canEditCalendar = false;

  bool get canEditCalendar => _canEditCalendar;

  set canEditCalendar(bool value) {
    _canEditCalendar = value;
    notifyListeners();
  }

  toggleAditional() {
    _isAdditional = !_isAdditional;
    notifyListeners();
  }

  set isAdditional(bool value) {
    _isAdditional = value;
    notifyListeners();
  }

  set iconPath(String newPath) {
    if (_iconPath != newPath) {
      Future.delayed(Duration(milliseconds: 150)).then((value) {
        _iconPath = newPath;
        notifyListeners();
      });
    }
  }

  set habitCategoryId(int id) {
    _habitCategoryId = id;
    notifyListeners();
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

    _habitCategoryId = 1;
    habitAmountLabelController.clear();
    nameController.clear();
    descController.clear();
    _iconPath = Assets.images.icons.book.path;
    _isAdditional = false;
    notifyListeners();
  }

  int get habitCategoryId => _habitCategoryId;

  int get habitAmount => _habitAmount;

  Duration get habitDuration => _habitDuration;

  String get iconPath => _iconPath;

  bool get isAdditional => _isAdditional;
}
