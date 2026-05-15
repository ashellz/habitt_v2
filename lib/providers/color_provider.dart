import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:habitt/services/color_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ColorMode { light, dark, system }

@immutable
class _ColSet {
  final Color bg,
      habitBg,
      text,
      secondaryButton,
      border,
      fail,
      mid,
      main,
      greyText,
      lightGreyText,
      disabled,
      glassButtonBg,
      progressBarSelected,
      leftOrangeGraident,
      rightOrangeGradient,
      orange,
      orange100,
      orange200,
      orange300,
      mainButtonLeftGradient,
      mainButtonRightGradient,
      field,
      habitIconBg,
      widgetColor,
      pill,
      error;

  const _ColSet({
    required this.bg,
    required this.habitBg,
    required this.text,
    required this.secondaryButton,
    required this.border,
    required this.fail,
    required this.mid,
    required this.main,
    required this.greyText,
    required this.lightGreyText,
    required this.disabled,
    required this.glassButtonBg,
    required this.progressBarSelected,
    required this.leftOrangeGraident,
    required this.rightOrangeGradient,
    required this.orange,
    required this.orange100,
    required this.orange200,
    required this.orange300,
    required this.mainButtonLeftGradient,
    required this.mainButtonRightGradient,
    required this.field,
    required this.habitIconBg,
    required this.widgetColor,
    required this.pill,
    required this.error,
  });

  static _ColSet lerp(_ColSet a, _ColSet b, double t) => _ColSet(
    bg: Color.lerp(a.bg, b.bg, t)!,
    habitBg: Color.lerp(a.habitBg, b.habitBg, t)!,
    text: Color.lerp(a.text, b.text, t)!,
    secondaryButton: Color.lerp(a.secondaryButton, b.secondaryButton, t)!,
    border: Color.lerp(a.border, b.border, t)!,
    fail: Color.lerp(a.fail, b.fail, t)!,
    mid: Color.lerp(a.mid, b.mid, t)!,
    main: Color.lerp(a.main, b.main, t)!,
    greyText: Color.lerp(a.greyText, b.greyText, t)!,
    lightGreyText: Color.lerp(a.lightGreyText, b.lightGreyText, t)!,
    disabled: Color.lerp(a.disabled, b.disabled, t)!,
    glassButtonBg: Color.lerp(a.glassButtonBg, b.glassButtonBg, t)!,
    progressBarSelected: Color.lerp(
      a.progressBarSelected,
      b.progressBarSelected,
      t,
    )!,
    leftOrangeGraident: Color.lerp(
      a.leftOrangeGraident,
      b.leftOrangeGraident,
      t,
    )!,
    rightOrangeGradient: Color.lerp(
      a.rightOrangeGradient,
      b.rightOrangeGradient,
      t,
    )!,
    orange: Color.lerp(a.orange, b.orange, t)!,
    orange100: Color.lerp(a.orange100, b.orange100, t)!,
    orange200: Color.lerp(a.orange200, b.orange200, t)!,
    orange300: Color.lerp(a.orange300, b.orange300, t)!,
    mainButtonLeftGradient: Color.lerp(
      a.mainButtonLeftGradient,
      b.mainButtonLeftGradient,
      t,
    )!,
    mainButtonRightGradient: Color.lerp(
      a.mainButtonRightGradient,
      b.mainButtonRightGradient,
      t,
    )!,
    field: Color.lerp(a.field, b.field, t)!,
    habitIconBg: Color.lerp(a.habitIconBg, b.habitIconBg, t)!,
    widgetColor: Color.lerp(a.widgetColor, b.widgetColor, t)!,
    pill: Color.lerp(a.pill, b.pill, t)!,
    error: Color.lerp(a.error, b.error, t)!,
  );
}

class ColorProvider extends ChangeNotifier {
  SharedPreferences prefs;

  ColorMode _mode = ColorMode.system;
  VoidCallback? _previousBrightnessCallback;

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
  // ignore: avoid_field_initializers_in_const_classes
  late Color widget;
  late Color pill;
  late Color error;

  // Animation state
  _ColSet? _animFrom;
  _ColSet? _animTo;
  Ticker? _ticker;
  static const _kAnimDuration = Duration(milliseconds: 200);

  _getModeFromPrefs(SharedPreferences prefs) {
    String? modeString = prefs.getString('color_mode');
    if (modeString != null) {
      return ColorMode.values.firstWhere(
        (e) => e.toString() == modeString,
        orElse: () => ColorMode.system,
      );
    }
    return ColorMode.system;
  }

  Future<void> initFromPrefs() async {
    _mode = _getModeFromPrefs(prefs);
    _applyColSet(_colsForDark(isDark));
    notifyListeners();
  }

  ColorProvider(this.prefs) {
    initFromPrefs();

    _previousBrightnessCallback =
        WidgetsBinding.instance.platformDispatcher.onPlatformBrightnessChanged;
    WidgetsBinding.instance.platformDispatcher.onPlatformBrightnessChanged =
        () {
          _previousBrightnessCallback?.call();
          if (_mode == ColorMode.system) {
            _startTransition();
          }
        };
  }

  void setMode(ColorMode newMode) {
    _mode = newMode;
    prefs.setString('color_mode', newMode.toString());
    _startTransition();
  }

  void _startTransition() {
    final from = _snapshot();
    final to = _colsForDark(isDark);

    _ticker?.stop();
    _ticker?.dispose();

    _animFrom = from;
    _animTo = to;
    _ticker = Ticker(_onTick);
    _ticker!.start();
  }

  void _onTick(Duration elapsed) {
    final raw =
        elapsed.inMilliseconds / _kAnimDuration.inMilliseconds;
    final t = raw.clamp(0.0, 1.0);
    final curved = Curves.easeInOut.transform(t);

    _applyColSet(_ColSet.lerp(_animFrom!, _animTo!, curved));
    notifyListeners();

    if (t >= 1.0) {
      _ticker!.stop();
      _ticker!.dispose();
      _ticker = null;
      _animFrom = null;
      _animTo = null;
    }
  }

  _ColSet _colsForDark(bool dark) {
    if (dark) {
      return const _ColSet(
        bg: Dark.bg,
        habitBg: Dark.habitsBg,
        text: Dark.text,
        glassButtonBg: Dark.black5,
        main: Dark.main,
        mid: Dark.mid,
        fail: Dark.fail,
        secondaryButton: Dark.secondaryButton,
        border: Dark.border,
        greyText: Dark.grayText,
        lightGreyText: Dark.lightGrayText,
        disabled: Dark.disabled,
        progressBarSelected: Dark.border,
        leftOrangeGraident: Dark.lightOrange,
        rightOrangeGradient: Dark.orange,
        orange: Color(0x00FFA500), // Colors.orange.withOpacity(0)
        orange100: Dark.orange100,
        orange200: Dark.orange200,
        orange300: Dark.orange300,
        mainButtonLeftGradient: Dark.mainButtonLeftGradient,
        mainButtonRightGradient: Dark.mainButtonRightGradient,
        field: Dark.field,
        habitIconBg: Dark.border,
        widgetColor: Dark.field,
        pill: Dark.field,
        error: Dark.error,
      );
    } else {
      return const _ColSet(
        bg: Light.bg,
        habitBg: Light.habitsBg,
        glassButtonBg: Light.white5,
        text: Light.black,
        main: Light.main,
        mid: Light.mid,
        fail: Light.fail,
        secondaryButton: Light.secondaryButton,
        border: Light.border,
        greyText: Light.grayText,
        lightGreyText: Light.lightGrayText,
        disabled: Light.disabled,
        progressBarSelected: Light.darkGray,
        leftOrangeGraident: Light.lighterOrange,
        rightOrangeGradient: Light.lightOrange,
        orange: Light.orange,
        orange100: Light.orange100,
        orange200: Light.orange200,
        orange300: Light.orange300,
        mainButtonLeftGradient: Light.mainButtonLeftGradient,
        mainButtonRightGradient: Light.mainButtonRightGradient,
        field: Light.field,
        habitIconBg: Light.white10,
        widgetColor: Light.bg,
        pill: Light.black,
        error: Light.error,
      );
    }
  }

  void _applyColSet(_ColSet s) {
    bg = s.bg;
    habitBg = s.habitBg;
    text = s.text;
    secondaryButton = s.secondaryButton;
    border = s.border;
    fail = s.fail;
    mid = s.mid;
    main = s.main;
    greyText = s.greyText;
    lightGreyText = s.lightGreyText;
    disabled = s.disabled;
    glassButtonBg = s.glassButtonBg;
    progressBarSelected = s.progressBarSelected;
    leftOrangeGraident = s.leftOrangeGraident;
    rightOrangeGradient = s.rightOrangeGradient;
    orange = s.orange;
    orange100 = s.orange100;
    orange200 = s.orange200;
    orange300 = s.orange300;
    mainButtonLeftGradient = s.mainButtonLeftGradient;
    mainButtonRightGradient = s.mainButtonRightGradient;
    field = s.field;
    habitIconBg = s.habitIconBg;
    widget = s.widgetColor;
    pill = s.pill;
    error = s.error;
  }

  _ColSet _snapshot() => _ColSet(
    bg: bg,
    habitBg: habitBg,
    text: text,
    secondaryButton: secondaryButton,
    border: border,
    fail: fail,
    mid: mid,
    main: main,
    greyText: greyText,
    lightGreyText: lightGreyText,
    disabled: disabled,
    glassButtonBg: glassButtonBg,
    progressBarSelected: progressBarSelected,
    leftOrangeGraident: leftOrangeGraident,
    rightOrangeGradient: rightOrangeGradient,
    orange: orange,
    orange100: orange100,
    orange200: orange200,
    orange300: orange300,
    mainButtonLeftGradient: mainButtonLeftGradient,
    mainButtonRightGradient: mainButtonRightGradient,
    field: field,
    habitIconBg: habitIconBg,
    widgetColor: widget,
    pill: pill,
    error: error,
  );

  @override
  void dispose() {
    _ticker?.stop();
    _ticker?.dispose();
    WidgetsBinding.instance.platformDispatcher.onPlatformBrightnessChanged =
        _previousBrightnessCallback;
    super.dispose();
  }
}
