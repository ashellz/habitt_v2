import 'package:flutter/material.dart';

class NewDefaultSwitch extends StatefulWidget {
  const NewDefaultSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.width = 56,
    this.height = 32,
    this.padding = 4,
    this.thumbSize = 24,
    this.activeColor = const Color(0xFF0B0B0B),
    this.inactiveColor = const Color(0xFFE1E3E6),
    this.thumbColor = Colors.white,
    this.animationDuration = const Duration(milliseconds: 220),
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  final double width;
  final double height;
  final double padding;
  final double thumbSize;

  final Color activeColor;
  final Color inactiveColor;
  final Color thumbColor;

  final Duration animationDuration;

  @override
  State<NewDefaultSwitch> createState() => _NewDefaultSwitchState();
}

class _NewDefaultSwitchState extends State<NewDefaultSwitch> {
  double? _dragRatio;

  double get _minThumbLeft => widget.padding;
  double get _maxThumbLeft => widget.width - widget.padding - widget.thumbSize;

  double _ratioToLeft(double ratio) {
    return _minThumbLeft + (_maxThumbLeft - _minThumbLeft) * ratio;
  }

  double _leftToRatio(double left) {
    final travel = _maxThumbLeft - _minThumbLeft;
    if (travel <= 0) return widget.value ? 1 : 0;
    return ((left - _minThumbLeft) / travel).clamp(0.0, 1.0);
  }

  void _toggle() {
    widget.onChanged(!widget.value);
  }

  @override
  Widget build(BuildContext context) {
    final visualRatio = _dragRatio ?? (widget.value ? 1.0 : 0.0);
    final thumbLeft = _ratioToLeft(visualRatio);

    return Semantics(
      toggled: widget.value,
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _toggle,
        onHorizontalDragStart: (_) {
          _dragRatio = widget.value ? 1.0 : 0.0;
          setState(() {});
        },
        onHorizontalDragUpdate: (details) {
          final currentLeft = _ratioToLeft(
            _dragRatio ?? (widget.value ? 1.0 : 0.0),
          );
          final nextLeft = (currentLeft + details.delta.dx).clamp(
            _minThumbLeft,
            _maxThumbLeft,
          );
          setState(() {
            _dragRatio = _leftToRatio(nextLeft);
          });
        },
        onHorizontalDragEnd: (_) {
          final ratio = _dragRatio ?? (widget.value ? 1.0 : 0.0);
          final nextValue = ratio >= 0.5;
          _dragRatio = null;
          if (nextValue != widget.value) {
            widget.onChanged(nextValue);
          } else {
            setState(() {});
          }
        },
        onHorizontalDragCancel: () {
          setState(() {
            _dragRatio = null;
          });
        },
        child: AnimatedContainer(
          duration: widget.animationDuration,
          curve: Curves.easeOutCubic,
          width: widget.width,
          height: widget.height,
          padding: EdgeInsets.all(widget.padding),
          decoration: ShapeDecoration(
            color:
                visualRatio > 0.5 ? widget.activeColor : widget.inactiveColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(100),
            ),
          ),
          child: Stack(
            children: [
              AnimatedPositioned(
                duration:
                    _dragRatio == null
                        ? widget.animationDuration
                        : Duration.zero,
                curve: Curves.easeOutCubic,
                left: thumbLeft - widget.padding,
                top: 0,
                child: Container(
                  width: widget.thumbSize,
                  height: widget.thumbSize,
                  decoration: ShapeDecoration(
                    color: widget.thumbColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(68.57),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
