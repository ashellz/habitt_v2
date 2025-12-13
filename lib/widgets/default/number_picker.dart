import 'package:flutter/cupertino.dart';
import 'package:habitt/providers/theme_provider.dart';
import 'package:provider/provider.dart';

class NumberPicker extends StatelessWidget {
  const NumberPicker({
    super.key,
    required this.hoursController,
    required this.minutesController,
    required this.width,
    this.maxHours,
    this.maxMinutes,
    this.onChangedHours,
    this.onChangedMinutes,
    this.looping = true,
  });

  final FixedExtentScrollController hoursController;
  final FixedExtentScrollController minutesController;
  final double width;
  final int? maxHours;
  final int? maxMinutes;
  final ValueChanged<int>? onChangedHours;
  final ValueChanged<int>? onChangedMinutes;
  final bool looping;

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    debugPrint(
      "Building NumberPicker with maxHours: $maxHours, maxMinutes: $maxMinutes",
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        if (maxHours != null && maxHours! > 0) ...[
          SizedBox(
            width: width / 3,
            height: 150,
            child: CupertinoPicker(
              looping: looping,
              scrollController: hoursController,
              itemExtent: 75.0,
              magnification: 1,
              useMagnifier: false,
              selectionOverlay: Container(),
              onSelectedItemChanged: (int index) {
                print("Selected index: $index");
                if (onChangedHours != null) {
                  onChangedHours!(index);
                }
              },
              children: List<Widget>.generate(
                maxHours != null ? maxHours! + 1 : 24,
                (index) => Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    index.toString().padLeft(2, '0'),
                    style: TextStyle(
                      fontSize: 44.0,
                      color: tp.primaryTextColor,
                    ),
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
        ],
        SizedBox(
          width: width / 3,
          height: 150,

          child: CupertinoPicker(
            looping: looping,
            scrollController: minutesController,
            itemExtent: 75.0,
            magnification: 1.0,
            useMagnifier: false,
            selectionOverlay: Container(),
            onSelectedItemChanged: (int index) {
              print("Selected index: $index");
              if (onChangedMinutes != null) {
                onChangedMinutes!(index);
              }
            },
            children: List<Widget>.generate(
              maxMinutes != null ? maxMinutes! + 1 : 60,
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
