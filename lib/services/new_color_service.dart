import 'package:flutter/material.dart';

class NewColorService {
  static const _Light Light = _Light();
  static const _Dark Dark = _Dark();
}

class _Light {
  const _Light();

  static const Color bg = Color(0xFFFFFFFF);
  static const Color white5 = Color(0xFFFAFAFA);
  static const Color white10 = Color(0xFFF1F1F1);
  static const Color habitsBg = Color(0xFFF4F4F4);

  static const Color field = Color(0xFFF4F4F4);

  static const Color grayText = Color(0xFF7A7C81);
  static const Color lightGrayText = Color(0xFFA4A7AE);
  static const Color disabled = Color(0xFFDCDCDC);

  static const Color black = Color(0xFF0C0C0C); // text, pills
  static const Color darkGray = Color(0xFF343434);

  static const Color main = Color(0xFF02D382);
  static const Color mid = Color(0xFFFFB764);
  static const Color fail = Color(0xFFFF6464);

  static const Color mainButtonLeftGradient = Color(0xFF02D382);
  static const Color mainButtonRightGradient = Color(0xFF02C378);

  static const Color secondaryButton = Color(0xFFE2E3E6);
  static const Color border = Color(0xFFEDECEC);

  static const Color orange = Color(0xFFFF9831);
  static const Color lightOrange = Color(0xFFFFDFB1);
  static const Color lighterOrange = Color(0xFFFFF6DA);
  static const Color orange100 = Color(0xFFFFECCE);
  static const Color orange200 = Color(0xFFFED8A2);
  static const Color orange300 = Color(0xFFFF9700);
}

class _Dark {
  const _Dark();

  static const Color text = Color(0xFFFFFFFF);
  static const Color black5 = Color(0xFF151515);
  static const Color bg = Color(0xFF0C0C0C);
  static const Color habitsBg = Color(0xFF181818);

  static const Color field = Color(0xFF202020);

  static const Color grayText = Color(0xFF7A7C81);
  static const Color lightGrayText = Color(0xFF8C909E);
  static const Color disabled = Color(0xFF464646);

  static const Color main = Color(0xFF11F29B);
  static const Color mid = Color(0xFFFFB764);
  static const Color fail = Color(0xFFFF6464);

  static const Color mainButtonLeftGradient = Color(0xFF24FFAA);
  static const Color mainButtonRightGradient = Color(0xFF02E990);

  static const Color secondaryButton = Color(0xFF414347);
  static const Color border = Color(0xFF2F3030);

  static const Color orange = Color(0xFFF47200);
  static const Color lightOrange = Color(0xFFFFE07A);
  static const Color orange100 = Color(0xFF443725);
  static const Color orange200 = Color(0xFF7C5B2C);
  static const Color orange300 = Color(0xFFFFAF3C);
}

enum ColorMode { light, dark, system }

class ColorProvider extends ChangeNotifier {
  ColorMode _mode = ColorMode.system;

  ColorMode get mode => _mode;

  bool get isDark =>
      _mode == ColorMode.dark ||
      (_mode == ColorMode.system &&
          WidgetsBinding.instance.platformDispatcher.platformBrightness ==
              Brightness.dark);

  late Color bg;
  late Color habitBg;
  late Color text;
  late Color secondaryButton;
  late Color border;
  late Color fail;
  late Color mid;
  late Color main;
  late Color greyText;
  late Color lightGreyText;
  late Color disabled;
  late Color glassButtonBg;
  late Color progressBarSelected;
  late Color leftOrangeGraident;
  late Color rightOrangeGradient;
  late Color orange;
  late Color orange100;
  late Color orange200;
  late Color orange300;
  late Color mainButtonLeftGradient;
  late Color mainButtonRightGradient;
  late Color field;
  late Color habitIconBg;
  late Color widget;
  late Color pill;

  ColorProvider() {
    _updateColors();

    // Listen to system brightness changes
    WidgetsBinding
        .instance
        .platformDispatcher
        .onPlatformBrightnessChanged = () {
      if (_mode == ColorMode.system) {
        _mode =
            WidgetsBinding.instance.platformDispatcher.platformBrightness ==
                    Brightness.dark
                ? ColorMode.dark
                : ColorMode.light;
        isDark ? _mode = ColorMode.dark : _mode = ColorMode.light;
        _updateColors();
      }
    };
  }

  void setMode(ColorMode newMode) {
    _mode = newMode;
    _updateColors();
    notifyListeners();
  }

  void _updateColors() {
    if (isDark) {
      bg = _Dark.bg;
      habitBg = _Dark.habitsBg;
      text = _Dark.text;
      glassButtonBg = _Dark.black5;
      main = _Dark.main;
      mid = _Dark.mid;
      fail = _Dark.fail;
      secondaryButton = _Dark.secondaryButton;
      border = _Dark.border;
      greyText = _Dark.grayText;
      lightGreyText = _Dark.lightGrayText;
      disabled = _Dark.disabled;
      progressBarSelected = _Dark.border;
      leftOrangeGraident = _Dark.lightOrange;
      rightOrangeGradient = _Dark.orange;
      orange = Colors.orange.withOpacity(0);
      orange100 = _Dark.orange100;
      orange200 = _Dark.orange200;
      orange300 = _Dark.orange300;
      mainButtonLeftGradient = _Dark.mainButtonLeftGradient;
      mainButtonRightGradient = _Dark.mainButtonRightGradient;
      field = _Dark.field;
      habitIconBg = _Dark.border;
      widget = _Dark.field;
      pill = _Dark.field;
    } else {
      bg = _Light.bg;
      habitBg = _Light.habitsBg;
      glassButtonBg = _Light.white5;
      text = _Light.black;
      main = _Light.main;
      mid = _Light.mid;
      fail = _Light.fail;
      secondaryButton = _Light.secondaryButton;
      border = _Light.border;
      greyText = _Light.grayText;
      lightGreyText = _Light.lightGrayText;
      disabled = _Light.disabled;
      progressBarSelected = _Light.darkGray;
      leftOrangeGraident = _Light.lighterOrange;
      rightOrangeGradient = _Light.lightOrange;
      orange = _Light.orange;
      orange100 = _Light.orange100;
      orange200 = _Light.orange200;
      orange300 = _Light.orange300;
      mainButtonLeftGradient = _Light.mainButtonLeftGradient;
      mainButtonRightGradient = _Light.mainButtonRightGradient;
      field = _Light.field;
      habitIconBg = _Light.white10;
      widget = _Light.bg;
      pill = _Light.black;
    }
  }
}
