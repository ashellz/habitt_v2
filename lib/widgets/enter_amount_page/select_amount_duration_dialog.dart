import 'package:flutter/material.dart';
import 'package:habitt/widgets/custom_spinbox.dart';
import 'package:habitt/widgets/select_habit_type_widget.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SelectAmountDurationDialog extends StatelessWidget {
  const SelectAmountDurationDialog({
    super.key,
    required this.onChanged,
    required this.wheelValue,
    required this.type,
    required this.durationValue,
  });

  final ValueChanged<int> onChanged;
  final int wheelValue;
  final Duration durationValue;
  final HabitType type;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Dialog(
      child: Container(
        padding: EdgeInsets.all(12),
        child:
            type == HabitType.amount
                ? CustomSpinBox(
                  labelText: localizations.amount,
                  min: 2,
                  max: 9999,
                  value: wheelValue.toDouble(),
                  onChanged: onChanged,
                )
                : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomSpinBox(
                      labelText: localizations.hours,
                      min: 0,
                      max: 23,
                      value: durationValue.inHours.toDouble(),
                      onChanged: onChanged,
                    ),
                    const SizedBox(height: 12),
                    CustomSpinBox(
                      labelText: localizations.minutes,
                      min: 0,
                      max: 59,

                      value: durationValue.inMinutes % 60,
                      onChanged: onChanged,
                    ),
                  ],
                ),
      ),
    );
  }
}
