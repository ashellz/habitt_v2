import 'package:flutter/material.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/util/show_dialog_sheet.dart';
import 'package:habitt/widgets/default/new_default_button.dart';
import 'package:habitt/widgets/dialogs/log_progress_dialog.dart';
import 'package:habitt/widgets/main_page/habits/habit_widget/new_habit_progress.dart';
import 'package:provider/provider.dart';

class HabitPrimaryActionButton extends StatefulWidget {
  const HabitPrimaryActionButton({
    super.key,
    required this.habit,
    this.isDemo = false,
    this.onDemoTap,
    this.dayOverride,
  });

  final Habit habit;
  final bool isDemo;
  final VoidCallback? onDemoTap;
  final DateTime? dayOverride;

  @override
  State<HabitPrimaryActionButton> createState() =>
      _HabitPrimaryActionButtonState();
}

class _HabitPrimaryActionButtonState extends State<HabitPrimaryActionButton> {
  double _progressValue() {
    if (widget.habit.completed || widget.habit.skipped) {
      return 1;
    }

    if (widget.habit.tracksAmount) {
      if (widget.habit.amount <= 0) {
        return 0;
      }
      return (widget.habit.amountCompleted / widget.habit.amount).clamp(
        0.0,
        1.0,
      );
    }

    if (widget.habit.tracksDuration) {
      if (widget.habit.duration <= 0) {
        return 0;
      }
      return (widget.habit.durationCompleted / widget.habit.duration).clamp(
        0.0,
        1.0,
      );
    }

    return 0;
  }

  String _label() {
    final loc = AppLocalizations.of(context)!;
    if (widget.habit.completed) {
      return loc.completed;
    }
    if (!widget.isDemo && widget.habit.hasTrackingType) {
      return loc.logProgress;
    }
    return loc.markAsComplete;
  }

  Future<void> _onMainTap() async {
    if (widget.isDemo) {
      widget.onDemoTap?.call();
      return;
    }

    final habitProvider = context.read<HabitProvider>();
    final stateProvider = context.read<StateProvider>();
    final effectiveDay = widget.dayOverride ?? DateTime.now();

    if (!widget.habit.hasTrackingType) {
      habitProvider.completeHabit(
        widget.habit.id,
        context,
        stateProvider,
        dayOverride: effectiveDay,
      );
      return;
    }

    await showDialogSheet(
      context: context,
      builder: (context) {
        return LogProgressDialog(
          progressType:
              widget.habit.tracksAmount
                  ? ProgressType.amount
                  : ProgressType.duration,
          habit: widget.habit,
          dayOverride: effectiveDay,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();

    return GestureDetector(
      onTap: _onMainTap,
      onLongPress:
          widget.isDemo
              ? null
              : () {
                final habitProvider = context.read<HabitProvider>();
                final stateProvider = context.read<StateProvider>();
                habitProvider.completeHabit(
                  widget.habit.id,
                  context,
                  stateProvider,
                  dayOverride: widget.dayOverride ?? DateTime.now(),
                );
              },
      child: NewDefaultButton(
        color: widget.habit.completed ? cp.habitBg : cp.main,
        height: 41,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        onPressed: () => _onMainTap(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IgnorePointer(
              child: _ActionProgressIcon(
                progress: _progressValue(),
                habit: widget.habit,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              _label(),
              style: TextStyle(
                color: widget.habit.completed ? cp.lightGreyText : cp.bg,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionProgressIcon extends StatelessWidget {
  const _ActionProgressIcon({required this.progress, required this.habit});

  final double progress;
  final Habit habit;

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();

    return NewHabitProgress(
      habit: habit,
      color: cp.bg,
      extraTapArea: false,
      secondaryCheckmarks: true,
    );
  }
}
