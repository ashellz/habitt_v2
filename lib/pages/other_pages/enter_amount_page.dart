import 'package:flutter/material.dart';
import 'package:flutter_spinbox/material.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/widgets/enter_amount_page/amount_wheel.dart';
import 'package:habitt/widgets/enter_amount_page/enter_amount_text.dart';
import 'package:habitt/widgets/gradient_background.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class NumberPickerScreen extends StatefulWidget {
  const NumberPickerScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _NumberPickerScreenState createState() => _NumberPickerScreenState();
}

class _NumberPickerScreenState extends State<NumberPickerScreen> {
  int wheelValue = 2;

  void increaseWheelValue() {
    if (wheelValue < 10000) {
      setState(() {
        wheelValue++;
      });
    }
  }

  void decreaseWheelValue() {
    if (wheelValue > 2) {
      setState(() {
        wheelValue--;
      });
    }
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
                    EnterAmountText(colorProvider: colorProvider),
                    // Amount value
                    GestureDetector(
                      onTap:
                          () => showDialog(
                            context: context,
                            builder:
                                (context) => Dialog(
                                  child: Container(
                                    padding: EdgeInsets.all(12),
                                    child: SpinBox(
                                      textInputAction: TextInputAction.done,
                                      cursorColor: colorProvider.textColor,
                                      enableInteractiveSelection: true,
                                      iconColor: WidgetStateProperty.all<Color>(
                                        colorProvider.textColor,
                                      ),
                                      decoration: InputDecoration(
                                        border: const OutlineInputBorder(
                                          borderRadius: BorderRadius.all(
                                            Radius.circular(20.0),
                                          ),
                                        ),
                                        filled: true,
                                        fillColor: colorProvider.standardColor,
                                        labelStyle: TextStyle(
                                          fontSize: 16.0,
                                          fontWeight: FontWeight.bold,
                                          color: colorProvider.textColor,
                                        ),
                                        labelText: localizations.amount,
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            15.0,
                                          ),
                                          borderSide: BorderSide(
                                            color:
                                                colorProvider
                                                    .colorScheme
                                                    .strokeColor,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.all(
                                            Radius.circular(20.0),
                                          ),
                                          borderSide: BorderSide(
                                            color:
                                                colorProvider
                                                    .colorScheme
                                                    .strokeColor,
                                          ),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              vertical: 20,
                                              horizontal: 20,
                                            ),
                                      ),
                                      min: 2,
                                      max: 9999,
                                      value: wheelValue.toDouble(),
                                      onChanged: (value) {
                                        setState(() {
                                          wheelValue = value.toInt();
                                        });
                                      },
                                    ),
                                  ),
                                ),
                          ),
                      child: Text(
                        wheelValue.toString(),
                        style: TextStyle(
                          fontSize: 56,
                          height: 0,
                          fontWeight: FontWeight.bold,
                          color: colorProvider.textColor,
                        ),
                      ),
                    ),
                    TipText(
                      width: width,
                      localizations: localizations,
                      colorProvider: colorProvider,
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
  });

  final double width;
  final AppLocalizations localizations;
  final ColorProvider colorProvider;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width / 2,
      child: Text(
        localizations.youCanPressNumberAbove,
        style: TextStyle(color: colorProvider.textColor),
      ),
    );
  }
}
