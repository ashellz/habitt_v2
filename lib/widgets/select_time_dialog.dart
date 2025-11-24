import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:habitt/providers/theme_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/widgets/blur_circle_button.dart';
import 'package:habitt/widgets/glass_feel_container.dart';
import 'package:provider/provider.dart';

class SelectTimeDialog extends StatefulWidget {
  const SelectTimeDialog({
    super.key,
    required this.isStartTime,
    required this.stateProvider,
  });

  final bool isStartTime;
  final StateProvider stateProvider;

  @override
  State<SelectTimeDialog> createState() => _SelectTimeDialogState();
}

class _SelectTimeDialogState extends State<SelectTimeDialog> {
  FixedExtentScrollController hoursController = FixedExtentScrollController();
  FixedExtentScrollController minutesController = FixedExtentScrollController();

  @override
  void initState() {
    super.initState();

    setState(() {
      hoursController = FixedExtentScrollController(
        initialItem:
            widget.isStartTime
                ? widget.stateProvider.timeIntervalStart ~/ 60
                : widget.stateProvider.timeIntervalEnd ~/ 60,
      );
      minutesController = FixedExtentScrollController(
        initialItem:
            widget.isStartTime
                ? widget.stateProvider.timeIntervalStart % 60
                : widget.stateProvider.timeIntervalEnd % 60,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final sp = context.watch<StateProvider>();
    final tp = context.watch<ThemeProvider>();
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
                      widget.isStartTime ? "Start time" : "End time",
                      style: TextStyle(
                        color: tp.primaryTextColor,
                        fontSize: 18,
                      ),
                    ),
                    SizedBox(height: 8),
                    Stack(
                      children: [
                        TimeGradient(color: tp.backgroundColor),
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
                    tp: tp,
                    icon: Icon(Icons.check, color: Colors.white),
                    color: tp.primaryColor,
                    onPressed: () {
                      final hours = hoursController.selectedItem % 24;
                      final minutes = minutesController.selectedItem % 60;
                      final time = hours * 60 + minutes;

                      if (widget.isStartTime) {
                        sp.timeIntervalStart = time;
                      } else if (!widget.isStartTime) {
                        sp.timeIntervalEnd = time;
                      }

                      Navigator.pop(context);
                    },
                  ),
                  SizedBox(height: 4),
                  CircleButton(
                    tp: tp,
                    icon: Icon(Icons.close, color: tp.primaryTextColor),
                    color: tp.primaryColor,
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
    final tp = context.watch<ThemeProvider>();

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
                  style: TextStyle(fontSize: 44.0, color: tp.primaryTextColor),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(bottom: 16.0),
          child: Text(
            ":",
            style: TextStyle(fontSize: 44.0, color: tp.primaryTextColor),
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
                    color: tp.primaryTextColor,
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
    final tp = context.watch<ThemeProvider>();

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [color, tp.backgroundColor.withValues(alpha: 0), color],
          ),
        ),
      ),
    );
  }
}
