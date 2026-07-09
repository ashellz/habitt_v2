import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum Colorfulness {
  tinted,
  standard,
  colorful;

  // get name for storage
  String get name {
    switch (this) {
      case Colorfulness.tinted:
        return 'tinted';
      case Colorfulness.standard:
        return 'standard';
      case Colorfulness.colorful:
        return 'colorful';
    }
  }

  // parse from string
  static Colorfulness _parseColorfulness(String? s) {
    switch (s) {
      case 'tinted':
        return Colorfulness.tinted;
      case 'colorful':
        return Colorfulness.colorful;
      case 'standard':
      default:
        return Colorfulness.standard;
    }
  }
}

class PreferencesProvider extends ChangeNotifier {
  static const String _kShowUploadActivityKey = 'show_upload_activity';
  static const String _kShowStreakCelebrationKey = 'show_streak_celebration';
  static const String _kShowCategoriesOnMainPageKey =
      'show_categories_on_main_page';
  static const String _kHasSelectedPastDayKey = 'has_selected_past_day';

  bool _glassFeel = true;
  // colorful interface level
  Colorfulness _colorfulness = Colorfulness.standard;
  bool _americanTimeFormat = false;
  bool _showUploadActivity = true;
  bool _showStreakCelebration = true;
  bool _showCategoriesOnMainPage = false;
  bool _hasSelectedPastDay = false;

  bool get glassFeel => _glassFeel;
  Colorfulness get colorfulness => _colorfulness;
  bool get americanTimeFormat => _americanTimeFormat;
  bool get showUploadActivity => _showUploadActivity;
  bool get showStreakCelebration => _showStreakCelebration;
  bool get showCategoriesOnMainPage => _showCategoriesOnMainPage;
  bool get hasSelectedPastDay => _hasSelectedPastDay;

  SharedPreferences? _prefs;

  PreferencesProvider(SharedPreferences prefs) {
    _prefs = prefs;
    init();
  }

  void init() {
    _glassFeel = _prefs?.getBool('glassFeel') ?? true;
    _americanTimeFormat = _prefs?.getBool('americanTimeFormat') ?? false;
    _showUploadActivity = _prefs?.getBool(_kShowUploadActivityKey) ?? true;
    _showStreakCelebration =
        _prefs?.getBool(_kShowStreakCelebrationKey) ?? true;
    _showCategoriesOnMainPage =
        _prefs?.getBool(_kShowCategoriesOnMainPageKey) ?? false;
    _hasSelectedPastDay = _prefs?.getBool(_kHasSelectedPastDayKey) ?? false;
    final stored = _prefs?.getString('colorfulness');
    _colorfulness = Colorfulness._parseColorfulness(stored);
    notifyListeners();
  }

  void toggleAmericanTimeFormat() {
    _americanTimeFormat = !_americanTimeFormat;
    _prefs?.setBool('americanTimeFormat', _americanTimeFormat);
    notifyListeners();
  }

  void toggleGlassFeel() {
    _glassFeel = !_glassFeel;
    _prefs?.setBool('glassFeel', _glassFeel);
    notifyListeners();
  }

  void setColorfulness(int index) {
    if (_colorfulness.index == index) return;
    _colorfulness = Colorfulness.values[index];
    _prefs?.setString('colorfulness', _colorfulness.name);
    notifyListeners();
  }

  void setShowUploadActivity(bool value) {
    _showUploadActivity = value;
    _prefs?.setBool(_kShowUploadActivityKey, value);
    notifyListeners();
  }

  void setShowStreakCelebration(bool value) {
    _showStreakCelebration = value;
    _prefs?.setBool(_kShowStreakCelebrationKey, value);
    notifyListeners();
  }

  void setShowCategoriesOnMainPage(bool value) {
    _showCategoriesOnMainPage = value;
    _prefs?.setBool(_kShowCategoriesOnMainPageKey, value);
    notifyListeners();
  }

  void setHasSelectedPastDay(bool value) {
    if (_hasSelectedPastDay == value) return;
    _hasSelectedPastDay = value;
    _prefs?.setBool(_kHasSelectedPastDayKey, value);
    notifyListeners();
  }
}
