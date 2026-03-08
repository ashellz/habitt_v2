import 'package:flutter/material.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/providers/preferences_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/providers/theme_provider.dart';
import 'package:habitt/widgets/default/glass_blur_container.dart';
import 'package:habitt/widgets/default/number_picker.dart';

class DurationCompletionDialogSlider extends StatelessWidget {
  const DurationCompletionDialogSlider({
    super.key,
    required this.width,
    required this.height,
    required this.tp,
    required this.colorfulness,
    required this.habit,
    required this.progressValue,
    required this.numberColor,
    required this.hours,
    required this.minutes,
    required this.sp,
    required this.hoursController,
    required this.minutesController,
  });

  final double width;
  final double height;
  final ThemeProvider tp;
  final Colorfulness colorfulness;
  final Habit habit;
  final double progressValue;
  final Color numberColor;
  final int hours;
  final int minutes;
  final StateProvider sp;
  final FixedExtentScrollController hoursController;
  final FixedExtentScrollController minutesController;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: tp.borderColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(30),
      ),
      width: width,
      height: height,
      child: Stack(
        children: [
          Positioned.fill(
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
              tween: Tween<double>(begin: 0, end: progressValue),
              builder: (context, value, _) {
                final endColor = habit.getCompletionColor(tp, colorfulness);

                return ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: Stack(
                    children: [
                      // Vertical fill from bottom up
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: FractionallySizedBox(
                          heightFactor: value,
                          widthFactor: 1,
                          child: Container(color: endColor),
                        ),
                      ),

                      GlassBlurContainer(
                        height: height,
                        forceBlur: true,
                        color: Colors.transparent,
                        borderColor: Colors.transparent,
                        hasGradient: false,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          Center(
            child: NumberPicker(
              padZero: false,
              height: height / 3,
              textStyle: TextStyle(
                shadows: [
                  Shadow(
                    color: Colors.black.withAlpha(100),
                    offset: const Offset(0, 1),
                    blurRadius: 5,
                  ),
                ],
                color: numberColor,
                fontWeight: FontWeight.bold,
                fontSize: 38,
                letterSpacing: 0,
              ),
              vertical: true,
              looping: false,
              maxHours: hours,
              maxMinutes: sp.habitDuration.inHours < hours ? 59 : minutes,
              hoursController: hoursController,
              minutesController: minutesController,
              width: width,
              onChangedHours: (int selectedHours) {
                final currentDuration = sp.habitDuration;
                sp.habitDuration = Duration(
                  hours: selectedHours,
                  minutes: currentDuration.inMinutes % 60,
                );
                // putting minutes to max if hours are maxed out
                if (selectedHours == hours) {
                  if (sp.habitDuration.inMinutes % 60 > minutes) {
                    sp.habitDuration = Duration(
                      hours: selectedHours,
                      minutes: minutes,
                    );
                  }
                }
              },
              onChangedMinutes: (int selectedMinutes) {
                final currentDuration = sp.habitDuration;
                sp.habitDuration = Duration(
                  hours: currentDuration.inHours,
                  minutes: selectedMinutes,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
