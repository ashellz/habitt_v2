import 'package:flutter/material.dart';
import 'package:habitt/models/custom_color_scheme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ColorProvider extends ChangeNotifier {
  bool isDarkMode = false;
  late String colorSchemeString;
  List<Color> vividColors = [];

  Color darkStandardColor = Color(0xFF212529);

  Color textColor = Color(0xFF212529);
  Color mutedTextColor = Color(0xFF6C757D);
  Color habitColor = Color.fromARGB(255, 218, 218, 218);
  Color iconBackgroundColor = Color(0xFFD9D9D9);
  Color backgroundColor = Color.fromARGB(255, 242, 242, 247);
  Color standardColor = Colors.grey.shade300;
  Color disabledColor = Color(0xFFF8F9FA);
  Color redAccent = Color.fromARGB(255, 240, 210, 210);

  late CustomColorScheme blueColorScheme;
  late CustomColorScheme tealColorScheme;
  late CustomColorScheme greenColorScheme;
  late CustomColorScheme magentaColorScheme;
  late CustomColorScheme cherryColorScheme;

  List<CustomColorScheme> colorSchemes = [];
  final List<Color> lightVividColors = [
    // Oranges
    Color(0xFFFF6A00), // bright carrot
    // Yellows
    Color(0xFFFFD400), // lemon
    // Pinks
    Color(0xFFFF2DB8), // neon pink
    // Purples / Violets
    Color(0xFF7A00FF), // electric violet
    // Cyan / Aqua
    Color(0xFF00E5FF), // bright cyan
    // Teal (extra)
    Color(0xFF00BFA5), // punchy teal
    // Olive / Mustard
    Color(0xFFB58E00), // bold mustard
    // Brown / Amber
    Color(0xFFB45A00), // amber-brown vivid
    // Slate / Indigo
    Color(0xFF0033CC), // deep indigo vivid
    // Neutral Bright
    Color(0xFF4D4D4D), // strong neutral for emphasis
  ];

  final List<Color> darkVividColors = [
    // Oranges
    Color(0xFFFF8A42), // warm highlight for dark mode
    // Yellows
    Color(0xFFFFE86B), // luminous for dark backgrounds
    // Pinks
    Color(0xFFFF7ACF), // bright on dark
    // Purples / Violets
    Color(0xFFB66CFF), // luminous purple for dark
    // Cyan / Aqua
    Color(0xFF6FF3FF), // teal-cyan highlight
    // Teal (extra)
    Color(0xFF4FF0D9), // vivid teal for dark
    // Lime / Chartreuse
    Color(0xFFD9FF66), // soft bright on dark
    // Olive / Mustard
    Color(0xFFFFD87A), // warm highlight for dark
    // Brown / Amber
    Color(0xFFFFA84A), // warm accent on dark
    // Slate / Indigo
    Color(0xFF3366FF), // bright indigo for dark
    // Neutral Bright
    Color(0xFFBFBFBF), // light neutral on dark
  ];

  Color red = Color.fromARGB(255, 215, 46, 46);

  final SharedPreferences prefs;

  ColorProvider({required this.prefs}) {
    isDarkMode = prefs.getBool("isDarkMode") ?? true;
    colorSchemeString = prefs.getString("colorScheme") ?? "green";

    adaptModeColors();

    colorSchemes = [
      blueColorScheme,
      tealColorScheme,
      greenColorScheme,
      magentaColorScheme,
      cherryColorScheme,
    ];

    vividColors = [
      blueColorScheme.vividColor,
      tealColorScheme.vividColor,
      greenColorScheme.vividColor,
      magentaColorScheme.vividColor,
      cherryColorScheme.vividColor,
    ];
    if (isDarkMode) {
      vividColors.addAll(darkVividColors);
    } else {
      vividColors.addAll(lightVividColors);
    }

    changeColorScheme(colorSchemeString);
  }

  void changeMode() {
    isDarkMode = !isDarkMode;
    prefs.setBool("isDarkMode", isDarkMode);
    adaptModeColors();
    changeColorScheme(colorSchemeString);
    notifyListeners();
  }

  void adaptModeColors() {
    if (isDarkMode) {
      blueColorScheme = _blueDark;
      tealColorScheme = _tealDark;
      greenColorScheme = _greenDark;
      magentaColorScheme = _magentaDark;
      cherryColorScheme = _cherryDark;

      textColor = Color(0xFFF8F9FA);
      iconBackgroundColor = Color.fromARGB(255, 46, 50, 55);
      backgroundColor = Color.fromARGB(255, 18, 20, 22);
      standardColor = darkStandardColor;
      habitColor = Color(0xFF212529);
      disabledColor = Color.fromARGB(255, 28, 31, 35);
      mutedTextColor = Color.fromARGB(255, 150, 161, 171);
      redAccent = Color.fromARGB(255, 43, 28, 28);

      vividColors = [
        blueColorScheme.vividColor,
        tealColorScheme.vividColor,
        greenColorScheme.vividColor,
        magentaColorScheme.vividColor,
        cherryColorScheme.vividColor,
      ];
      vividColors.addAll(darkVividColors);
    } else {
      blueColorScheme = _blue;
      tealColorScheme = _teal;
      greenColorScheme = _green;
      magentaColorScheme = _magenta;
      cherryColorScheme = _cherry;

      textColor = Color(0xFF212529);
      habitColor = Color(0xFFEDEDED);
      iconBackgroundColor = Color(0xFFD9D9D9);
      backgroundColor = Color.fromARGB(255, 242, 242, 247);
      standardColor = Colors.grey.shade300;
      disabledColor = Color(0xFFF8F9FA);
      mutedTextColor = Color(0xFF6C757D);
      redAccent = Color.fromARGB(255, 240, 210, 210);

      vividColors = [
        blueColorScheme.vividColor,
        tealColorScheme.vividColor,
        greenColorScheme.vividColor,
        magentaColorScheme.vividColor,
        cherryColorScheme.vividColor,
      ];
      vividColors.addAll(lightVividColors);
    }

    colorSchemes = [
      blueColorScheme,
      tealColorScheme,
      greenColorScheme,
      magentaColorScheme,
      cherryColorScheme,
    ];

    notifyListeners();
  }

  void changeColorScheme(String colorSchemeName) {
    debugPrint("Changing color scheme to: $colorSchemeName");

    prefs.setString("colorScheme", colorSchemeName);
    colorSchemeString = colorSchemeName;

    colorScheme = colorSchemes.firstWhere(
      (scheme) => scheme.name == colorSchemeName,
      orElse: () => colorSchemes.first,
    );

    notifyListeners();
  }

  CustomColorScheme colorScheme = CustomColorScheme(
    name: "nan",
    disabledColor: Color(0xFFF8F9FA),
    standardColor: Color(0xFFEDEDED),
    strokeColor: Color(0xFF97A5B7),
    vividColor: Color(0xFF01377D),
    darkerStandardColor: Color(0xFF01377D),
  );

  final CustomColorScheme _blue = CustomColorScheme(
    name: "blue",
    disabledColor: Color(0xFFEAF2FB), // softer, airier blue
    standardColor: Color(0xFFD9E6F9), // light bluish mint
    strokeColor: Color(0xFF7AA6D9), // clearer sky blue
    vividColor: Color(0xFF0A75FF), // bolder and crisper blue
    darkerStandardColor: Color(0xFF0055CC), // deeper and more saturated
  );

  final CustomColorScheme _blueDark = CustomColorScheme(
    name: "blue",
    disabledColor: Color(0xFF1A2431),
    standardColor: Color(0xFF1F2C3A),
    strokeColor: Color(0xFF355773),
    vividColor: Color(0xFF409CFF), // comparable vibrancy to magenta
    darkerStandardColor: Color(0xFF0055CC),
  );

  final CustomColorScheme _teal = CustomColorScheme(
    name: "teal",
    disabledColor: Color(0xFFE6F9F8), // soft cyan
    standardColor: Color(0xFFD2F0F0), // light mint-teal
    strokeColor: Color(0xFF88C7C5), // cool teal-gray
    vividColor: Color(0xFF00CFC1), // bright aqua
    darkerStandardColor: Color(0xFF009B8E), // deeper teal
  );

  final CustomColorScheme _tealDark = CustomColorScheme(
    name: "teal",
    disabledColor: Color(0xFF122725), // dark sea green
    standardColor: Color(0xFF1C2B2A), // darkened background
    strokeColor: Color(0xFF33514F), // teal-gray border
    vividColor: Color(0xFF2ED7D7), // strong highlight
    darkerStandardColor: Color(0xFF009B8E), // deep vivid teal
  );
  final CustomColorScheme _green = CustomColorScheme(
    name: "green",
    disabledColor: Color(0xFFE6FAF0), // softened like teal
    standardColor: Color(0xFFd8f7da), // brighter mint green
    strokeColor: Color(0xFF7ABF9A), // cooler and clearer tone
    vividColor: Color.fromARGB(255, 0, 203, 115), // more vibrant green
    darkerStandardColor: Color(0xFF00A85B), // rich teal-leaning green
  );

  final CustomColorScheme _greenDark = CustomColorScheme(
    name: "green",
    disabledColor: Color(0xFF132820), // darker but still green-tinted
    standardColor: Color(0xFF1B2F26),
    strokeColor: Color(0xFF355E4A), // like tealDark.strokeColor
    vividColor: Color(0xFF2EDF8F), // brighter vivid for contrast
    darkerStandardColor: Color(0xFF00A85B),
  );

  final CustomColorScheme _magenta = CustomColorScheme(
    name: "magenta",
    disabledColor: Color(0xFFF4EAF7), // soft lilac
    standardColor: Color(0xFFF0E6F9), // gentle lavender
    strokeColor: Color(0xFFB088C4), // medium purple-gray
    vividColor: Color(0xFF8D2BA5), // rich magenta
    darkerStandardColor: Color(0xFF6B1F79), // deep violet
  );

  final CustomColorScheme _magentaDark = CustomColorScheme(
    name: "magenta",
    disabledColor: Color(0xFF2A1D2D), // muted dark lilac
    standardColor: Color(0xFF1F1A23), // dark background match
    strokeColor: Color(0xFF49374D), // grayish purple
    vividColor: Color(0xFFE38AFB), // bright highlight magenta
    darkerStandardColor: Color(0xFF6B1F79), // deep violet again
  );

  final CustomColorScheme _cherry = CustomColorScheme(
    name: "cherry",
    disabledColor: Color.fromARGB(255, 250, 237, 240),
    standardColor: Color.fromARGB(255, 251, 228, 233),
    strokeColor: Color.fromARGB(255, 192, 120, 133),
    vividColor: Color(0xFFD20A2E), // rich magenta
    darkerStandardColor: Color.fromARGB(255, 128, 12, 41), // deep violet
  );

  final CustomColorScheme _cherryDark = CustomColorScheme(
    name: "cherry",
    disabledColor: Color.fromARGB(255, 33, 25, 27),
    standardColor: Color.fromARGB(255, 46, 30, 34),
    strokeColor: Color.fromARGB(255, 86, 61, 66),
    vividColor: Color.fromARGB(255, 255, 103, 131),
    darkerStandardColor: Color.fromARGB(255, 118, 26, 49),
  );
}
