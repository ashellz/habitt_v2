import 'package:flutter/cupertino.dart';
import 'package:habitt/providers/theme_provider.dart';
import 'package:provider/provider.dart';

class NumberPicker extends StatelessWidget {
  const NumberPicker({
    super.key,
    required this.hoursController,
    required this.minutesController,
    required this.width,
    this.height = 150,
    this.maxHours,
    this.maxMinutes,
    this.onChangedHours,
    this.onChangedMinutes,
    this.looping = true,
    this.vertical = false,
    this.textStyle,
    this.padZero = true,
  });

  final FixedExtentScrollController hoursController;
  final FixedExtentScrollController minutesController;
  final double width;
  final double height;
  final int? maxHours;
  final int? maxMinutes;
  final ValueChanged<int>? onChangedHours;
  final ValueChanged<int>? onChangedMinutes;
  final bool looping;
  final bool vertical;
  final TextStyle? textStyle;
  final bool padZero;

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    debugPrint(
      "Building NumberPicker with maxHours: $maxHours, maxMinutes: $maxMinutes",
    );

    int safeInitial(int idx, int max) => idx.clamp(0, max);

    Widget customPicker({
      required int itemCount,
      required int initialIndex,
      required ValueChanged<int>? onChanged,
      double? pickerWidth,
      double? pickerHeight,
      double containerWidth = 72,
      double containerHeight = 100,
    }) {
      final items = List<Widget>.generate(
        itemCount,
        (index) => Center(
          child: Text(
            padZero ? index.toString().padLeft(2, '0') : index.toString(),
            style:
                textStyle ??
                TextStyle(
                  fontSize: 32.0,
                  color: tp.primaryTextColor,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
      );

      return CustomPicker(
        width: pickerWidth ?? width / 3,
        height: pickerHeight ?? 150,
        containerWidth: containerWidth,
        containerHeight: containerHeight,
        gapScaleFactor: 0.15,
        initialIndex: safeInitial(initialIndex, itemCount - 1),
        onSnap: (idx) {
          if (onChanged != null) onChanged(idx);
        },
        children: items,
      );
    }

    Widget hoursPickerCustom({double? pickerWidth, double? pickerHeight}) {
      return customPicker(
        itemCount: (maxHours ?? 23) + 1,
        initialIndex: hoursController.initialItem,
        onChanged: onChangedHours,
        pickerWidth: pickerWidth,
        pickerHeight: pickerHeight,
      );
    }

    Widget minutesPickerCustom({double? pickerWidth, double? pickerHeight}) {
      return customPicker(
        itemCount: (maxMinutes ?? 59) + 1,
        initialIndex: minutesController.initialItem,
        onChanged: onChangedMinutes,
        pickerWidth: pickerWidth,
        pickerHeight: pickerHeight,
      );
    }

    Widget hoursPickerCupertino() {
      return SizedBox(
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
            if (onChangedHours != null) onChangedHours!(index);
          },
          children: List<Widget>.generate(
            maxHours != null ? maxHours! + 1 : 24,
            (index) => Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                padZero ? index.toString().padLeft(2, '0') : index.toString(),
                style:
                    textStyle ??
                    TextStyle(fontSize: 44.0, color: tp.primaryTextColor),
              ),
            ),
          ),
        ),
      );
    }

    Widget minutesPickerCupertino() {
      return SizedBox(
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
            if (onChangedMinutes != null) onChangedMinutes!(index);
          },
          children: List<Widget>.generate(
            maxMinutes != null ? maxMinutes! + 1 : 60,
            (index) => Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                padZero ? index.toString().padLeft(2, '0') : index.toString(),
                style:
                    textStyle ??
                    TextStyle(
                      fontSize: 44.0,
                      color: tp.primaryTextColor,
                      fontWeight: FontWeight.w400,
                    ),
              ),
            ),
          ),
        ),
      );
    }

    if (vertical) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (maxHours != null && maxHours! > 0) ...[
            hoursPickerCustom(pickerHeight: height, pickerWidth: width),
          ],
          minutesPickerCustom(pickerHeight: height, pickerWidth: width),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (maxHours != null && maxHours! > 0) ...[
          hoursPickerCupertino(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              ":",
              style: TextStyle(fontSize: 36.0, color: tp.primaryTextColor),
            ),
          ),
        ],
        minutesPickerCupertino(),
      ],
    );
  }
}

class CustomPicker extends StatefulWidget {
  const CustomPicker({
    super.key,
    required this.width,
    required this.height,
    required this.containerWidth,
    required this.containerHeight,
    required this.gapScaleFactor,
    required this.children,
    required this.onSnap,
    this.initialIndex = 0,
  });

  final double width;
  final double height;
  final double containerWidth;
  final double containerHeight;
  final double gapScaleFactor;
  final List<Widget> children;
  final int initialIndex;
  final ValueChanged<int> onSnap;

  @override
  State<CustomPicker> createState() => _CustomPickerState();
}

class _CustomPickerState extends State<CustomPicker>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  double currentScrollX = 0;
  double oldAnimScrollX = 0;
  double animDistance = 0;
  int currentSnap = 0;
  final List<Positioned> scrollableContainer = [];

  double get _scrollableLength =>
      (widget.containerWidth + widget.containerWidth * widget.gapScaleFactor) *
          widget.children.length -
      widget.containerWidth * widget.gapScaleFactor;

  @override
  void initState() {
    super.initState();
    _initController();
    _jumpToInitial(widget.initialIndex);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _initController() {
    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      lowerBound: 0,
      upperBound: 1,
    )..addListener(() {
      setState(() {
        currentScrollX = oldAnimScrollX + controller.value * animDistance;
        _buildPositions();
      });
    });
  }

  void _jumpToInitial(int index) {
    currentScrollX = _positionForIndex(index);
    _buildPositions();
  }

  double _positionForIndex(int index) {
    final spacing = widget.containerWidth * (1 + widget.gapScaleFactor);
    // Align so that the chosen index is centered.
    final centerOffset = widget.width / 2 - widget.containerWidth / 2;
    return spacing * index - centerOffset;
  }

  void _buildPositions() {
    scrollableContainer.clear();
    if (currentScrollX < 0) currentScrollX = 0;
    if (currentScrollX > _scrollableLength - widget.containerWidth) {
      currentScrollX = _scrollableLength - widget.containerWidth;
    }

    for (int i = 0; i < widget.children.length; i++) {
      final leftPos =
          widget.width / 2 -
          widget.containerWidth / 2 -
          currentScrollX +
          widget.containerWidth * i +
          widget.containerWidth * widget.gapScaleFactor * i;
      final mid = widget.width / 2 - widget.containerWidth / 2;
      scrollableContainer.add(
        Positioned(
          left: leftPos,
          top: 0,
          child: SizedBox(
            height: widget.containerHeight,
            width: widget.containerWidth,
            child: widget.children[i],
          ),
        ),
      );
    }
  }

  void _lookForSnappoint() {
    double distance = double.maxFinite;
    double animVal = 0;
    int index = 0;
    for (int i = 0; i < scrollableContainer.length; i++) {
      final snappoint = widget.width / 2 - widget.containerWidth / 2;
      final currentLeftPos =
          widget.width / 2 -
          widget.containerWidth / 2 -
          currentScrollX +
          widget.containerWidth * i +
          widget.containerWidth * widget.gapScaleFactor * i;
      if ((currentLeftPos - snappoint).abs() < distance) {
        distance = (currentLeftPos - snappoint).abs();
        animVal = currentLeftPos - snappoint;
        index = i;
      }
    }
    animDistance = animVal;
    oldAnimScrollX = currentScrollX;
    controller.reset();
    controller.forward();
    currentSnap = index;
    widget.onSnap(index);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: GestureDetector(
        onPanUpdate: (DragUpdateDetails dragUpdateDetails) {
          setState(() {
            currentScrollX -= dragUpdateDetails.delta.dx;
            _buildPositions();
          });
        },
        onPanEnd: (_) => _lookForSnappoint(),
        behavior: HitTestBehavior.translucent,
        child: Stack(children: scrollableContainer),
      ),
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
