import 'dart:ui';
import 'package:cupertino_native/style/sf_symbol.dart';
import 'package:flutter/material.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/providers/preferences_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/providers/theme_provider.dart';
import 'package:habitt/widgets/default/circle_button.dart';
import 'package:habitt/widgets/habit_widget/progress_inputs/old/duration_completion_dialog_slider.dart';
import 'package:provider/provider.dart';
import 'package:tinycolor2/tinycolor2.dart';

void showDurationCompletionDialog(
  BuildContext context,
  Habit habit,
  DateTime day,
) {
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
      return DurationCompletionDialog(habit: habit, day: day);
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

class DurationCompletionDialog extends StatefulWidget {
  const DurationCompletionDialog({
    super.key,
    required this.habit,
    required this.day,
  });

  final Habit habit;
  final DateTime day;

  @override
  State<DurationCompletionDialog> createState() =>
      _DurationCompletionDialogState();
}

class _DurationCompletionDialogState extends State<DurationCompletionDialog> {
  FixedExtentScrollController hoursController = FixedExtentScrollController();
  FixedExtentScrollController minutesController = FixedExtentScrollController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Sets the initial amount or duration
      final stateProvider = context.read<StateProvider>();
      stateProvider.habitDuration = Duration(
        hours: widget.habit.durationCompleted ~/ 60,
        minutes: widget.habit.durationCompleted % 60,
      );
    });

    setState(() {
      hoursController = FixedExtentScrollController(
        initialItem: widget.habit.durationCompleted ~/ 60,
      );
      minutesController = FixedExtentScrollController(
        initialItem: widget.habit.durationCompleted % 60,
      );
    });
  }

  Color getColor() {
    final tp = context.read<ThemeProvider>();
    final prefs = context.read<PreferencesProvider>();
    switch (prefs.colorfulness) {
      case Colorfulness.tinted:
        return tp.primaryColor.darken(20).withOpacity(0.7);
      case Colorfulness.standard:
        return tp.successColor.darken(20).withOpacity(0.7);
      case Colorfulness.colorful:
        return widget.habit.resolveColor(tp)?.darken(20).withOpacity(0.7) ??
            tp.successColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    final sp = context.watch<StateProvider>();
    final colorfulness = context.read<PreferencesProvider>().colorfulness;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final width = screenWidth / 2.75;
    final height = screenHeight / 2.75;

    int minutes = widget.habit.duration % 60;
    int hours = widget.habit.duration ~/ 60;

    double getProgressValue() {
      if (widget.habit.duration == 0) return 0.0; // Avoid divide by zero
      final progress = sp.habitDuration.inMinutes / widget.habit.duration;
      return progress.clamp(0.0, 1.0);
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      backgroundColor:
          Colors.transparent, // Important for the blur to show through
      insetPadding: EdgeInsets.zero,
      child: IntrinsicWidth(
        child: IntrinsicHeight(
          child: Row(
            children: [
              SizedBox(width: 8 + 50),
              DurationCompletionDialogSlider(
                width: width,
                height: height,
                tp: tp,
                colorfulness: colorfulness,
                habit: widget.habit,
                progressValue: getProgressValue(),
                numberColor: getColor(),
                hours: hours,
                minutes: minutes,
                sp: sp,
                hoursController: hoursController,
                minutesController: minutesController,
              ),
              SizedBox(width: 8),
              Column(
                children: [
                  CircleButton(
                    cnIcon: CNSymbol('checkmark', size: 20),
                    tp: tp,
                    icon: Icon(Icons.check, color: Colors.white),
                    color: widget.habit.getCompletionColor(tp, colorfulness),
                    onPressed: () {
                      // If nothing changed then don't update unnecessarily
                      if (widget.habit.durationCompleted ==
                          sp.habitDuration.inMinutes) {
                        Navigator.pop(context);
                        return;
                      }

                      final habitProvider = context.read<HabitProvider>();
                      habitProvider.updateHabitDurationCompleted(
                        widget.habit.id,
                        sp.habitDuration.inMinutes,
                        context,
                      );

                      Navigator.pop(context);
                    },
                  ),
                  SizedBox(height: 4),
                  CircleButton(
                    cnIcon: CNSymbol('xmark', size: 20),
                    tp: tp,
                    icon: Icon(Icons.close, color: tp.primaryTextColor),
                    color: tp.surfaceColor,
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
