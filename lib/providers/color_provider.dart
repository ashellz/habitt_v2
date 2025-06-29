import 'package:flutter/material.dart';
import 'package:habitt/models/custom_color_scheme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ColorProvider extends ChangeNotifier {
  bool isDarkMode = false;
  String colorSchemeString = "blue";

  Color darkStandardColor = Color(0xFF212529);

  Color textColor = Color(0xFF212529);
  Color mutedTextColor = Color(0xFF6C757D);
  Color habitColor = Color.fromARGB(255, 218, 218, 218);
  Color iconBackgroundColor = Color(0xFFD9D9D9);
  Color backgroundColor = Color.fromARGB(255, 242, 242, 247);
  Color standardColor = Color(0xFFEDEDED);
  Color disabledColor = Color(0xFFF8F9FA);
  Color redAccent = Color.fromARGB(255, 240, 210, 210);

  Color red = Color.fromARGB(255, 215, 46, 46);

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
      standardColor = darkStandardColor;
      habitColor = Color(0xFF212529);
      disabledColor = Color.fromARGB(255, 28, 31, 35);
      mutedTextColor = Color.fromARGB(255, 150, 161, 171);
      redAccent = Color.fromARGB(255, 43, 28, 28);
    } else {
      textColor = Color(0xFF212529);
      habitColor = Color(0xFFEDEDED);
      iconBackgroundColor = Color(0xFFD9D9D9);
      backgroundColor = Color.fromARGB(255, 242, 242, 247);
      standardColor = Color(0xFFEDEDED);
      disabledColor = Color(0xFFF8F9FA);
      mutedTextColor = Color(0xFF6C757D);
      redAccent = Color.fromARGB(255, 240, 210, 210);
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
    disabledColor: Color(0xFFEAF2FB), // softer, airier blue
    standardColor: Color(0xFFD9E6F9), // light bluish mint
    strokeColor: Color(0xFF7AA6D9), // clearer sky blue
    vividColor: Color(0xFF0A75FF), // bolder and crisper blue
    darkerStandardColor: Color(0xFF0055CC), // deeper and more saturated
  );

  final CustomColorScheme _blueDark = CustomColorScheme(
    disabledColor: Color(0xFF1A2431),
    standardColor: Color(0xFF1F2C3A),
    strokeColor: Color(0xFF355773),
    vividColor: Color(0xFF409CFF), // comparable vibrancy to magenta
    darkerStandardColor: Color(0xFF0055CC),
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
    disabledColor: Color(0xFFE6FAF0), // softened like teal
    standardColor: Color(0xFFD1F7E6), // brighter mint green
    strokeColor: Color(0xFF7ABF9A), // cooler and clearer tone
    vividColor: Color.fromARGB(255, 0, 203, 115), // more vibrant green
    darkerStandardColor: Color(0xFF00A85B), // rich teal-leaning green
  );

  final CustomColorScheme _greenDark = CustomColorScheme(
    disabledColor: Color(0xFF132820), // darker but still green-tinted
    standardColor: Color(0xFF1B2F26),
    strokeColor: Color(0xFF355E4A), // like tealDark.strokeColor
    vividColor: Color(0xFF2EDF8F), // brighter vivid for contrast
    darkerStandardColor: Color(0xFF00A85B),
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
