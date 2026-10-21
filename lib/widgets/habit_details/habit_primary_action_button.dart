import 'package:flutter/material.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/util/show_dialog_sheet.dart';
import 'package:habitt/widgets/default/confetti_burst.dart';
import 'package:habitt/widgets/default/new_default_button.dart';
import 'package:habitt/widgets/dialogs/log_progress_dialog.dart';
import 'package:habitt/widgets/dialogs/timer_dialog.dart';
import 'package:habitt/widgets/dialogs/unpause_restore_habit_dialog.dart';
import 'package:habitt/widgets/main_page/habits/habit_widget/new_habit_progress.dart';
import 'package:provider/provider.dart';

class HabitPrimaryActionButton extends StatefulWidget {
  const HabitPrimaryActionButton({
    super.key,
    required this.habit,
    this.isDemo = false,
    this.onDemoTap,
  });

  final Habit habit;
  final bool isDemo;
  final VoidCallback? onDemoTap;
  @override
  State<HabitPrimaryActionButton> createState() =>
      _HabitPrimaryActionButtonState();
}

class _HabitPrimaryActionButtonState extends State<HabitPrimaryActionButton> {
  final _buttonKey = GlobalKey();
  late bool _lastCompleted;
  // set when the user taps/holds to complete, so completions from elsewhere
  // (Health sync, notification actions) don't pop confetti
  bool _confettiArmed = false;

  @override
  void initState() {
    super.initState();
    _lastCompleted = widget.habit.completed;
  }

  void _burstConfetti() {
    final box = _buttonKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.attached) return;
    ConfettiBurst.show(
      context,
      origin: box.localToGlobal(Offset(box.size.width, 0)),
      direction: ConfettiDirection.topRight,
    );
  }

  void _trackCompletion() {
    final completed = widget.habit.completed;
    if (completed == _lastCompleted) return;
    _lastCompleted = completed;
    if (completed && _confettiArmed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _burstConfetti();
      });
    }
    _confettiArmed = false;
  }

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

  String _label(bool isCompleted) {
    final loc = AppLocalizations.of(context)!;
    if (isCompleted) {
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

    if (widget.habit.isPaused == true || widget.habit.isDeleted == true) {
      final loc = AppLocalizations.of(context)!;
      // shows a dialog to inform the user that the habit is paused or deleted
      // with optioins to unpause or restore the habit.
      bool isPaused = widget.habit.isPaused == true;
      final String title = isPaused ? loc.habitPaused : loc.habitDeleted;
      final String desc = isPaused ? loc.habitPausedDesc : loc.habitDeletedDesc;

      final buttonText = isPaused ? loc.unpause : loc.restore;

      await showDialogSheet(
        context: context,
        builder:
            (context) => UnpauseRestoreHabitDialog(
              title: title,
              desc: desc,
              buttonText: buttonText,
              loc: loc,
              isPaused: isPaused,
              widget: widget,
            ),
      );

      return;
    }

    final habitProvider = context.read<HabitProvider>();
    final stateProvider = context.read<StateProvider>();

    if (!widget.habit.hasTrackingType) {
      _confettiArmed = !widget.habit.completed;
      habitProvider.completeHabit(widget.habit.id, context, stateProvider);
      return;
    }

    final selected = habitProvider.selectedDate;
    final now = DateTime.now();
    final isToday =
        selected == null ||
        (selected.year == now.year &&
            selected.month == now.month &&
            selected.day == now.day);
    final wasCompleted = widget.habit.completed;

    await showDialogSheet(
      context: context,
      builder: (context) {
        if (widget.habit.tracksAmount) {
          return LogProgressDialog(
            progressType: ProgressType.amount,
            habit: widget.habit,
          );
        } else if (isToday) {
          return TimerDialog(habit: widget.habit);
        } else {
          return LogProgressDialog(
            progressType: ProgressType.duration,
            habit: widget.habit,
          );
        }
      },
    );

    // completed inside the dialog: pop once it's out of the way
    if (mounted && !wasCompleted && widget.habit.completed) {
      _burstConfetti();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    // the timer provider completes the habit itself once the target is
    // reached, so watching the habit provider is enough to stay in sync
    context.watch<HabitProvider>();
    _trackCompletion();
    final isCompleted = widget.habit.completed;

    return GestureDetector(
      onTap: _onMainTap,
      onLongPress:
          widget.isDemo
              ? null
              : () {
                final habitProvider = context.read<HabitProvider>();
                final stateProvider = context.read<StateProvider>();
                _confettiArmed = !widget.habit.completed;
                habitProvider.completeHabit(
                  widget.habit.id,
                  context,
                  stateProvider,
                );
              },
      child: NewDefaultButton(
        key: _buttonKey,
        color: isCompleted ? cp.habitBg : cp.main,
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
              _label(isCompleted),
              style: TextStyle(
                color: isCompleted ? cp.lightGreyText : cp.bg,
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
