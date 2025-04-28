import 'package:flutter/material.dart';
import 'package:flutter_spinbox/material.dart';
import 'package:habitt/providers/color_provider.dart';
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
    final colorProvider = context.watch<ColorProvider>();

    return SpinBox(
      textInputAction: TextInputAction.done,
      cursorColor: colorProvider.textColor,
      enableInteractiveSelection: true,

      iconColor: WidgetStateProperty.all<Color>(colorProvider.textColor),
      textStyle: TextStyle(color: colorProvider.textColor),
      decoration: InputDecoration(
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(20.0)),
        ),
        filled: true,
        fillColor: colorProvider.standardColor,
        labelStyle: TextStyle(
          fontSize: 16.0,
          fontWeight: FontWeight.bold,
          color: colorProvider.textColor,
        ),
        labelText: labelText,

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15.0),
          borderSide: BorderSide(color: colorProvider.colorScheme.strokeColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(20.0)),
          borderSide: BorderSide(color: colorProvider.colorScheme.strokeColor),
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
