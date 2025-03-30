import 'package:flutter/material.dart';
import 'package:flutter_spinbox/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/widgets/enter_amount_page/amount_wheel.dart';
import 'package:habitt/widgets/enter_amount_page/enter_amount_text.dart';
import 'package:habitt/widgets/gradient_background.dart';
import 'package:habitt/widgets/select_habit_type_widget.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class NumberPickerScreen extends StatefulWidget {
  const NumberPickerScreen({super.key, required this.type});

  final HabitType type;

  @override
  NumberPickerScreenState createState() => NumberPickerScreenState();
}

class NumberPickerScreenState extends State<NumberPickerScreen> {
  int wheelValue = 2;
  Duration durationValue = const Duration(hours: 0, minutes: 20);
  bool editingHours = true;

  void increaseWheelValue() {
    if (widget.type == HabitType.amount) {
      if (wheelValue < 9999) {
        setState(() {
          wheelValue++;
        });
      }
    } else {
      if (editingHours) {
        if (durationValue.inHours < 23) {
          setState(() {
            durationValue += const Duration(hours: 1);
          });
        }
      } else {
        if (durationValue.inMinutes % 60 < 59) {
          setState(() {
            durationValue += const Duration(minutes: 1);
          });
        }
      }
    }
  }

  void decreaseWheelValue() {
    if (widget.type == HabitType.amount) {
      if (wheelValue > 2) {
        setState(() {
          wheelValue--;
        });
      }
    } else {
      if (editingHours) {
        if (durationValue.inHours > 0) {
          setState(() {
            durationValue -= const Duration(hours: 1);
          });
        }
      } else {
        if (durationValue.inMinutes % 60 > 0) {
          setState(() {
            durationValue -= const Duration(minutes: 1);
          });
        }
      }
    }
  }

  void onDone() {
    final stateProvider = context.read<StateProvider>();

    Future.microtask(() {
      if (widget.type == HabitType.amount) {
        stateProvider.habitAmount = wheelValue;
      } else {
        stateProvider.habitDuration = durationValue;
      }
    });

    Navigator.pop(context);
  }

  void switchValues() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        editingHours = !editingHours;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final ColorProvider colorProvider = context.watch<ColorProvider>();
    final localizations = AppLocalizations.of(context)!;
    final double width = MediaQuery.of(context).size.width;
    final double offset = width / 4;

    return Scaffold(
      body: GradientBackground(
        child: Stack(
          children: [
            SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    EnterAmountDurationText(
                      colorProvider: colorProvider,
                      type: widget.type,
                    ),
                    // Amount/Duration value
                    GestureDetector(
                      onTap:
                          () => showDialog(
                            context: context,
                            builder:
                                (context) => SelectAmountDurationDialog(
                                  wheelValue: wheelValue,
                                  durationValue: durationValue,
                                  onChanged: (value) {
                                    WidgetsBinding.instance
                                        .addPostFrameCallback((_) {
                                          setState(() {
                                            wheelValue = value;
                                          });
                                        });
                                  },
                                  type: widget.type,
                                ),
                          ),
                      child:
                          widget.type == HabitType.amount
                              ? Text(
                                wheelValue.toString(),
                                style: TextStyle(
                                  fontSize: 56,
                                  height: 0,
                                  fontWeight: FontWeight.bold,
                                  color: colorProvider.textColor,
                                ),
                              )
                              : Row(
                                children: [
                                  AnimatedOpacity(
                                    opacity: editingHours ? 1 : 0.5,
                                    duration: Duration(milliseconds: 150),
                                    child: Text.rich(
                                      TextSpan(
                                        children: [
                                          TextSpan(
                                            text:
                                                durationValue.inHours
                                                    .toString(),
                                            style: TextStyle(
                                              fontSize: 56,
                                              height: 0,
                                              fontWeight: FontWeight.bold,
                                              color: colorProvider.textColor,
                                            ),
                                          ),
                                          TextSpan(
                                            text: 'h',
                                            style: TextStyle(
                                              fontSize: 56,
                                              height: 0,
                                              fontWeight: FontWeight.w200,
                                              color: colorProvider.textColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  AnimatedOpacity(
                                    opacity: editingHours ? 0.5 : 1,
                                    duration: Duration(milliseconds: 150),
                                    child: Text.rich(
                                      TextSpan(
                                        children: [
                                          TextSpan(
                                            text:
                                                "${durationValue.inMinutes % 60}",
                                            style: TextStyle(
                                              fontSize: 56,
                                              height: 0,
                                              fontWeight: FontWeight.bold,
                                              color: colorProvider.textColor,
                                            ),
                                          ),
                                          TextSpan(
                                            text: 'm',
                                            style: TextStyle(
                                              fontSize: 56,
                                              height: 0,
                                              fontWeight: FontWeight.w200,
                                              color: colorProvider.textColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  SwitchValuesArrow(
                                    editingHours: editingHours,
                                    switchValues: switchValues,
                                  ),
                                ],
                              ),
                    ),
                    TipText(
                      width: width,
                      localizations: localizations,
                      colorProvider: colorProvider,
                      type: widget.type,
                    ),
                  ],
                ),
              ),
            ),

            //Wheel itself
            Stack(
              children: [
                Positioned(
                  left: offset,
                  bottom: -offset,
                  child: InteractiveWheel(
                    wheelValue: wheelValue,
                    decreaseWheelValue: decreaseWheelValue,
                    increaseWheelValue: increaseWheelValue,
                    onDone: onDone,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class TipText extends StatelessWidget {
  const TipText({
    super.key,
    required this.width,
    required this.localizations,
    required this.colorProvider,
    required this.type,
  });

  final double width;
  final AppLocalizations localizations;
  final ColorProvider colorProvider;
  final HabitType type;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width / 2,
      child: Text(
        localizations.youCanPressNumberAbove(
          type == HabitType.amount
              ? localizations.amount.toLowerCase()
              : localizations.duration.toLowerCase(),
        ),
        style: TextStyle(color: colorProvider.textColor),
      ),
    );
  }
}

class SelectAmountDurationDialog extends StatelessWidget {
  const SelectAmountDurationDialog({
    super.key,
    required this.onChanged,
    required this.wheelValue,
    required this.type,
    required this.durationValue,
  });

  final ValueChanged<int> onChanged;
  final int wheelValue;
  final Duration durationValue;
  final HabitType type;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Dialog(
      child: Container(
        padding: EdgeInsets.all(12),
        child:
            type == HabitType.amount
                ? CustomSpinBox(
                  labelText: localizations.amount,
                  min: 2,
                  max: 9999,
                  value: wheelValue.toDouble(),
                  onChanged: onChanged,
                )
                : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomSpinBox(
                      labelText: localizations.hours,
                      min: 0,
                      max: 23,
                      value: durationValue.inHours.toDouble(),
                      onChanged: onChanged,
                    ),
                    const SizedBox(height: 12),
                    CustomSpinBox(
                      labelText: localizations.minutes,
                      min: 0,
                      max: 59,

                      value: durationValue.inMinutes % 60,
                      onChanged: onChanged,
                    ),
                  ],
                ),
      ),
    );
  }
}

class CustomSpinBox extends StatelessWidget {
  const CustomSpinBox({
    super.key,
    required this.labelText,
    required this.min,
    required this.max,
    required this.value,
    required this.onChanged,
  });

  final String labelText;
  final double min;
  final double max;
  final double value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorProvider = context.watch<ColorProvider>();

    return SpinBox(
      textInputAction: TextInputAction.done,
      cursorColor: colorProvider.textColor,
      enableInteractiveSelection: true,

      iconColor: WidgetStateProperty.all<Color>(colorProvider.textColor),
      decoration: InputDecoration(
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(20.0)),
        ),
        filled: true,
        fillColor: colorProvider.standardColor,
        labelStyle: TextStyle(
          fontSize: 16.0,
          fontWeight: FontWeight.bold,
          color: colorProvider.textColor,
        ),
        labelText: labelText,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15.0),
          borderSide: BorderSide(color: colorProvider.colorScheme.strokeColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(20.0)),
          borderSide: BorderSide(color: colorProvider.colorScheme.strokeColor),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 20,
          horizontal: 20,
        ),
      ),
      min: min,
      max: max,
      value: value,
      onChanged: (value) => onChanged(value.toInt()),
    );
  }
}

class SwitchValuesArrow extends StatelessWidget {
  const SwitchValuesArrow({
    super.key,
    required this.editingHours,
    required this.switchValues,
  });

  final bool editingHours;
  final GestureTapCallback switchValues;

  @override
  Widget build(BuildContext context) {
    final colorProvider = context.watch<ColorProvider>();

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colorProvider.colorScheme.standardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: AnimatedRotation(
        turns: editingHours ? 0.5 : 1,
        curve: Curves.decelerate,
        duration: Duration(milliseconds: 150),
        child: GestureDetector(
          onTap: switchValues,
          child: SvgPicture.asset(
            width: 30,
            height: 30,
            "assets/images/svg/arrow-back.svg",
          ),
        ),
      ),
    );
  }
}
