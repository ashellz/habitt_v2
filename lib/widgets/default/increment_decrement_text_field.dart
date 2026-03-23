import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/widgets/default/new_default_text_field.dart';
import 'package:provider/provider.dart';

class IncrementDecrementTextField extends StatelessWidget {
  const IncrementDecrementTextField({
    super.key,
    this.title,
    required this.controller,
    required this.onIncrement,
    required this.onDecrement,
    this.onIncrementLongPressStart,
    this.onIncrementLongPressEnd,
    this.onIncrementLongPressCancel,
    this.fontWeight = FontWeight.w500,
    this.minValue,
    this.maxValue,
    this.onValueChanged,
  });

  final String? title;
  final TextEditingController controller;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final GestureLongPressStartCallback? onIncrementLongPressStart;
  final GestureLongPressEndCallback? onIncrementLongPressEnd;
  final VoidCallback? onIncrementLongPressCancel;
  final FontWeight fontWeight;
  final int? minValue;
  final int? maxValue;
  final ValueChanged<int>? onValueChanged;

  void _onTextChanged(String value) {
    if (value.isEmpty) {
      return;
    }

    final parsed = int.tryParse(value);
    if (parsed == null) {
      return;
    }

    final lower = minValue ?? parsed;
    final upper = maxValue ?? parsed;
    final clamped = parsed.clamp(lower, upper).toInt();

    if (clamped != parsed) {
      final nextText = clamped.toString();
      controller.value = controller.value.copyWith(
        text: nextText,
        selection: TextSelection.collapsed(offset: nextText.length),
        composing: TextRange.empty,
      );
    }

    onValueChanged?.call(clamped);
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();

    return NewDefaultTextField(
      fontWeight: fontWeight,
      title: title,
      digitsOnly: true,
      centerValue: true,
      controller: controller,
      onChanged: _onTextChanged,
      prefix: GestureDetector(
        onTap: onDecrement,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12.0),
          child: SvgPicture.asset(
            "assets/images/new-svg/minus.svg",
            colorFilter: ColorFilter.mode(cp.text, BlendMode.srcIn),
          ),
        ),
      ),
      suffix: GestureDetector(
        onTap: onIncrement,
        onLongPressStart: onIncrementLongPressStart,
        onLongPressEnd: onIncrementLongPressEnd,
        onLongPressCancel: onIncrementLongPressCancel,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12.0),
          child: SvgPicture.asset(
            "assets/images/new-svg/plus.svg",
            colorFilter: ColorFilter.mode(cp.text, BlendMode.srcIn),
          ),
        ),
      ),
    );
  }
}
