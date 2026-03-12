import 'package:flutter/material.dart';
import 'package:habitt/models/schedule_option_type.dart';
import 'package:habitt/providers/theme_provider.dart';
import 'package:habitt/services/color_service.dart';
import 'package:habitt/services/emoji_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tinycolor2/tinycolor2.dart';

class StateProvider extends ChangeNotifier {
  SharedPreferences? _prefs;
  bool _shouldUpdateStreaks = false;

  StateProvider(SharedPreferences prefs) {
    _prefs = prefs;
    init();
  }

  void init() {
    _shouldUpdateStreaks = _prefs?.getBool('shouldUpdateStreaks') ?? false;
    notifyListeners();
  }

  bool _showAllHabits = true;

  bool get showAllHabits => _showAllHabits;

  void toggleShowAllHabits() {
    _showAllHabits = !_showAllHabits;
    notifyListeners();
  }

  int _selectedHabitId = -1;

  int _habitCategoryId = 1;
  int _habitAmount = 0;
  Duration _habitDuration = Duration.zero;
  TextEditingController habitAmountLabelController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  TextEditingController descController = TextEditingController();
  String _iconPath = "";
  bool _isOptional = false;
  Color? _habitColor;
  String? _habitColorName;
  ScheduleOptionType _selectedScheduleOption = ScheduleOptionType.daily;

  String _alertText = "";
  bool _showAlert = false;

  String get alertText => _alertText;
  bool get showAlert => _showAlert;
  ScheduleOptionType get selectedScheduleOption => _selectedScheduleOption;

  set selectedScheduleOption(ScheduleOptionType option) {
    _selectedScheduleOption = option;
    notifyListeners();
  }

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

  bool get shouldUpdateStreaks => _shouldUpdateStreaks;

  set shouldUpdateStreaks(bool value) {
    _shouldUpdateStreaks = value;
    _prefs?.setBool('shouldUpdateStreaks', value);
    notifyListeners();
  }

  toggleOptional() {
    _isOptional = !_isOptional;
    notifyListeners();
  }

  set isOptional(bool value) {
    _isOptional = value;
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

  set selectedHabitId(int id) {
    _selectedHabitId = id;
    notifyListeners();
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

  Color? get habitColor => _habitColor;

  set habitColorName(String? value) {
    _habitColorName = value;
    notifyListeners();
  }

  void reset() {
    _selectedHabitId = -1;
    _habitAmount = 0;
    _showAllHabits = true;

    _habitDuration = Duration.zero;

    _habitCategoryId = 1;
    habitAmountLabelController.clear();
    nameController.clear();
    descController.clear();
    _iconPath = EmojiService.defaultEmoji;
    _isOptional = false;

    _timeIntervalEnabled = false;
    _timeIntervalStart = 420;
    _timeIntervalEnd = 450;

    _habitColor = null;
    _habitColorName = null;
    _selectedScheduleOption = ScheduleOptionType.daily;

    notifyListeners();
  }

  int get selectedHabitId => _selectedHabitId;

  int get habitCategoryId => _habitCategoryId;

  int get habitAmount => _habitAmount;

  Duration get habitDuration => _habitDuration;

  String get iconPath => _iconPath;

  bool get isOptional => _isOptional;

  Color? getHabitColor(ThemeProvider tp) {
    if (_habitColorName != null) {
      final spec = ColorService.habitColorSpecs[_habitColorName!];
      if (spec != null) {
        return tp.isDark ? spec.dark : spec.light;
      }
    }
    return null;
  }

  Color? getHabitTextColor(ThemeProvider tp) {
    if (_habitColorName != null) {
      final spec = ColorService.habitColorSpecs[_habitColorName!];
      if (spec != null) {
        return tp.isDark ? spec.darkText : spec.lightText;
      }
    }
    if (_habitColor != null) {
      // provide minimal contrast by flipping toward darker tone for text
      return tp.isDark ? _habitColor!.lighten(35) : _habitColor!.darken(35);
    }
    return null;
  }

  String? get habitColorName => _habitColorName;
}
