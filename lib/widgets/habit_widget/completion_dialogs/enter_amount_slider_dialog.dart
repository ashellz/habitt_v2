import 'dart:ui';

import 'package:cupertino_native/style/sf_symbol.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/providers/theme_provider.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/widgets/default/blur_circle_button.dart';
import 'package:habitt/widgets/habit_widget/completion_dialogs/enter_amount_slider.dart';
import 'package:provider/provider.dart';

void showAmountSliderDialog(BuildContext context, Habit habit, DateTime day) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Enter Amount',
    transitionDuration: const Duration(
      milliseconds: 150,
    ), // Your animation duration
    // This builder is for the content of the dialog.
    // We pass the simplified dialog widget here.
    pageBuilder: (context, animation, secondaryAnimation) {
      return EnterAmountSliderDialog(habit: habit, day: day);
    },

    // This builder is for the transition animation.
    // This is where we will build the BackdropFilter.
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      // The `animation` object here is an Animation<double> that goes from 0.0 to 1.0
      // over the course of the `transitionDuration`.

      // Animate the sigma value for the blur
      final double blurValue = animation.value * 4; // Max blur of 8

      // Animate the tint color's opacity
      final double tintOpacity = animation.value * 0.1; // Max opacity of 0.2

      return Stack(
        children: [
          // This BackdropFilter is now part of the transition,
          // so it correctly blurs the screen behind the route.
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blurValue, sigmaY: blurValue),
            child: Container(color: Colors.black.withOpacity(tintOpacity)),
          ),

          // Use a FadeTransition to fade in the dialog content itself.
          // The `child` here is the EnterAmountSliderDialog built by pageBuilder.
          FadeTransition(
            opacity: animation, // Use the same animation controller
            child: Center(child: child),
          ),
        ],
      );
    },
  );
}

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
    final tp = context.watch<ThemeProvider>();
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
                habitColor: widget.habit.resolveColor(tp),
                onChanged: (newValue) {
                  stateProvider.habitAmount = newValue;
                  HapticFeedback.selectionClick();
                },
              ),
              SizedBox(width: 8),
              Column(
                children: [
                  CircleButton(
                    cnIcon: CNSymbol('checkmark', size: 16),
                    tp: tp,
                    icon: Icon(Icons.check, color: Colors.white),
                    color: tp.primaryColor,
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
                    cnIcon: CNSymbol('xmark', size: 16),
                    tp: tp,
                    icon: Icon(Icons.close, color: tp.primaryTextColor),
                    color: tp.secondaryButtonBackground,
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
