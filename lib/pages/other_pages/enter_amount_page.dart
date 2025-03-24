import 'package:flutter/material.dart';
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
  int wheelValue = 0;

  void increaseWheelValue() {
    setState(() {
      wheelValue++;
    });
  }

  void decreaseWheelValue() {
    setState(() {
      wheelValue--;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ColorProvider colorProvider = context.watch<ColorProvider>();
    final localizations = AppLocalizations.of(context)!;

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
                    Text(
                      wheelValue.toString(),
                      style: TextStyle(
                        fontSize: 56,
                        height: 0,
                        fontWeight: FontWeight.bold,
                        color: colorProvider.textColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            //Wheel itself
            Stack(
              children: [
                Positioned(
                  left: 100,
                  bottom: -100,
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
