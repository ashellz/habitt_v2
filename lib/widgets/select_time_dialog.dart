import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/widgets/blur_circle_button.dart';
import 'package:habitt/widgets/habit_widget/completion_dialogs/enter_amount_slider.dart';
import 'package:provider/provider.dart';

class SelectTimeDialog extends StatefulWidget {
  const SelectTimeDialog({super.key});

  @override
  State<SelectTimeDialog> createState() => _SelectTimeDialogState();
}

class _SelectTimeDialogState extends State<SelectTimeDialog> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final stateProvider = context.watch<StateProvider>();
    final colorProvider = context.watch<ColorProvider>();

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
                totalSegments: 5,
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
