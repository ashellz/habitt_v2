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
  bool _glassFeel = true;
  bool _glassHabits = false;
  // colorful interface level
  Colorfulness _colorfulness = Colorfulness.standard;

  bool get glassFeel => _glassFeel;
  bool get glassHabits => _glassHabits;
  Colorfulness get colorfulness => _colorfulness;

  SharedPreferences? _prefs;

  PreferencesProvider(SharedPreferences prefs) {
    _prefs = prefs;
    init();
  }

  void init() {
    _glassFeel = _prefs?.getBool('glassFeel') ?? true;
    _glassHabits = _prefs?.getBool('glassHabits') ?? false;
    final stored = _prefs?.getString('colorfulness');
    _colorfulness = Colorfulness._parseColorfulness(stored);
    notifyListeners();
  }

  void toggleGlassFeel() {
    _glassFeel = !_glassFeel;
    _prefs?.setBool('glassFeel', _glassFeel);
    notifyListeners();
  }

  void toggleGlassHabits() {
    _glassHabits = !_glassHabits;
    _prefs?.setBool('glassHabits', _glassHabits);
    notifyListeners();
  }

  void setColorfulness(int index) {
    if (_colorfulness.index == index) return;
    _colorfulness = Colorfulness.values[index];
    _prefs?.setString('colorfulness', _colorfulness.name);
    notifyListeners();
  }
}
