import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The check of a habit completed with a lighter goal for the day: a dashed
/// ring and a check in [color] instead of the filled checkmark, so a lighter
/// day reads differently from a full one. See docs/goal_check_in.md.
class LighterDayBadge extends StatelessWidget {
  const LighterDayBadge({super.key, required this.color, this.size = 24});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Completed with a lighter goal',
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _LighterDayPainter(color)),
      ),
    );
  }
}

class _LighterDayPainter extends CustomPainter {
  const _LighterDayPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final center = size.center(Offset.zero);
    final radius = s / 2 - 1;
    final ring =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..strokeCap = StrokeCap.round
          ..color = color;

    // 12 dashes around the ring
    const dashes = 12;
    const sweep = 2 * math.pi / dashes;
    final rect = Rect.fromCircle(center: center, radius: radius);
    for (var i = 0; i < dashes; i++) {
      canvas.drawArc(rect, i * sweep - math.pi / 2, sweep * 0.55, false, ring);
    }

    final check =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = color;
    final path =
        Path()
          ..moveTo(s * 0.30, s * 0.52)
          ..lineTo(s * 0.44, s * 0.65)
          ..lineTo(s * 0.70, s * 0.38);
    canvas.drawPath(path, check);
  }

  @override
  bool shouldRepaint(covariant _LighterDayPainter oldDelegate) =>
      oldDelegate.color != color;
}
