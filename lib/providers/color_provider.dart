import 'package:flutter/material.dart';
import 'package:habitt/models/custom_color_scheme.dart';

class ColorProvider extends ChangeNotifier {
  String colorSchemeString = "blue";
  Color textColor = Color(0xFF212529);
  Color mutedTextColor = Color(0xFF6C757D);
  Color habitColor = Color(0xFFEDEDED);
  Color iconBackgroundColor = Color(0xFFD9D9D9);
  Color backgroundColor = Color(0xFFF8F9FA);
  Color standardColor = Color(0xFFEDEDED);
  Color disabledColor = Color(0xFFF8F9FA);

  ColorProvider() {
    colorScheme = _blue;
    colorSchemeString = "blue";
  }

  void changeColorScheme(String color) {
    switch (color) {
      case "blue":
        colorScheme = _blue;
        colorSchemeString = "blue";
        break;
      case "green":
        colorScheme = _green;
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

  final CustomColorScheme _green = CustomColorScheme(
    disabledColor: Color(0xFFE9F7F1),
    standardColor: Color(0xFFDEF3EA),
    strokeColor: Color(0xFF97B7A5),
    vividColor: Color(0xFF26B170),
    darkerStandardColor: Color(0xFF1D8554),
  );
}
