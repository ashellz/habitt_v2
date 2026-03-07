import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/services/new_color_service.dart';
import 'package:habitt/widgets/default/checkmark.dart';
import 'package:habitt/widgets/default/new_default_button.dart';
import 'package:habitt/widgets/habit_widget/completion_dialogs/duration_completion_dialog.dart';
import 'package:habitt/widgets/habit_widget/completion_dialogs/enter_amount_slider_dialog.dart';
import 'package:provider/provider.dart';

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
        if (widget.habit.amount == 0 && widget.habit.duration == 0 ||
            widget.habit.completed ||
            widget.habit.skipped) {
          habitProvider.completeHabit(
            widget.habit.id,
            context,
            stateProvider,
            day: widget.focusedDay,
          );
        } else {
          // Opens a dialog for selecting amount/duration completion

          if (widget.habit.amount > 0) {
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              isScrollControlled: true,
              builder: (context) {
                return LogProgressDialog(
                  progressType: ProgressType.amount,
                  habit: widget.habit,
                );
              },
            );
          } else {
            showDurationCompletionDialog(
              context,
              widget.habit,
              widget.focusedDay ?? DateTime.now(),
            );
          }
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

enum ProgressType { amount, duration }

class LogProgressDialog extends StatelessWidget {
  const LogProgressDialog({
    super.key,
    required this.progressType,
    required this.habit,
  });

  final ProgressType progressType;
  final Habit habit;

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: cp.bg,
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 20,
          children: [titleAndDesc(cp), target(cp), buttons(cp)],
        ),
      ),
    );
  }

  Row buttons(ColorProvider cp) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      spacing: 8,
      children: [
        Expanded(
          child: NewDefaultButton.secondary(onPressed: () {}, label: "Cancel"),
        ),
        Expanded(
          child: NewDefaultButton.primary(onPressed: () {}, label: "Save"),
        ),
      ],
    );
  }

  Row target(ColorProvider cp) {
    String getTargetText() {
      if (progressType == ProgressType.amount) {
        return "${habit.amount} ${habit.amountLabel.isEmpty ? "times" : habit.amountLabel}";
      } else {
        final hours = habit.duration ~/ 60;
        final minutes = habit.duration % 60;

        return "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}";
      }
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Target:',
          style: TextStyle(
            color: cp.text,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: [
            SvgPicture.asset("assets/images/new-svg/clock.svg"),
            Text(
              getTargetText(),
              style: TextStyle(
                color: const Color(0xFF0B0B0B),
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Column titleAndDesc(ColorProvider cp) {
    final title =
        progressType == ProgressType.amount ? "Log progress" : "Log duration";
    final desc =
        progressType == ProgressType.amount
            ? "How much did you complete today?"
            : "How much time did you spend on this habit today?";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 10,
      children: [
        Text(
          title,
          style: TextStyle(
            color: cp.text,
            fontSize: 22,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(desc, style: TextStyle(color: cp.greyText, fontSize: 16)),
      ],
    );
  }
}
