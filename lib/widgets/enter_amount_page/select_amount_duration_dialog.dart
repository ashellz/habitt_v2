import 'package:flutter/material.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/widgets/custom_spinbox.dart';
import 'package:habitt/widgets/custom_text_field.dart';
import 'package:habitt/widgets/select_habit_type_widget.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
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
  final HabitType type;
  final TextEditingController habitAmountLabelController;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final stateProvider = context.watch<StateProvider>();

    return Dialog(
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: stateProvider.habitAmountLabelController,
        builder: (context, value, child) {
          return Container(
            padding: EdgeInsets.all(12),
            child:
                type == HabitType.amount
                    ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CustomSpinBox(
                          labelText: localizations.amount,
                          min: 2,
                          max: 9999,
                          value: wheelValue.toDouble(),
                          onChanged: onChangedAmount,
                        ),
                        CustomTextField(
                          textOnly: true,
                          maxTextLength: 15,
                          topPadding: 12,
                          title: localizations.label,
                          controller: habitAmountLabelController,
                        ),
                      ],
                    )
                    : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CustomSpinBox(
                          labelText: localizations.hours,
                          min: 0,
                          max: 23,
                          value: durationValue.inHours.toDouble(),
                          onChanged: onChangedHours,
                        ),
                        const SizedBox(height: 12),
                        CustomSpinBox(
                          labelText: localizations.minutes,
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
