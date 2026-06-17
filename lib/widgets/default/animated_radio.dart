import 'package:flutter/material.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:provider/provider.dart';

/// A circular, animated radio control that works with a shared [groupValue].
///
/// Mirrors the look & feel of [AnimatedCheckbox] but is round and shows an
/// animated inner dot when its [value] matches [groupValue].
class AnimatedRadio<T> extends StatefulWidget {
  const AnimatedRadio({
    super.key,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    this.size = 24,
  });

  /// The value this radio represents.
  final T value;

  /// The currently selected value of the group.
  final T? groupValue;

  /// Called with [value] when this radio is tapped.
  final ValueChanged<T> onChanged;

  final double size;

  bool get _selected => value == groupValue;

  @override
  State<AnimatedRadio<T>> createState() => _AnimatedRadioState<T>();
}

class _AnimatedRadioState<T> extends State<AnimatedRadio<T>>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 180),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    if (widget._selected) _controller.value = 1;
  }

  @override
  void didUpdateWidget(AnimatedRadio<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget._selected != oldWidget._selected) {
      if (widget._selected) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final hslMain = HSLColor.fromColor(cp.main);
    final gradientEnd =
        hslMain
            .withLightness((hslMain.lightness - 0.08).clamp(0.0, 1.0))
            .toColor();

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final t = _animation.value;
        return AnimatedScale(
          scale: _pressed ? 0.92 : 1,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              splashFactory: NoSplash.splashFactory,
              onHighlightChanged: (value) {
                if (!mounted) return;
                setState(() => _pressed = value);
              },
              onTap: () => widget.onChanged(widget.value),
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    width: 1.5,
                    color: Color.lerp(cp.disabled, cp.main, t)!,
                  ),
                ),
                child: Center(
                  child: Transform.scale(
                    scale: t,
                    child: Container(
                      width: widget.size * 0.5,
                      height: widget.size * 0.5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [cp.main, gradientEnd],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
