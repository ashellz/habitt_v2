import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesProvider extends ChangeNotifier {
  bool _glassFeel = true;
  bool _glassHabits = false;

  bool get glassFeel => _glassFeel;
  bool get glassHabits => _glassHabits;

  SharedPreferences? _prefs;

  PreferencesProvider(SharedPreferences prefs) {
    _prefs = prefs;
    init();
  }

  void init() {
    _glassFeel = _prefs?.getBool('glassFeel') ?? true;
    _glassHabits = _prefs?.getBool('glassHabits') ?? false;
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
}
