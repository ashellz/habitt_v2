import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/widgets/habit_widget/completion_dialogs/enter_amount_slider.dart';
import 'package:provider/provider.dart';

class EnterAmountSliderDialog extends StatefulWidget {
  const EnterAmountSliderDialog({super.key, required this.habit});

  final Habit habit;

  @override
  State<EnterAmountSliderDialog> createState() =>
      _EnterAmountSliderDialogState();
}

class _EnterAmountSliderDialogState extends State<EnterAmountSliderDialog> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final stateProvider = context.read<StateProvider>();
      stateProvider.habitAmount = widget.habit.amountCompleted;
    });
  }

  @override
  Widget build(BuildContext context) {
    final stateProvider = context.watch<StateProvider>();
    final colorProvider = context.watch<ColorProvider>();
    final habitProvider = context.read<HabitProvider>();

    return Dialog(
      backgroundColor:
          Colors.transparent, // Important for the blur to show through
      insetPadding: EdgeInsets.zero,
      child: IntrinsicWidth(
        child: IntrinsicHeight(
          child: Row(
            children: [
              SizedBox(width: 8 + 50),
              EnterAmountSlider(
                totalSegments: widget.habit.amount,
                filledSegments: stateProvider.habitAmount,
                onChanged: (newValue) {
                  stateProvider.habitAmount = newValue;
                  HapticFeedback.selectionClick();
                },
              ),
              SizedBox(width: 8),
              Column(
                children: [
                  CircleButton(
                    colorProvider: colorProvider,
                    icon: Icon(Icons.check, color: Colors.white),
                    color: colorProvider.colorScheme.darkerStandardColor,
                    onPressed: () {
                      if (widget.habit.amountCompleted ==
                          stateProvider.habitAmount) {
                        Navigator.pop(context);
                        return;
                      }

                      habitProvider.updateHabitAmountCompleted(
                        widget.habit.id,
                        stateProvider.habitAmount,
                      );

                      Navigator.pop(context);
                    },
                  ),
                  SizedBox(height: 4),
                  CircleButton(
                    colorProvider: colorProvider,
                    icon: Icon(Icons.close, color: colorProvider.textColor),
                    color: colorProvider.colorScheme.standardColor,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CircleButton extends StatefulWidget {
  const CircleButton({
    super.key,
    required this.colorProvider,
    required this.icon,
    required this.color,
    this.onPressed,
  });

  final ColorProvider colorProvider;
  final Widget icon;
  final Color color;
  final VoidCallback? onPressed;

  @override
  State<CircleButton> createState() => _CircleButtonState();
}

class _CircleButtonState extends State<CircleButton> {
  double scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          scale = 0.9;
        });
        Future.delayed(const Duration(milliseconds: 150), () {
          setState(() {
            scale = 1.0;
          });
        });

        if (widget.onPressed != null) {
          widget.onPressed!();
        }
      },
      onTapDown: (context) {
        HapticFeedback.selectionClick();
        setState(() {
          scale = 0.9;
        });
      },

      onTapCancel: () {
        setState(() {
          scale = 1.0;
        });
      },
      onTapUp: (context) {
        HapticFeedback.selectionClick();
        setState(() {
          scale = 1.0;
        });
      },
      child: AnimatedScale(
        duration: const Duration(milliseconds: 150),
        scale: scale,
        child: Container(
          height: 50,
          width: 50,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
          ),
          padding: const EdgeInsets.all(8),

          child: Center(child: widget.icon),
        ),
      ),
    );
  }
}
