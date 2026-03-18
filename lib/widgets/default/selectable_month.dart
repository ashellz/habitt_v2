import 'package:flutter/material.dart';
import 'package:habitt/services/new_color_service.dart';
import 'package:provider/provider.dart';

class SelectableMonth extends StatelessWidget {
  const SelectableMonth({
    super.key,
    required this.selectedDays,
    required this.onDaySelected,
    this.selectionDuration = const Duration(milliseconds: 200),
  });

  final Set<int> selectedDays;
  final ValueChanged<int> onDaySelected;
  final Duration selectionDuration;

  @override
  Widget build(BuildContext context) {
    const itemSize = 38.0;
    const verticalSpacing = 8.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalItemWidth = itemSize * 7;
        final remainingWidth = constraints.maxWidth - totalItemWidth;
        final horizontalSpacing = remainingWidth > 0 ? remainingWidth / 6 : 0.0;

        return SizedBox(
          height: (itemSize * 5) + (verticalSpacing * 4),
          child: Wrap(
            direction: Axis.horizontal,
            spacing: horizontalSpacing,
            runSpacing: verticalSpacing,
            children:
                List.generate(31, (index) => index + 1).map((day) {
                  return _SelectableMonthDayButton(
                    label: day.toString(),
                    isSelected: selectedDays.contains(day),
                    selectionDuration: selectionDuration,
                    onPressed: () => onDaySelected(day),
                  );
                }).toList(),
          ),
        );
      },
    );
  }
}

class _SelectableMonthDayButton extends StatelessWidget {
  const _SelectableMonthDayButton({
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
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected ? cp.main : cp.field,
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
              color: cp.text,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
