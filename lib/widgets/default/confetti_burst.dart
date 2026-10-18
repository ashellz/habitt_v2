import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A small one-shot confetti pop, drawn in the root overlay so it isn't
/// clipped by cards or lists. Pieces fly out of [origin] (global
/// coordinates) in a cone around
/// [direction] (radians, screen coordinates: 0 = right, -pi/2 = up), travel at
/// most [maxDistance] px, then fade out.
class ConfettiBurst {
  static void show(
    BuildContext context, {
    required Offset origin,
    required List<Color> colors,
    double direction = -3 * math.pi / 4,
    double maxDistance = 100,
  }) {
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) return;
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;
    final overlayBox = overlay.context.findRenderObject() as RenderBox?;
    final localOrigin = overlayBox?.globalToLocal(origin) ?? origin;

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder:
          (_) => _ConfettiBurstOverlay(
            origin: localOrigin,
            colors: colors,
            direction: direction,
            maxDistance: maxDistance,
            onDone: () => entry.remove(),
          ),
    );
    overlay.insert(entry);
  }
}

class _ConfettiBurstOverlay extends StatefulWidget {
  const _ConfettiBurstOverlay({
    required this.origin,
    required this.colors,
    required this.direction,
    required this.maxDistance,
    required this.onDone,
  });

  final Offset origin;
  final List<Color> colors;
  final double direction;
  final double maxDistance;
  final VoidCallback onDone;

  @override
  State<_ConfettiBurstOverlay> createState() => _ConfettiBurstOverlayState();
}

class _ConfettiBurstOverlayState extends State<_ConfettiBurstOverlay>
    with SingleTickerProviderStateMixin {
  static const _particleCount = 14;
  static const _spread = math.pi / 4; // +-45deg around the direction

  late final AnimationController _controller;
  late final List<_Piece> _pieces;

  @override
  void initState() {
    super.initState();
    final rand = math.Random();
    _pieces = List.generate(_particleCount, (i) {
      final angle = widget.direction + (rand.nextDouble() * 2 - 1) * _spread;
      return _Piece(
        angle: angle,
        distance: widget.maxDistance * (0.45 + rand.nextDouble() * 0.55),
        size: Size(4 + rand.nextDouble() * 3, 2.5 + rand.nextDouble() * 1.5),
        spin: (rand.nextDouble() * 2 - 1) * 4 * math.pi,
        color: widget.colors[i % widget.colors.length],
        isCircle: rand.nextDouble() < 0.3,
      );
    });

    _controller =
        AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 800),
          )
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) widget.onDone();
          })
          ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: _ConfettiBurstPainter(
          animation: _controller,
          origin: widget.origin,
          pieces: _pieces,
        ),
      ),
    );
  }
}

class _Piece {
  const _Piece({
    required this.angle,
    required this.distance,
    required this.size,
    required this.spin,
    required this.color,
    required this.isCircle,
  });

  final double angle;
  final double distance;
  final Size size;
  final double spin;
  final Color color;
  final bool isCircle;
}

class _ConfettiBurstPainter extends CustomPainter {
  _ConfettiBurstPainter({
    required this.animation,
    required this.origin,
    required this.pieces,
  }) : super(repaint: animation);

  final Animation<double> animation;
  final Offset origin;
  final List<_Piece> pieces;

  // slight fall once the pieces lose their speed
  static const _gravityDrop = 14.0;

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value;
    final travel = Curves.easeOutCubic.transform(t);
    final opacity = t < 0.5 ? 1.0 : 1 - (t - 0.5) / 0.5;
    final paint = Paint();

    for (final piece in pieces) {
      final position =
          origin +
          Offset(math.cos(piece.angle), math.sin(piece.angle)) *
              (piece.distance * travel) +
          Offset(0, _gravityDrop * t * t);

      paint.color = piece.color.withValues(alpha: opacity.clamp(0.0, 1.0));
      canvas.save();
      canvas.translate(position.dx, position.dy);
      canvas.rotate(piece.angle + piece.spin * t);
      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: piece.size.width,
        height: piece.size.height,
      );
      if (piece.isCircle) {
        canvas.drawCircle(Offset.zero, piece.size.height / 2 + 0.5, paint);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(1)),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiBurstPainter oldDelegate) =>
      oldDelegate.pieces != pieces || oldDelegate.origin != origin;
}
