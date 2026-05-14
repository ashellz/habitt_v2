import 'package:flutter/material.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/providers/theme_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/widgets/default/default_spinbox.dart';
import 'package:habitt/widgets/default/default_text_field.dart';
import 'package:habitt/widgets/habit_details/select_habit_type_widget.dart';
import 'package:provider/provider.dart';

class SelectAmountDurationDialog extends StatelessWidget {
  const SelectAmountDurationDialog({
    super.key,
    required this.onChangedAmount,
    required this.wheelValue,
    required this.type,
    required this.durationValue,
    required this.onChangedHours,
    required this.onChangedMinutes,
    required this.habitAmountLabelController,
  });

  final ValueChanged<int> onChangedAmount;
  final ValueChanged<int> onChangedHours;
  final ValueChanged<int> onChangedMinutes;
  final int wheelValue;
  final Duration durationValue;
  final OldHabitType type;
  final TextEditingController habitAmountLabelController;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final stateProvider = context.watch<StateProvider>();
    final tp = context.watch<ThemeProvider>();

    return Dialog(
      backgroundColor: tp.backgroundColor,
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: stateProvider.habitAmountLabelController,
        builder: (context, value, child) {
          return Container(
            padding: EdgeInsets.all(12),
            child:
                type == OldHabitType.amount
                    ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CustomSpinBox(
                          labelText: loc.amount,
                          min: 2,
                          max: 9999,
                          value: wheelValue.toDouble(),
                          onChanged: onChangedAmount,
                        ),
                        DefaultTextField(
                          maxTextLength: 15,
                          topPadding: 12,
                          title: loc.label,
                          controller: habitAmountLabelController,
                        ),
                      ],
                    )
                    : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CustomSpinBox(
                          labelText: loc.hours,
                          min: 0,
                          max: 23,
                          value: durationValue.inHours.toDouble(),
                          onChanged: onChangedHours,
                        ),
                        const SizedBox(height: 12),
                        CustomSpinBox(
                          labelText: loc.minutes,
                          min: 0,
                          max: 59,
                          value: durationValue.inMinutes % 60,
                          onChanged: onChangedMinutes,
                        ),
                      ],
                    ),
          );
        },
      ),
    );
  }
}
