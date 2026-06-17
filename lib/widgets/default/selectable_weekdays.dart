import 'package:flutter/material.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:provider/provider.dart';

class SelectableWeekdays extends StatelessWidget {
  const SelectableWeekdays({
    super.key,
    this.isNotification = false,
    required this.selectedDays,
    required this.onDaySelected,
    this.disabledDays = const {},
    this.selectionDuration = const Duration(milliseconds: 200),
  });

  static List<String> _weekDays(AppLocalizations loc) => [
    loc.mon,
    loc.tue,
    loc.wed,
    loc.thu,
    loc.fri,
    loc.sat,
    loc.sun,
  ];

  final Set<String> selectedDays;
  final ValueChanged<String> onDaySelected;
  final Set<String> disabledDays;
  final Duration selectionDuration;
  final bool isNotification;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children:
          _weekDays(loc).map((day) {
            final isDisabled = disabledDays.contains(day);
            return _SelectableWeekDayButton(
              label: day,
              isNotification: isNotification,
              isSelected: selectedDays.contains(day),
              isDisabled: isDisabled,
              selectionDuration: selectionDuration,
              onPressed: isDisabled ? null : () => onDaySelected(day),
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
    this.isDisabled = false,
    this.isNotification = false,
  });

  final String label;
  final bool isSelected;
  final bool isDisabled;
  final Duration selectionDuration;
  final VoidCallback? onPressed;
  final bool isNotification;

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final isAndroid = Theme.of(context).platform == TargetPlatform.android;

    return Opacity(
      opacity: isDisabled ? 0.4 : 1.0,
      child: AnimatedContainer(
        duration: selectionDuration,
        curve: Curves.easeOut,
        width: isNotification ? 40 : 36,
        height: isNotification ? 40 : 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected ? cp.text : Colors.transparent,
          border: Border.all(
            width: 1,
            color: isSelected ? cp.text : cp.disabled,
          ),
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
      ),
    );
  }
}
