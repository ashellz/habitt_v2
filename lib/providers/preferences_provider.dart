import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesProvider extends ChangeNotifier {
  bool _glassFeel = true;

  bool get glassFeel => _glassFeel;

  SharedPreferences? _prefs;

  PreferencesProvider(SharedPreferences prefs) {
    _prefs = prefs;
    init();
  }

  void init() {
    _glassFeel = _prefs?.getBool('glassFeel') ?? true;
    notifyListeners();
  }

  void toggleGlassFeel() {
    _glassFeel = !_glassFeel;
    _prefs?.setBool('glassFeel', _glassFeel);
    notifyListeners();
  }
}
