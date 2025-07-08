import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/widgets/enter_amount_page/amount_wheel.dart';
import 'package:habitt/widgets/enter_amount_page/enter_amount_text.dart';
import 'package:habitt/widgets/enter_amount_page/select_amount_duration_dialog.dart';
import 'package:habitt/widgets/enter_amount_page/switch_values_arrow.dart';
import 'package:habitt/widgets/enter_amount_page/tip_text.dart';
import 'package:habitt/widgets/gradient_background.dart';
import 'package:habitt/widgets/select_habit_type_widget.dart';
import 'package:provider/provider.dart';
import 'package:habitt/l10n/app_localizations.dart';

class EnterAmountPage extends StatefulWidget {
  const EnterAmountPage({
    super.key,
    required this.type,
    this.wheelValue = 2,
    this.durationValue = const Duration(hours: 0, minutes: 20),
  });

  final HabitType type;
  final int wheelValue;
  final Duration durationValue;

  @override
  EnterAmountPageState createState() => EnterAmountPageState();
}

class EnterAmountPageState extends State<EnterAmountPage> {
  late int wheelValue;
  late Duration durationValue;
  bool editingHours = true;

  @override
  void initState() {
    super.initState();
    wheelValue = widget.wheelValue;
    durationValue = widget.durationValue;
  }

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

    if (widget.type == HabitType.amount) {
      stateProvider.habitAmount = wheelValue;
    } else {
      stateProvider.habitDuration = durationValue;
    }

    Navigator.pop(context);
  }

  void switchValues() {
    setState(() {
      editingHours = !editingHours;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ColorProvider colorProvider = context.watch<ColorProvider>();
    final localizations = AppLocalizations.of(context)!;
    final double width = MediaQuery.of(context).size.width;
    final double offset = width / 4;
    final stateProvider = context.watch<StateProvider>();
    final amountLabelController = stateProvider.habitAmountLabelController;
    final amountLabel = amountLabelController.text;

    return AnnotatedRegion(
      value: SystemUiOverlayStyle(
        statusBarColor: colorProvider.backgroundColor,
        statusBarIconBrightness:
            colorProvider.isDarkMode ? Brightness.light : Brightness.dark,
        statusBarBrightness:
            colorProvider.isDarkMode
                ? Brightness.dark
                : Brightness.light, // for iOS
      ),
      child: Scaffold(
        backgroundColor: colorProvider.backgroundColor,
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
                                    habitAmountLabelController:
                                        amountLabelController,
                                    onChangedAmount: (value) {
                                      WidgetsBinding.instance
                                          .addPostFrameCallback((_) {
                                            setState(() {
                                              wheelValue = value;
                                            });
                                          });
                                    },
                                    onChangedHours: (value) {
                                      WidgetsBinding.instance
                                          .addPostFrameCallback((_) {
                                            setState(() {
                                              durationValue = Duration(
                                                hours: value,
                                                minutes:
                                                    durationValue.inMinutes %
                                                    60,
                                              );
                                            });
                                          });
                                    },
                                    onChangedMinutes: (value) {
                                      WidgetsBinding.instance
                                          .addPostFrameCallback((_) {
                                            setState(() {
                                              durationValue = Duration(
                                                hours: durationValue.inHours,
                                                minutes: value,
                                              );
                                            });
                                          });
                                    },
                                    type: widget.type,
                                  ),
                            ).whenComplete(
                              () => setState(() {
                                if (amountLabelController.text.isEmpty) {
                                  amountLabelController.text =
                                      localizations.times;
                                }
                              }),
                            ),
                        child:
                            widget.type == HabitType.amount
                                ? SizedBox(
                                  width: width - 32,
                                  child: Text.rich(
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    TextSpan(
                                      children: [
                                        TextSpan(
                                          text: '$wheelValue ',
                                          style: TextStyle(
                                            fontSize: 56,
                                            height: 0,
                                            fontWeight: FontWeight.bold,
                                            color: colorProvider.textColor,
                                          ),
                                        ),
                                        TextSpan(
                                          text: amountLabel,
                                          style: TextStyle(
                                            fontSize: 42,
                                            height: 0,
                                            color: colorProvider.textColor,
                                          ),
                                        ),
                                      ],
                                    ),
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
      ),
    );
  }
}
