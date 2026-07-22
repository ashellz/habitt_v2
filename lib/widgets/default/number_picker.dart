import 'package:flutter/cupertino.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:provider/provider.dart';

class NumberPicker extends StatefulWidget {
  const NumberPicker({
    super.key,
    required this.hoursController,
    required this.minutesController,
    required this.width,
    this.height = 211,
    this.minHours,
    this.maxHours,
    this.maxMinutes,
    this.onChangedHours,
    this.onChangedMinutes,
    this.secondsController,
    this.maxSeconds,
    this.onChangedSeconds,
    this.looping = true,
    this.vertical = false,
    this.textStyle,
    this.padZero = true,
  });

  final FixedExtentScrollController hoursController;
  final FixedExtentScrollController minutesController;
  final double width;
  final double height;
  final int? minHours;
  final int? maxHours;
  final int? maxMinutes;
  final ValueChanged<int>? onChangedHours;
  final ValueChanged<int>? onChangedMinutes;

  /// Optional third column for seconds. When null, the picker renders only the
  /// hours:minutes columns (unchanged behavior).
  final FixedExtentScrollController? secondsController;
  final int? maxSeconds;
  final ValueChanged<int>? onChangedSeconds;

  final bool looping;
  final bool vertical;
  final TextStyle? textStyle;
  final bool padZero;

  @override
  State<NumberPicker> createState() => _NumberPickerState();
}

class _NumberPickerState extends State<NumberPicker> {
  late int minHour;
  late int maxHour;
  late int hourItemCount;

  @override
  void initState() {
    super.initState();

    debugPrint(
      "Initializing NumberPicker with controller: ${widget.hoursController.initialItem}, ${widget.minutesController.initialItem} ",
    );

    minHour = widget.minHours ?? 0;
    maxHour = widget.maxHours ?? 23;
    hourItemCount = (maxHour - minHour + 1).clamp(1, 24);

    _clampHoursController();
  }

  void _clampHoursController() {
    // Use the provided initialItem and clamp to the allowed hour window.
    final int clampedValue =
        widget.hoursController.initialItem.clamp(minHour, maxHour).toInt();
    final int relativeIndex = _safeInitial(
      clampedValue - minHour,
      hourItemCount - 1,
    );

    // Defer until after first layout so the controller has clients, then jump.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.hoursController.hasClients) {
        widget.hoursController.jumpToItem(relativeIndex);
      }
    });
  }

  int _safeInitial(int idx, int max) => idx.clamp(0, max).toInt();

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    debugPrint(
      "Building NumberPicker with maxHours: ${widget.maxHours}, maxMinutes: ${widget.maxMinutes}",
    );

    Widget hoursPickerCupertino() {
      return SizedBox(
        width: 49,
        height: widget.height,
        child: CupertinoPicker(
          looping: widget.looping,
          scrollController: widget.hoursController,
          itemExtent: 67,
          useMagnifier: false,

          selectionOverlay: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(color: cp.border, height: 1),
              Container(color: cp.border, height: 1),
            ],
          ),
          onSelectedItemChanged: (int index) {
            final value = minHour + index;
            if (widget.onChangedHours != null) widget.onChangedHours!(value);
            debugPrint("Selected hour index: $index, value: $value");
          },
          children: List<Widget>.generate(
            hourItemCount,
            (index) => Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  widget.padZero
                      ? (minHour + index).toString().padLeft(2, '0')
                      : (minHour + index).toString(),
                  style:
                      widget.textStyle ??
                      TextStyle(
                        color: cp.text,
                        fontSize: 32,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    Widget minutesPickerCupertino() {
      return SizedBox(
        width: 49,
        height: widget.height,
        child: CupertinoPicker(
          looping: widget.looping,
          scrollController: widget.minutesController,
          itemExtent: 67,
          useMagnifier: false,
          selectionOverlay: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(color: cp.border, height: 1),
              Container(color: cp.border, height: 1),
            ],
          ),
          onSelectedItemChanged: (int index) {
            if (widget.onChangedMinutes != null) {
              widget.onChangedMinutes!(index);
            }
            debugPrint("Selected minute index: $index");
          },
          children: List<Widget>.generate(
            widget.maxMinutes != null ? widget.maxMinutes! + 1 : 60,
            (index) => Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  widget.padZero
                      ? index.toString().padLeft(2, '0')
                      : index.toString(),
                  style:
                      widget.textStyle ??
                      TextStyle(
                        color: cp.text,
                        fontSize: 32,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    Widget secondsPickerCupertino() {
      return SizedBox(
        width: 49,
        height: widget.height,
        child: CupertinoPicker(
          looping: widget.looping,
          scrollController: widget.secondsController!,
          itemExtent: 67,
          useMagnifier: false,
          selectionOverlay: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(color: cp.border, height: 1),
              Container(color: cp.border, height: 1),
            ],
          ),
          onSelectedItemChanged: (int index) {
            if (widget.onChangedSeconds != null) {
              widget.onChangedSeconds!(index);
            }
          },
          children: List<Widget>.generate(
            widget.maxSeconds != null ? widget.maxSeconds! + 1 : 60,
            (index) => Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  widget.padZero
                      ? index.toString().padLeft(2, '0')
                      : index.toString(),
                  style:
                      widget.textStyle ??
                      TextStyle(
                        color: cp.text,
                        fontSize: 32,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    Widget separator() {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Text(
          ":",
          style: TextStyle(
            color: cp.text,
            fontSize: 32,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 20,
      children: [
        hoursPickerCupertino(),
        separator(),
        minutesPickerCupertino(),
        if (widget.secondsController != null) ...[
          separator(),
          secondsPickerCupertino(),
        ],
      ],
    );
  }
}
