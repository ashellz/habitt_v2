import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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
        gapScaleFactor: 0.05,
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
        height: height,
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
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  padZero ? index.toString().padLeft(2, '0') : index.toString(),
                  style:
                      textStyle ??
                      TextStyle(fontSize: 44.0, color: tp.primaryTextColor),
                ),
              ),
            ),
          ),
        ),
      );
    }

    Widget minutesPickerCupertino() {
      return SizedBox(
        width: width / 3,
        height: height,
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
              child: FittedBox(
                fit: BoxFit.scaleDown,
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
        ),
      );
    }

    if (vertical) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (maxHours != null && maxHours! > 0) ...[
            hoursPickerCupertino(),
            Text(
              "hours",
              style: TextStyle(
                color: textStyle?.color ?? tp.primaryTextColor,
                fontSize: 16,
                shadows: textStyle?.shadows,
              ),
            ),
            Divider(
              color: textStyle?.color ?? tp.primaryTextColor,
              thickness: 3,
            ),
            Text(
              "minutes",
              style: TextStyle(
                shadows: textStyle?.shadows,
                color: textStyle?.color ?? tp.primaryTextColor,
                fontSize: 16,
              ),
            ),
          ],
          minutesPickerCupertino(),
          if (maxHours == null || maxHours! < 1)
            Text(
              "minutes",
              style: TextStyle(
                shadows: textStyle?.shadows,
                color: textStyle?.color ?? tp.primaryTextColor,
                fontSize: 16,
              ),
            ),
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
  double lastVelocityX = 0;
  bool _isFling = false;
  double _flingStart = 0;
  double _flingEnd = 0;
  int currentSnap = 0;
  bool _didInitialSnap = false;
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _didInitialSnap) return;
      _didInitialSnap = true;
      _snapToIndex(widget.initialIndex);
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant CustomPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    // When the number of items changes (e.g., max minutes lowers), clamp the
    // scroll position and snap to the nearest valid item so the UI reflects
    // the new bounds without user interaction.
    if (oldWidget.children.length != widget.children.length) {
      final newMaxIndex =
          widget.children.isNotEmpty ? widget.children.length - 1 : 0;
      final clampedIndex = currentSnap.clamp(0, newMaxIndex);
      currentScrollX = _positionForIndex(clampedIndex);
      oldAnimScrollX = currentScrollX;
      animDistance = 0;
      currentSnap = clampedIndex;
      _buildPositions();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _lookForSnappoint();
      });
    }
  }

  void _snapToIndex(int index) {
    currentScrollX = _positionForIndex(index);
    oldAnimScrollX = currentScrollX;
    animDistance = 0;
    currentSnap = index;
    _buildPositions();
    _lookForSnappoint();
  }

  void _initController() {
    controller =
        AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 200),
            lowerBound: 0,
            upperBound: 1,
          )
          ..addListener(() {
            setState(() {
              if (_isFling) {
                // Decelerate during fling for visible slowdown
                final t = Curves.decelerate.transform(controller.value);
                currentScrollX = _flingStart + t * (_flingEnd - _flingStart);
              } else {
                // Ease out when snapping to center
                final t = Curves.easeOutCubic.transform(controller.value);
                currentScrollX = oldAnimScrollX + t * animDistance;
              }
              _buildPositions();
            });
          })
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed && _isFling) {
              _isFling = false;
              _lookForSnappoint();
            }
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
      final isNeighbor = (i - currentSnap).abs() == 1;
      final opacity = isNeighbor ? 0.5 : 1.0;

      scrollableContainer.add(
        Positioned(
          left: leftPos,
          top: 0,
          child: Opacity(
            opacity: opacity,
            child: SizedBox(
              height: widget.containerHeight,
              width: widget.containerWidth,
              child: widget.children[i],
            ),
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
    // Adjust animation duration based on distance and recent flick velocity
    final baseMs = 200;
    final extraMsFromDistance =
        (animDistance.abs() * 1.2).clamp(0, 800).toInt();
    final extraMsFromVelocity =
        (lastVelocityX.abs() * 0.05).clamp(0, 600).toInt();
    final totalMs = (baseMs + extraMsFromDistance + extraMsFromVelocity).clamp(
      200,
      1200,
    );
    controller.duration = Duration(milliseconds: totalMs);
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
            // Increase sensitivity slightly to feel more like Cupertino
            currentScrollX -= dragUpdateDetails.delta.dx * 1.25;
            _buildPositions();
          });
        },
        onPanEnd: (details) {
          lastVelocityX = details.velocity.pixelsPerSecond.dx;
          // Project a bit farther and slow down via curve
          final projected = (currentScrollX - lastVelocityX * 0.35).clamp(
            0,
            _scrollableLength - widget.containerWidth,
          );
          _flingStart = currentScrollX;
          _flingEnd = projected.toDouble();
          _isFling = true;
          // Longer duration to make slowdown clearly visible
          final flingMs = (lastVelocityX.abs() * 0.35).clamp(400, 1400).toInt();
          controller.duration = Duration(milliseconds: flingMs);
          controller.reset();
          controller.forward();
        },
        behavior: HitTestBehavior.translucent,
        child: Stack(children: scrollableContainer),
      ),
    );
  }
}
