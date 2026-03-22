import 'package:flutter/material.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:provider/provider.dart';

class SelectableWeekdays extends StatelessWidget {
  const SelectableWeekdays({
    super.key,
    required this.selectedDays,
    required this.onDaySelected,
    this.selectionDuration = const Duration(milliseconds: 200),
  });

  static const List<String> _weekDays = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  final Set<String> selectedDays;
  final ValueChanged<String> onDaySelected;
  final Duration selectionDuration;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children:
          _weekDays.map((day) {
            return _SelectableWeekDayButton(
              label: day,
              isSelected: selectedDays.contains(day),
              selectionDuration: selectionDuration,
              onPressed: () => onDaySelected(day),
            );
          }).toList(),
    );
  }
}

class _SelectableWeekDayButton extends StatelessWidget {
  const _SelectableWeekDayButton({
    required this.label,
    required this.isSelected,
    required this.selectionDuration,
    required this.onPressed,
  });

  final String label;
  final bool isSelected;
  final Duration selectionDuration;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final isAndroid = Theme.of(context).platform == TargetPlatform.android;

    return AnimatedContainer(
      duration: selectionDuration,
      curve: Curves.easeOut,
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected ? cp.text : Colors.transparent,
        border: Border.all(width: 1, color: isSelected ? cp.text : cp.disabled),
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ButtonStyle(
          splashFactory: isAndroid ? null : NoSplash.splashFactory,
          elevation: const WidgetStatePropertyAll(0),
          overlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
            if (!states.contains(WidgetState.pressed)) {
              return null;
            }

            if (isAndroid) {
              return null;
            }

            return cp.bg.withValues(alpha: 0.2);
          }),
          backgroundColor: const WidgetStatePropertyAll(Colors.transparent),
          shadowColor: const WidgetStatePropertyAll(Colors.transparent),
          shape: const WidgetStatePropertyAll(CircleBorder()),
          padding: const WidgetStatePropertyAll(EdgeInsets.zero),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? cp.bg : cp.text,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
