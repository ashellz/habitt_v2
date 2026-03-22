import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/widgets/default/checkmark.dart';
import 'package:habitt/widgets/dialogs/log_progress_dialog.dart';
import 'package:provider/provider.dart';
import 'package:tinycolor2/tinycolor2.dart';

class NewHabitProgress extends StatefulWidget {
  const NewHabitProgress({super.key, required this.habit, this.focusedDay});

  final Habit habit;
  final DateTime? focusedDay;

  @override
  State<NewHabitProgress> createState() => _NewHabitProgressState();
}

class _NewHabitProgressState extends State<NewHabitProgress> {
  bool _hasAnimatedProgress = false;
  double _lastProgress = 0.0;

  double getProgressValue() {
    final habit = widget.habit;

    if (habit.completed || habit.skipped) return 1.0;

    if (habit.amount > 0) {
      // Habit tracked by amount
      if (habit.amount == 0) return 0.0; // Avoid divide by zero
      final progress = habit.amountCompleted / habit.amount;
      return progress.clamp(0.0, 1.0);
    }

    if (habit.duration > 0) {
      // Habit tracked by duration
      if (habit.duration == 0) return 0.0; // Avoid divide by zero
      final progress = habit.durationCompleted / habit.duration;
      return progress.clamp(0.0, 1.0);
    }

    return 0.0;
  }

  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    final habitProvider = context.watch<HabitProvider>();
    final stateProvider = context.read<StateProvider>();
    final cp = context.watch<ColorProvider>();

    return GestureDetector(
      onTap: () {
        setState(() {
          _scale = 0.9;
        });
        Future.delayed(const Duration(milliseconds: 150), () {
          setState(() {
            _scale = 1.0;
          });
        });

        // If no amount or duration, toggle completion
        if (widget.habit.amount == 0 && widget.habit.duration == 0) {
          habitProvider.completeHabit(
            widget.habit.id,
            context,
            stateProvider,
            day: widget.focusedDay,
          );
        } else {
          // Opens a dialog for selecting amount/duration completion
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            barrierColor: cp.greyText.darken().withOpacity(0.3),
            isScrollControlled: true,
            builder: (context) {
              return LogProgressDialog(
                progressType:
                    widget.habit.amount > 0
                        ? ProgressType.amount
                        : ProgressType.duration,
                habit: widget.habit,
              );
            },
          );
        }
      },
      onTapDown: (context) {
        HapticFeedback.selectionClick();
        setState(() {
          _scale = 0.9;
        });
      },
      onTapCancel: () {
        setState(() {
          _scale = 1.0;
        });
      },
      onTapUp: (context) {
        HapticFeedback.selectionClick();
        setState(() {
          _scale = 1.0;
        });
      },
      onLongPress: () {
        habitProvider.completeHabit(
          widget.habit.id,
          context,
          stateProvider,
          day: widget.focusedDay,
        );
      },
      child: Container(
        color: Colors.transparent,
        width: 32 + 24,
        height: 42,
        child: Center(
          child: AnimatedScale(
            scale: _scale,
            duration: const Duration(milliseconds: 150),
            child: SizedBox(
              width: 24,
              height: 24,
              child: Checkmark(value: widget.habit.completed),
            ),
          ),
        ),
      ),
    );
  }
}
