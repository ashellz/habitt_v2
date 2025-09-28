import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/widgets/blur_circle_button.dart';
import 'package:habitt/widgets/habit_widget/completion_dialogs/enter_amount_slider.dart';
import 'package:provider/provider.dart';

class EnterAmountSliderDialog extends StatefulWidget {
  const EnterAmountSliderDialog({
    super.key,
    required this.habit,
    required this.day,
  });

  final Habit habit;
  final DateTime day;

  @override
  State<EnterAmountSliderDialog> createState() =>
      _EnterAmountSliderDialogState();
}

class _EnterAmountSliderDialogState extends State<EnterAmountSliderDialog> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final stateProvider = context.read<StateProvider>();
      stateProvider.habitAmount = widget.habit.amountCompleted;
    });
  }

  @override
  Widget build(BuildContext context) {
    final stateProvider = context.watch<StateProvider>();
    final colorProvider = context.watch<ColorProvider>();
    final habitProvider = context.read<HabitProvider>();

    return Dialog(
      backgroundColor:
          Colors.transparent, // Important for the blur to show through
      insetPadding: EdgeInsets.zero,
      child: IntrinsicWidth(
        child: IntrinsicHeight(
          child: Row(
            children: [
              SizedBox(width: 8 + 50),
              EnterAmountSlider(
                totalSegments: widget.habit.amount,
                filledSegments: stateProvider.habitAmount,
                onChanged: (newValue) {
                  stateProvider.habitAmount = newValue;
                  HapticFeedback.selectionClick();
                },
              ),
              SizedBox(width: 8),
              Column(
                children: [
                  CircleButton(
                    colorProvider: colorProvider,
                    icon: Icon(Icons.check, color: Colors.white),
                    color: colorProvider.colorScheme.darkerStandardColor,
                    onPressed: () {
                      if (widget.habit.amountCompleted ==
                          stateProvider.habitAmount) {
                        Navigator.pop(context);
                        return;
                      }

                      habitProvider.updateHabitAmountCompleted(
                        widget.habit.id,
                        stateProvider.habitAmount,
                        context,
                        day: widget.day,
                      );

                      Navigator.pop(context);
                    },
                  ),
                  SizedBox(height: 4),
                  CircleButton(
                    colorProvider: colorProvider,
                    icon: Icon(Icons.close, color: colorProvider.textColor),
                    color: colorProvider.colorScheme.standardColor,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
