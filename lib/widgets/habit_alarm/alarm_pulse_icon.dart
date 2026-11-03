import 'package:flutter/material.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:provider/provider.dart';

/// The habit's emoji in an accent circle with rings pulsing out of it while
/// the alarm rings.
class AlarmPulseIcon extends StatefulWidget {
  const AlarmPulseIcon({super.key, required this.emoji});

  final String emoji;

  @override
  State<AlarmPulseIcon> createState() => _AlarmPulseIconState();
}

class _AlarmPulseIconState extends State<AlarmPulseIcon>
    with SingleTickerProviderStateMixin {
  static const double _iconSize = 120;
  static const double _maxSize = 220;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();

    return SizedBox.square(
      dimension: _maxSize,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // two rings, half a cycle apart
              for (final offset in const [0.0, 0.5])
                _ring(cp, (_controller.value + offset) % 1),
              child!,
            ],
          );
        },
        child: Container(
          width: _iconSize,
          height: _iconSize,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: cp.mainTint,
            border: Border.all(color: cp.mainBorder, width: 2),
          ),
          child: Text(widget.emoji, style: const TextStyle(fontSize: 56)),
        ),
      ),
    );
  }

  Widget _ring(ColorProvider cp, double t) {
    final eased = Curves.easeOut.transform(t);
    final size = _iconSize + (_maxSize - _iconSize) * eased;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: cp.main.withValues(alpha: 0.12 * (1 - t)),
      ),
    );
  }
}
