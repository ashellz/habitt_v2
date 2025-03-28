import 'package:flutter/material.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/pages/other_pages/icons_page.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:provider/provider.dart';

class HabitWidget extends StatelessWidget {
  const HabitWidget({super.key, required this.editable, required this.habit});

  final Habit habit;
  final bool editable;

  @override
  Widget build(BuildContext context) {
    final colorProvider = context.watch<ColorProvider>();

    // Main container
    return Container(
      margin: EdgeInsets.only(top: 8),
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      height: 74,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: colorProvider.habitColor,
      ),
      // Inside of the container
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left side
          Row(
            children: [
              // Icon circle container
              InkWell(
                onTap: () {
                  if (editable) {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => IconsPage()),
                    );
                  }
                },
                child: Container(
                  width: 50,
                  height: 50,
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorProvider.iconBackgroundColor,
                  ),
                  // Icon
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 150),
                    transitionBuilder:
                        (child, animation) =>
                            ScaleTransition(scale: animation, child: child),
                    switchInCurve: Curves.decelerate,
                    switchOutCurve: Curves.decelerate,
                    child: Image.asset(
                      key: ValueKey<String>(habit.iconPath),
                      habit.iconPath,
                    ),
                  ),
                ),
              ),
              // Text
              Padding(
                padding: const EdgeInsets.only(left: 10),
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 150),
                  height: habit.description.isEmpty ? 23 : 43,
                  width:
                      MediaQuery.of(context).size.width -
                      32 - // 32 padding
                      100 - // 100 on the right
                      70, // 70 on the left
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        habit.name,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                        style: TextStyle(
                          fontSize: 16,
                          color: colorProvider.textColor,
                        ),
                      ),

                      AnimatedContainer(
                        duration: Duration(milliseconds: 150),
                        height: habit.description.isEmpty ? 0 : 20,
                        child: Text(
                          habit.description,
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 14,
                            color: colorProvider.mutedTextColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
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
    // Center icon
    Widget centerIcon() {
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder:
            (child, animation) =>
                FadeTransition(opacity: animation, child: child),
        child: Center(
          key: ValueKey<bool>(widget.habit.completed),
          child: Icon(
            widget.habit.completed ? Icons.check : Icons.close,
            color: widget.colorProvider.backgroundColor,
          ),
        ),
      );
    }

    // Middle child inside of the container (checkmark or amount/duration)
    Widget getCompletionWidget() {
      if (widget.habit.amount > 0) {
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
      } else if (widget.habit.duration > 0) {
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

                if (widget.habit.amount == 0 && widget.habit.duration == 0) {
                  setState(() {
                    widget.habit.completed = !widget.habit.completed;
                  });
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
        setState(() {
          widget.habit.completed = !widget.habit.completed;
        });
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
              if (widget.habit.amount == 0 && widget.habit.duration == 0)
                Positioned.fill(
                  child: RotatedBox(
                    quarterTurns: -1,
                    child: TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
                      tween: Tween<double>(
                        begin: 0,
                        end: widget.habit.completed ? 1 : 0,
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
                )
              else
                Positioned.fill(
                  child: RotatedBox(
                    quarterTurns: -1,
                    child: TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
                      tween: Tween<double>(
                        begin: 0,
                        end:
                            widget.habit.amount > 1
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
              getCompletionWidget(),
            ],
          ),
        ),
      ),
    );
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
