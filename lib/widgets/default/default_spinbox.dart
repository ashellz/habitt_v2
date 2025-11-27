import 'package:flutter/material.dart';
import 'package:flutter_spinbox/material.dart';
import 'package:habitt/providers/theme_provider.dart';
import 'package:provider/provider.dart';

class CustomSpinBox extends StatelessWidget {
  const CustomSpinBox({
    super.key,
    required this.labelText,
    required this.min,
    required this.max,
    required this.value,
    required this.onChanged,
  });

  final String labelText;
  final double min;
  final double max;
  final double value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();

    return SpinBox(
      textInputAction: TextInputAction.done,
      cursorColor: tp.primaryTextColor,
      enableInteractiveSelection: true,
      keyboardAppearance: tp.isDark ? Brightness.dark : Brightness.light,
      iconColor: WidgetStateProperty.all<Color>(tp.primaryTextColor),
      textStyle: TextStyle(color: tp.primaryTextColor),
      decoration: InputDecoration(
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(20.0)),
        ),
        filled: true,
        fillColor: tp.surfaceColor,
        labelStyle: TextStyle(
          fontSize: 16.0,
          fontWeight: FontWeight.bold,
          color: tp.primaryTextColor,
        ),
        labelText: labelText,

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15.0),
          borderSide: BorderSide(color: tp.primaryButtonBackground),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(20.0)),
          borderSide: BorderSide(color: tp.primaryButtonBackground),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 20,
          horizontal: 20,
        ),
      ),
      min: min,
      max: max,
      value: value,
      onChanged: (value) => onChanged(value.toInt()),
    );
  }
}
