import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/widgets/blur_circle_button.dart';
import 'package:habitt/widgets/glass_feel_container.dart';
import 'package:provider/provider.dart';

class SelectTimeDialog extends StatefulWidget {
  const SelectTimeDialog({super.key});

  @override
  State<SelectTimeDialog> createState() => _SelectTimeDialogState();
}

class _SelectTimeDialogState extends State<SelectTimeDialog> {
  @override
  void initState() {
    super.initState();
  }

  final hoursController = FixedExtentScrollController();
  final minutesController = FixedExtentScrollController();

  @override
  Widget build(BuildContext context) {
    final colorProvider = context.watch<ColorProvider>();
    final width = MediaQuery.of(context).size.width - 200;

    return Dialog(
      backgroundColor:
          Colors.transparent, // Important for the blur to show through
      insetPadding: EdgeInsets.zero,
      child: IntrinsicWidth(
        child: IntrinsicHeight(
          child: Row(
            children: [
              SizedBox(width: 8 + 50),
              GlassFeelContainer(
                width: width,
                child: Column(
                  children: [
                    Text(
                      "Start time",
                      style: TextStyle(
                        color: colorProvider.textColor,
                        fontSize: 18,
                      ),
                    ),
                    SizedBox(height: 8),
                    Stack(
                      children: [
                        TimeGradient(color: colorProvider.backgroundColor),
                        NumberPicker(
                          hoursController: hoursController,
                          minutesController: minutesController,
                          width: width,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8),
              Column(
                children: [
                  CircleButton(
                    colorProvider: colorProvider,
                    icon: Icon(Icons.check, color: Colors.white),
                    color: colorProvider.colorScheme.darkerStandardColor,
                    onPressed: () {
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

class NumberPicker extends StatelessWidget {
  const NumberPicker({
    super.key,
    required this.hoursController,
    required this.minutesController,
    required this.width,
  });

  final FixedExtentScrollController hoursController;
  final FixedExtentScrollController minutesController;
  final double width;

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        SizedBox(
          width: width / 3,
          height: 150,
          child: CupertinoPicker(
            looping: true,
            scrollController: hoursController,
            itemExtent: 75.0,
            magnification: 1,
            useMagnifier: false,
            selectionOverlay: Container(),
            onSelectedItemChanged: (int index) {
              print("Selected index: $index");
            },
            children: List<Widget>.generate(
              24,
              (index) => Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  index.toString().padLeft(2, '0'),
                  style: TextStyle(fontSize: 44.0, color: cp.textColor),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(bottom: 16.0),
          child: Text(
            ":",
            style: TextStyle(fontSize: 44.0, color: cp.textColor),
          ),
        ),
        SizedBox(
          width: width / 3,
          height: 150,

          child: CupertinoPicker(
            looping: true,
            scrollController: minutesController,
            itemExtent: 75.0,
            magnification: 1.0,
            useMagnifier: false,
            selectionOverlay: Container(),
            onSelectedItemChanged: (int index) {
              print("Selected index: $index");
            },
            children: List<Widget>.generate(
              60,
              (index) => Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  index.toString().padLeft(2, '0'),
                  style: TextStyle(
                    fontSize: 44.0,
                    color: cp.textColor,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class TimeGradient extends StatelessWidget {
  const TimeGradient({super.key, required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [color, cp.backgroundColor.withValues(alpha: 0), color],
          ),
        ),
      ),
    );
  }
}
