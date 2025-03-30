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
              Padding(
                padding: const EdgeInsets.all(4.0),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder:
                      (child, animation) =>
                          FadeTransition(opacity: animation, child: child),
                  child: KeyedSubtree(
                    key: ValueKey<bool>(widget.habit.completed),
                    child: getCompletionWidget(),
                  ),
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
            child: Divider(
              height: 2,
              thickness: 2,
              color: widget.colorProvider.backgroundColor,
            ),
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
      return DurationDisplay(habit: widget.habit);
    } else {
      return centerIcon();
    }
  }
}

class DurationDisplay extends StatefulWidget {
  const DurationDisplay({super.key, required this.habit});

  final Habit habit;

  @override
  State<DurationDisplay> createState() => DurationDisplayState();
}

class DurationDisplayState extends State<DurationDisplay> {
  double _fontSize = 12;
  String? _lastBottomText;
  final TextPainter _painter = TextPainter(
    textDirection: TextDirection.ltr,
    maxLines: 1,
  );

  @override
  void didUpdateWidget(DurationDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.habit.duration != oldWidget.habit.duration) {
      _adjustFontSize();
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _adjustFontSize());
  }

  void _adjustFontSize() {
    final currentBottomText = _getDurationString(widget.habit.duration);

    // Only recalculate if text changed or we haven't calculated before
    if (_lastBottomText == currentBottomText) return;

    _lastBottomText = currentBottomText;
    const maxWidth = 48 * 0.85; // 85% of container width as safety margin
    const double minFontSize = 8;
    const double maxFontSize = 12;

    double testFontSize = maxFontSize;
    bool foundFit = false;

    while (testFontSize >= minFontSize && !foundFit) {
      _painter.text = TextSpan(
        text: currentBottomText,
        style: TextStyle(fontSize: testFontSize, fontWeight: FontWeight.bold),
      );

      _painter.layout(minWidth: 0, maxWidth: double.infinity);

      debugPrint(
        'Testing "${currentBottomText}" at $testFontSize: '
        '${_painter.width} vs $maxWidth',
      );

      if (_painter.width <= maxWidth) {
        foundFit = true;
      } else {
        testFontSize -= 0.5;
      }
    }

    final newFontSize = foundFit ? testFontSize : minFontSize;
    if (_fontSize != newFontSize) {
      setState(() => _fontSize = newFontSize);
    }
  }

  String _getDurationString(int duration) {
    return duration ~/ 60 == 0
        ? "${duration % 60}m"
        : duration % 60 == 0
        ? "${duration ~/ 60}h"
        : "${duration ~/ 60}h${duration % 60}m";
  }

  @override
  void dispose() {
    _painter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorProvider = context.watch<ColorProvider>();

    final durationCompletedString = _getDurationString(
      widget.habit.durationCompleted,
    );
    final durationString = _getDurationString(widget.habit.duration);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          durationCompletedString,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: colorProvider.backgroundColor,
            fontSize: _fontSize,
          ),
          maxLines: 1,
          softWrap: false,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Divider(
            height: 2,
            thickness: 2,
            color: colorProvider.backgroundColor,
          ),
        ),
        Text(
          durationString,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: colorProvider.backgroundColor,
            fontSize: _fontSize,
          ),
          maxLines: 1,
          softWrap: false,
        ),
      ],
    );
  }
}
