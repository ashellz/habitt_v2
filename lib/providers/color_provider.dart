import 'package:flutter/material.dart';
import 'package:habitt/services/color_service.dart';

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
      bg = Dark.bg;
      habitBg = Dark.habitsBg;
      text = Dark.text;
      glassButtonBg = Dark.black5;
      main = Dark.main;
      mid = Dark.mid;
      fail = Dark.fail;
      secondaryButton = Dark.secondaryButton;
      border = Dark.border;
      greyText = Dark.grayText;
      lightGreyText = Dark.lightGrayText;
      disabled = Dark.disabled;
      progressBarSelected = Dark.border;
      leftOrangeGraident = Dark.lightOrange;
      rightOrangeGradient = Dark.orange;
      orange = Colors.orange.withOpacity(0);
      orange100 = Dark.orange100;
      orange200 = Dark.orange200;
      orange300 = Dark.orange300;
      mainButtonLeftGradient = Dark.mainButtonLeftGradient;
      mainButtonRightGradient = Dark.mainButtonRightGradient;
      field = Dark.field;
      habitIconBg = Dark.border;
      widget = Dark.field;
      pill = Dark.field;
    } else {
      bg = Light.bg;
      habitBg = Light.habitsBg;
      glassButtonBg = Light.white5;
      text = Light.black;
      main = Light.main;
      mid = Light.mid;
      fail = Light.fail;
      secondaryButton = Light.secondaryButton;
      border = Light.border;
      greyText = Light.grayText;
      lightGreyText = Light.lightGrayText;
      disabled = Light.disabled;
      progressBarSelected = Light.darkGray;
      leftOrangeGraident = Light.lighterOrange;
      rightOrangeGradient = Light.lightOrange;
      orange = Light.orange;
      orange100 = Light.orange100;
      orange200 = Light.orange200;
      orange300 = Light.orange300;
      mainButtonLeftGradient = Light.mainButtonLeftGradient;
      mainButtonRightGradient = Light.mainButtonRightGradient;
      field = Light.field;
      habitIconBg = Light.white10;
      widget = Light.bg;
      pill = Light.black;
    }
  }
}
