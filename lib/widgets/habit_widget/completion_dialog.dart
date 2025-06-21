import 'package:flutter/material.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/widgets/custom_spinbox.dart';
import 'package:habitt/widgets/select_habit_type_widget.dart';
import 'package:provider/provider.dart';
import 'package:habitt/l10n/app_localizations.dart';

class CompletionDialog extends StatelessWidget {
  const CompletionDialog({super.key, required this.habit});

  final Habit habit;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final habitProvider = context.read<HabitProvider>();
    final stateProvider = context.watch<StateProvider>();
    final colorProvider = context.watch<ColorProvider>();

    HabitType type = HabitType.none;

    if (habit.amount > 1) {
      type = HabitType.amount;
    } else if (habit.duration > 0) {
      type = HabitType.duration;
    }

    return StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          backgroundColor: colorProvider.backgroundColor,
          content: CompletionDialogContent(
            habit: habit,
            stateProvider: stateProvider,
            type: type,
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  child: Text(
                    localizations.cancel,
                    style: TextStyle(
                      color: colorProvider.colorScheme.vividColor,
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                TextButton(
                  child: Text(
                    localizations.done,
                    style: TextStyle(
                      color: colorProvider.colorScheme.vividColor,
                    ),
                  ),
                  onPressed: () {
                    if (type == HabitType.amount) {
                      // If nothing changed then don't update unnecessarily
                      if (habit.amountCompleted == stateProvider.habitAmount) {
                        Navigator.pop(context);
                        return;
                      }

                      habitProvider.updateHabitAmountCompleted(
                        habit.id,
                        stateProvider.habitAmount,
                      );
                    } else {
                      // If nothing changed then don't update unnecessarily
                      if (habit.durationCompleted ==
                          stateProvider.habitDuration.inMinutes) {
                        Navigator.pop(context);
                        return;
                      }

                      habitProvider.updateHabitDurationCompleted(
                        habit.id,
                        stateProvider.habitDuration.inMinutes,
                      );
                    }

                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class CompletionDialogContent extends StatefulWidget {
  const CompletionDialogContent({
    super.key,
    required this.habit,
    required this.stateProvider,
    required this.type,
  });

  final Habit habit;
  final StateProvider stateProvider;
  final HabitType type;

  @override
  State<CompletionDialogContent> createState() =>
      _CompletionDialogContentState();
}

class _CompletionDialogContentState extends State<CompletionDialogContent> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Sets the initial amount or duration
      if (widget.type == HabitType.amount) {
        widget.stateProvider.habitAmount = widget.habit.amountCompleted;
      } else {
        widget.stateProvider.habitDuration = Duration(
          hours: widget.habit.durationCompleted ~/ 60,
          minutes: widget.habit.durationCompleted % 60,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    int amount = widget.habit.amount;
    int minutes = widget.habit.duration % 60;
    int hours = widget.habit.duration ~/ 60;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Column(
          children: [
            if (widget.habit.amount > 1)
              Column(
                children: [
                  HabitSlider(
                    totalSegments: amount,
                    filledSegments: widget.stateProvider.habitAmount,
                    onChanged: (newValue) {
                      setState(() {
                        widget.stateProvider.habitAmount = newValue;
                      });
                    },
                  ),
                  /* 
                  CustomSpinBox(
                    labelText: capitalizeFirst(widget.habit.amountLabel),
                    min: 0,
                    max: amount.toDouble(),
                    value: widget.stateProvider.habitAmount.toDouble(),
                    onChanged: (value) {
                      // Sets the new amount
                      widget.stateProvider.habitAmount = value.toInt();
                    },
                  ),*/
                ],
              )
            else
              Column(
                children: [
                  if (widget.habit.duration > 60)
                    CustomSpinBox(
                      labelText: localizations.hours,
                      min: 0,
                      max: hours.toDouble(),
                      value:
                          widget.stateProvider.habitDuration.inHours.toDouble(),
                      onChanged: (value) {
                        final int newMinutes =
                            widget.stateProvider.habitDuration.inMinutes % 60;

                        // Sets the new duration
                        widget.stateProvider.habitDuration = Duration(
                          hours: value.toInt(),
                          minutes: newMinutes,
                        );

                        // If the hours are maxed out, lowers minutes if they're over the max amount
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (widget.stateProvider.habitDuration.inHours ==
                              hours) {
                            if (newMinutes > minutes) {
                              widget.stateProvider.habitDuration = Duration(
                                hours: value.toInt(),
                                minutes: minutes,
                              );
                            }
                          }
                        });
                      },
                    ),
                  if (widget.habit.duration > 60) const SizedBox(height: 10),
                  CustomSpinBox(
                    labelText: localizations.minutes,
                    min: 0,
                    max: // If hour is maxed out, sets max to max minutes, else 59
                        widget.stateProvider.habitDuration.inHours.toDouble() <
                                hours
                            ? 59
                            : minutes.toDouble(),
                    value: widget.stateProvider.habitDuration.inMinutes % 60,
                    onChanged: (value) {
                      // Sets the new duration
                      widget.stateProvider.habitDuration = Duration(
                        hours: widget.stateProvider.habitDuration.inHours,
                        minutes: value.toInt(),
                      );
                    },
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }
}

class HabitSlider extends StatefulWidget {
  final int totalSegments;
  final int filledSegments;
  final void Function(int) onChanged;

  const HabitSlider({
    required this.totalSegments,
    required this.filledSegments,
    required this.onChanged,
    super.key,
  });

  @override
  State<HabitSlider> createState() => _HabitSliderState();
}

class _HabitSliderState extends State<HabitSlider> {
  late int currentFilled;

  void _updateFill(Offset localPos, double height) {
    final value =
        (widget.totalSegments - (localPos.dy / height) * widget.totalSegments)
            .clamp(0, widget.totalSegments)
            .floor();
    if (value != currentFilled) {
      setState(() => currentFilled = value);
      widget.onChanged(currentFilled);
    }
  }

  double getFontSize() {
    if (currentFilled < 10) {
      return 98;
    } else if (currentFilled < 100) {
      return 54;
    } else if (currentFilled < 1000) {
      return 44;
    } else {
      return 34;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorProvider = context.watch<ColorProvider>();
    final isSimpleSlider = widget.totalSegments > 50;
    currentFilled = widget.filledSegments;

    return Stack(
      alignment: Alignment.center,
      children: [
        GestureDetector(
          onVerticalDragUpdate: (details) {
            RenderBox box = context.findRenderObject() as RenderBox;
            final localPos = box.globalToLocal(details.globalPosition);
            _updateFill(localPos, box.size.height);
          },
          child: SizedBox(
            width: 100,
            height: 240,
            child:
                isSimpleSlider
                    ? _buildSmoothSlider(colorProvider)
                    : _buildSegmentedSlider(colorProvider),
          ),
        ),

        IgnorePointer(
          child: Container(
            width: 100,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                currentFilled.toString(),
                style: TextStyle(
                  color: colorProvider.colorScheme.strokeColor.withOpacity(0.5),
                  fontWeight: FontWeight.bold,
                  fontSize: getFontSize(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSegmentedSlider(ColorProvider colorProvider) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: Column(
        children: List.generate(widget.totalSegments, (index) {
          final reversedIndex = widget.totalSegments - index - 1;
          final isFilled = reversedIndex < currentFilled;
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 0.5),
              decoration: BoxDecoration(
                color:
                    isFilled
                        ? colorProvider.colorScheme.vividColor
                        : colorProvider.colorScheme.strokeColor.withOpacity(
                          0.5,
                        ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSmoothSlider(ColorProvider colorProvider) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;
        final fillHeight = (currentFilled / widget.totalSegments) * height;
        final fillRatio = currentFilled / widget.totalSegments;

        // Calculate top radius based on how close to full it is
        double topRadius = 0;
        if (fillRatio > 0.9) {
          topRadius = ((fillRatio - 0.9) / 0.1) * 30.clamp(0, 30);
        }

        return Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              decoration: BoxDecoration(
                color: colorProvider.colorScheme.strokeColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            Container(
              height: fillHeight,
              decoration: BoxDecoration(
                color: colorProvider.colorScheme.vividColor,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(30),
                  top: Radius.circular(topRadius),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
