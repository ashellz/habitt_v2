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
    isDarkMode = prefs.getBool("isDarkMode") ?? true;
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
      disabledColor = Color.fromARGB(255, 28, 31, 35);
    } else {
      textColor = Color(0xFF212529);
      habitColor = Color(0xFFEDEDED);
      iconBackgroundColor = Color(0xFFD9D9D9);
      backgroundColor = Color(0xFFF8F9FA);
      standardColor = Color(0xFFEDEDED);
      disabledColor = Color(0xFFF8F9FA);
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
      case "teal":
        if (isDarkMode) {
          colorScheme = _tealDark;
        } else {
          colorScheme = _teal;
        }
        colorSchemeString = "teal";
        break;
      case "green":
        if (isDarkMode) {
          colorScheme = _greenDark;
        } else {
          colorScheme = _green;
        }
        colorSchemeString = "green";
        break;
      case "magenta":
        if (isDarkMode) {
          colorScheme = _magentaDark;
        } else {
          colorScheme = _magenta;
        }
        colorSchemeString = "magenta";
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

  final CustomColorScheme _teal = CustomColorScheme(
    disabledColor: Color(0xFFE6F9F8), // soft cyan
    standardColor: Color(0xFFD2F0F0), // light mint-teal
    strokeColor: Color(0xFF88C7C5), // cool teal-gray
    vividColor: Color(0xFF00CFC1), // bright aqua
    darkerStandardColor: Color(0xFF009B8E), // deeper teal
  );

  final CustomColorScheme _tealDark = CustomColorScheme(
    disabledColor: Color(0xFF122725), // dark sea green
    standardColor: Color(0xFF1C2B2A), // darkened background
    strokeColor: Color(0xFF33514F), // teal-gray border
    vividColor: Color(0xFF2ED7D7), // strong highlight
    darkerStandardColor: Color(0xFF009B8E), // deep vivid teal
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

  final CustomColorScheme _magenta = CustomColorScheme(
    disabledColor: Color(0xFFF4EAF7), // soft lilac
    standardColor: Color(0xFFF0E6F9), // gentle lavender
    strokeColor: Color(0xFFB088C4), // medium purple-gray
    vividColor: Color(0xFF8D2BA5), // rich magenta
    darkerStandardColor: Color(0xFF6B1F79), // deep violet
  );

  final CustomColorScheme _magentaDark = CustomColorScheme(
    disabledColor: Color(0xFF2A1D2D), // muted dark lilac
    standardColor: Color(0xFF1F1A23), // dark background match
    strokeColor: Color(0xFF49374D), // grayish purple
    vividColor: Color(0xFFE38AFB), // bright highlight magenta
    darkerStandardColor: Color(0xFF6B1F79), // deep violet again
  );
}
