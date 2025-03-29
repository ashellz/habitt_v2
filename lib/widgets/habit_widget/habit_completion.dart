import 'package:flutter/material.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:provider/provider.dart';

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
        if (widget.editable) return;
        setState(() {
          _scale = 0.9;
        });
      },
      onTapCancel: () {
        if (widget.editable) return;
        setState(() {
          _scale = 1.0;
        });
      },
      onTapUp: (context) {
        if (widget.editable) return;
        setState(() {
          _scale = 1.0;
        });
      },
      onLongPress: () {
        if (widget.editable) return;
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
