import 'package:flutter/material.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/widgets/habit_widget/habit_icon.dart';
import 'package:habitt/widgets/habit_widget/habit_text.dart';
import 'package:provider/provider.dart';

class HabitWidget extends StatelessWidget {
  const HabitWidget({super.key, required this.editable, required this.habit});

  final Habit habit;
  final bool editable;

  @override
  Widget build(BuildContext context) {
    final colorProvider = context.watch<ColorProvider>();
    final int alpha = 100;

    // Main container
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: habit.completed ? 0 : 1),
      duration: const Duration(milliseconds: 200),
      builder: (context, double value, child) {
        return Container(
          margin: EdgeInsets.only(top: 8),
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          height: 74,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color:
                Color.lerp(
                  colorProvider.habitColor.withAlpha(alpha),
                  colorProvider.habitColor,
                  value,
                )!,
          ),
          // Inside of the container
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left side
              Row(
                children: [
                  // Icon circle container
                  HabitIcon(
                    editable: editable,
                    colorProvider: colorProvider,
                    alpha: alpha,
                    habit: habit,
                    value: value,
                  ),
                  // Text
                  HabitText(
                    habit: habit,
                    colorProvider: colorProvider,
                    alpha: alpha,
                    value: value,
                  ),
                ],
              ),
              // Completion and streak
              Row(
                children: [
                  if (habit.streak > 0)
                    StreakDisplay(
                      streak: habit.streak,
                      colorProvider: colorProvider,
                    ),
                  // Completion
                  CompletionDisplay(
                    editable: editable,
                    colorProvider: colorProvider,
                    habit: habit,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class CompletionDisplay extends StatefulWidget {
  const CompletionDisplay({
    super.key,
    required this.colorProvider,
    required this.editable,
    required this.habit,
  });

  final ColorProvider colorProvider;
  final bool editable;
  final Habit habit;

  @override
  State<CompletionDisplay> createState() => _CompletionDisplayState();
}

class _CompletionDisplayState extends State<CompletionDisplay> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    final habitProvider = context.read<HabitProvider>();

    // Main widget
    return GestureDetector(
      onTap:
          widget.editable
              ? null
              : () {
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
                    widget.habit.completed) {
                  habitProvider.completeHabit(widget.habit.id);
                } else {
                  // TODO: Open dialog for selecting amount/duration completion
                }
              },
      onTapDown: (context) {
        setState(() {
          _scale = 0.9;
        });
      },
      onTapCancel:
          () => setState(() {
            _scale = 1.0;
          }),
      onTapUp:
          (context) => setState(() {
            _scale = 1.0;
          }),
      onLongPress: () {
        habitProvider.completeHabit(widget.habit.id);
      },
      child: AnimatedScale(
        duration: const Duration(milliseconds: 150),
        scale: _scale,
        child: Container(
          clipBehavior: Clip.hardEdge,
          height: 50,
          width: 50,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(15)),
          child: Stack(
            children: [
              Positioned.fill(
                child: RotatedBox(
                  quarterTurns: -1,
                  child: TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                    tween: Tween<double>(
                      begin: 0,
                      end:
                          // Really complicated logic here but it works
                          // Basically checks if habit has amount or duration
                          // If not its filled from 0 to 1 if completed or not
                          // Otherwise fills it by amount or duration completed accordingly
                          widget.habit.amount == 0 &&
                                      widget.habit.duration == 0 ||
                                  widget.habit.completed
                              ? widget.habit.completed
                                  ? 1
                                  : 0
                              : widget.habit.amount > 1
                              ? widget.habit.amountCompleted /
                                  widget.habit.amount
                              : widget.habit.durationCompleted /
                                  widget.habit.duration,
                    ),
                    builder: (context, value, _) {
                      return LinearProgressIndicator(
                        value: value,
                        color:
                            widget
                                .colorProvider
                                .colorScheme
                                .darkerStandardColor,
                        backgroundColor:
                            widget.colorProvider.colorScheme.strokeColor,
                      );
                    },
                  ),
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder:
                    (child, animation) =>
                        FadeTransition(opacity: animation, child: child),
                child: KeyedSubtree(
                  key: ValueKey<bool>(widget.habit.completed),
                  child: getCompletionWidget(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Center icon
  Widget centerIcon() {
    return Center(
      child: Icon(
        widget.habit.completed ? Icons.check : Icons.close,
        color: widget.colorProvider.backgroundColor,
      ),
    );
  }

  // Middle child inside of the container (checkmark or amount/duration)
  Widget getCompletionWidget() {
    if (widget.habit.amount > 0 && !widget.habit.completed) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            widget.habit.amountCompleted.toString(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: widget.colorProvider.backgroundColor,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Divider(height: 5, thickness: 2),
          ),
          Text(
            widget.habit.amount.toString(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: widget.colorProvider.backgroundColor,
            ),
          ),
        ],
      );
    } else if (widget.habit.duration > 0 && !widget.habit.completed) {
      final String durationCopmletedString =
          "${widget.habit.durationCompleted / 60}h${widget.habit.durationCompleted % 60}m";

      final String durationString =
          "${widget.habit.duration / 60}h${widget.habit.duration % 60}m";

      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            durationCopmletedString,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: widget.colorProvider.backgroundColor,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Divider(height: 5, thickness: 2),
          ),
          Text(
            durationString,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: widget.colorProvider.backgroundColor,
            ),
          ),
        ],
      );
    } else {
      return centerIcon();
    }
  }
}

class StreakDisplay extends StatelessWidget {
  const StreakDisplay({
    super.key,
    required this.streak,
    required this.colorProvider,
  });

  final int streak;
  final ColorProvider colorProvider;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(right: 5),
      child: SizedBox(
        width: 30,
        height: 30,
        child: Stack(
          children: [
            Image.asset("assets/images/icons/streak.png"),
            Center(
              child: Transform.translate(
                offset: Offset(0, 1.5),
                child: FittedBox(
                  child: Text(
                    "$streak",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorProvider.textColor,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
