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
  Color? _habitColor;

  String _alertText = "";
  bool _showAlert = false;

  String get alertText => _alertText;
  bool get showAlert => _showAlert;

  set alertText(String value) {
    _alertText = value;
    notifyListeners();
  }

  void toggleAlert({bool? show}) {
    _showAlert = show ?? !_showAlert;
    notifyListeners();
  }

  bool _timeIntervalEnabled = false;
  int _timeIntervalStart = 420;
  int _timeIntervalEnd = 450;

  bool get timeIntervalEnabled => _timeIntervalEnabled;
  int get timeIntervalStart => _timeIntervalStart;
  int get timeIntervalEnd => _timeIntervalEnd;

  set timeIntervalEnabled(bool value) {
    _timeIntervalEnabled = value;
    notifyListeners();
  }

  set timeIntervalStart(int value) {
    _timeIntervalStart = value;
    notifyListeners();
  }

  set timeIntervalEnd(int value) {
    _timeIntervalEnd = value;
    notifyListeners();
  }

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

  set habitColor(Color? color) {
    _habitColor = color;
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

    _timeIntervalEnabled = false;
    _timeIntervalStart = 420;
    _timeIntervalEnd = 450;

    _habitColor = null;

    notifyListeners();
  }

  int get habitCategoryId => _habitCategoryId;

  int get habitAmount => _habitAmount;

  Duration get habitDuration => _habitDuration;

  String get iconPath => _iconPath;

  bool get isAdditional => _isAdditional;

  Color? get habitColor => _habitColor;
}
