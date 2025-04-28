import 'package:flutter/material.dart';
import 'package:habitt/models/custom_color_scheme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ColorProvider extends ChangeNotifier {
  bool isDarkMode = false;
  String colorSchemeString = "blue";
  Color textColor = Color(0xFF212529);
  Color mutedTextColor = Color(0xFF6C757D);
  Color habitColor = Color(0xFFEDEDED);
  Color iconBackgroundColor = Color(0xFFD9D9D9);
  Color backgroundColor = Color(0xFFF8F9FA);
  Color standardColor = Color(0xFFEDEDED);
  Color disabledColor = Color(0xFFF8F9FA);

  final SharedPreferences prefs;

  ColorProvider({required this.prefs}) {
    isDarkMode = prefs.getBool("isDarkMode") ?? false;
    colorSchemeString = prefs.getString("colorScheme") ?? "blue";
    changeColorScheme(colorSchemeString);
    adaptModeColors();
  }

  void changeMode() {
    isDarkMode = !isDarkMode;
    prefs.setBool("isDarkMode", isDarkMode);
    adaptModeColors();
    changeColorScheme(colorSchemeString);
  }

  void adaptModeColors() {
    if (isDarkMode) {
      textColor = Color(0xFFF8F9FA);
      iconBackgroundColor = Color.fromARGB(255, 46, 50, 55);
      backgroundColor = Color.fromARGB(255, 18, 20, 22);
      standardColor = Color(0xFF212529);
      habitColor = Color(0xFF212529);
    } else {
      textColor = Color(0xFF212529);
      habitColor = Color(0xFFEDEDED);
      iconBackgroundColor = Color(0xFFD9D9D9);
      backgroundColor = Color(0xFFF8F9FA);
      standardColor = Color(0xFFEDEDED);
    }
  }

  void changeColorScheme(String color) {
    prefs.setString("colorScheme", color);

    switch (color) {
      case "blue":
        if (isDarkMode) {
          colorScheme = _blueDark;
        } else {
          colorScheme = _blue;
        }
        colorSchemeString = "blue";
        break;
      case "green":
        if (isDarkMode) {
          colorScheme = _greenDark;
        } else {
          colorScheme = _green;
        }
        colorSchemeString = "green";
        break;
    }
    notifyListeners();
  }

  CustomColorScheme colorScheme = CustomColorScheme(
    disabledColor: Color(0xFFF8F9FA),
    standardColor: Color(0xFFEDEDED),
    strokeColor: Color(0xFF97A5B7),
    vividColor: Color(0xFF01377D),
    darkerStandardColor: Color(0xFF01377D),
  );

  final CustomColorScheme _blue = CustomColorScheme(
    disabledColor: Color(0xFFE6EBF2),
    standardColor: Color(0xFFE9EBF8),
    strokeColor: Color(0xFF97A5B7),
    vividColor: Color(0xFF01377D),
    darkerStandardColor: Color(0xFF01377D),
  );

  final CustomColorScheme _blueDark = CustomColorScheme(
    disabledColor: Color.fromARGB(255, 30, 33, 37),
    standardColor: Color.fromARGB(255, 31, 32, 33),
    strokeColor: Color.fromARGB(255, 55, 60, 66),
    vividColor: Color.fromARGB(255, 70, 123, 194),
    darkerStandardColor: Color(0xFF01377D),
  );

  final CustomColorScheme _green = CustomColorScheme(
    disabledColor: Color(0xFFE9F7F1),
    standardColor: Color(0xFFDEF3EA),
    strokeColor: Color(0xFF97B7A5),
    vividColor: Color(0xFF26B170),
    darkerStandardColor: Color(0xFF1D8554),
  );

  final CustomColorScheme _greenDark = CustomColorScheme(
    disabledColor: Color.fromARGB(255, 22, 27, 24),
    standardColor: Color.fromARGB(255, 30, 32, 31),
    strokeColor: Color.fromARGB(255, 55, 66, 59),
    vividColor: Color.fromARGB(255, 70, 194, 99),
    darkerStandardColor: Color(0xFF1D8554),
  );
}
