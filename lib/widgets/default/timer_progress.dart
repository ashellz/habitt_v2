import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:tinycolor2/tinycolor2.dart';

void _paintTipShadow(
  Canvas canvas,
  Offset tip,
  Offset leading,
  double strokeWidth, {
  double opacity = 1.0,
  required bool isDark,
}) {
  final shadowScale = math.max(strokeWidth, 8.0);
  final trailing = Offset(-leading.dx, -leading.dy);
  final shadowCenter = tip + trailing * (shadowScale * 0.30);

  final shadowColor = isDark ? Colors.black : Colors.white;
  canvas.drawCircle(
    shadowCenter,
    shadowScale * 0.62,
    Paint()
      ..color = shadowColor.withValues(alpha: 0.55 * opacity)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, shadowScale * 0.5),
  );
}

class TimerRingIndicator extends StatelessWidget {
  const TimerRingIndicator({
    super.key,
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.isDark,
    this.strokeWidth = 10,
    this.lapSeconds = 60,
  });

  final double progress;
  final Color color;
  final Color trackColor;
  final double strokeWidth;
  final double lapSeconds;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: progress),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.linear,
      builder: (context, value, _) {
        return CustomPaint(
          painter: _RingPainter(
            progress: value,
            color: color,
            trackColor: trackColor,
            strokeWidth: strokeWidth,
            lapSeconds: lapSeconds,
            isDark: isDark,
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
    required this.lapSeconds,
    required this.isDark,
  });

  final double progress;
  final Color color;
  final Color trackColor;
  final double lapSeconds;
  final double strokeWidth;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const start = -math.pi / 2;

    Paint strokePaint() =>
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

    // track circle (background ring)
    canvas.drawCircle(center, radius, strokePaint()..color = trackColor);

    if (progress <= 0) return;

    final laps = progress.floor();
    final fraction = progress - laps;
    final overtime = laps >= 1;
    final tipFraction = overtime ? (fraction == 0 ? 1.0 : fraction) : fraction;
    final sweep = 2 * math.pi * tipFraction;

    final tipColor = isDark ? color.darken(20) : color.lighten(20);

    // if you can't understand the complexity of this code message me directly
    // it is too complex to be written down lol

    const glowSeconds = 1.85;
    const gradientSeconds = 1.30;
    final glowWindow =
        lapSeconds > 0 ? (glowSeconds / lapSeconds).clamp(0.0, 0.9) : 0.06;
    final gradientWindow =
        lapSeconds > 0 ? (gradientSeconds / lapSeconds).clamp(0.0, 0.9) : 0.06;
    final glowT = (fraction / glowWindow).clamp(0.0, 1.0);
    final gradientT = (fraction / gradientWindow).clamp(0.0, 1.0);
    final arcStartColor =
        overtime ? Color.lerp(tipColor, color, gradientT)! : color;

    // gradient for the progress arc, brighter/darker at the tip
    final gradient =
        strokePaint()
          ..strokeCap = StrokeCap.butt
          ..shader = SweepGradient(
            startAngle: 0,
            endAngle: sweep == 0 ? 2 * math.pi : sweep,
            colors: [arcStartColor, tipColor],
            transform: const GradientRotation(start),
          ).createShader(rect);

    final tipAngle = start + sweep;
    final tip = Offset(
      center.dx + radius * math.cos(tipAngle),
      center.dy + radius * math.sin(tipAngle),
    );
    final leading = Offset(-math.sin(tipAngle), math.cos(tipAngle));
    final tipCapPaint = Paint()..color = tipColor;

    if (!overtime) {
      canvas.drawArc(rect, start, sweep, false, gradient);
      canvas.drawCircle(tip, strokeWidth / 2, tipCapPaint);
      return;
    }

    // overtime: completed solid cirlce
    canvas.drawArc(
      rect,
      start,
      2 * math.pi,
      false,
      strokePaint()..color = color,
    );

    // after the progress arc finishes its circle it pops and creatses a new one
    // that makes the background ring appear instantly with the green color instead of the gradient
    // this circle is the gradient circle that appears for a short period and faded away to provide a smooth transition
    if (fraction < glowWindow) {
      final ghostOpacity = 1 - glowT;
      // ghosttip color is the right end of the glow line color
      // we move the color from the brightest to the regular color
      // this is to seemlessly blend the glow gradient color with the progress arc color that just has started
      final ghostTipColor = Color.lerp(tipColor, color, glowT)!;
      canvas.saveLayer(
        rect.inflate(strokeWidth),
        Paint()..color = Colors.white.withValues(alpha: ghostOpacity),
      );
      canvas.drawArc(
        rect,
        start,
        2 * math.pi,
        false,
        strokePaint()
          ..strokeCap = StrokeCap.butt
          ..shader = SweepGradient(
            startAngle: 0,
            endAngle: 2 * math.pi,
            colors: [color, ghostTipColor],
            transform: const GradientRotation(start),
          ).createShader(rect),
      );
      canvas.restore();
    }

    // The shadow sits strokeWidth*0.92 behind the tip (0.30 offset + 0.62
    // radius) — fade it in/out across a margin instead of popping at a hard
    // cutoff, so it doesn't overshoot past the arc's own start when the lap
    // is short and instead eases in as the lap grows (and back out as it
    // resets to near-zero at the next wrap).
    final shadowOpacity = ((sweep * radius - strokeWidth * 0.92) /
            (strokeWidth * 1.58))
        .clamp(0.0, 1.0);

    _paintTipShadow(
      canvas,
      tip,
      leading,
      strokeWidth,
      opacity: shadowOpacity,
      isDark: isDark,
    );

    canvas.drawArc(rect, start, sweep, false, gradient);
    canvas.drawCircle(tip, strokeWidth / 2, tipCapPaint);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.trackColor != trackColor ||
      old.strokeWidth != strokeWidth ||
      old.lapSeconds != lapSeconds ||
      old.isDark != isDark;
}

class TimerStadiumIndicator extends StatelessWidget {
  const TimerStadiumIndicator({
    super.key,
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.isDark,
    this.strokeWidth = 3,
    this.inset = 2,
    this.lapSeconds = 60,
  });

  final double progress;
  final Color color;
  final Color trackColor;
  final double strokeWidth;
  final double inset;
  final double lapSeconds;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: progress),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.linear,
      builder: (context, value, _) {
        return CustomPaint(
          painter: _StadiumPainter(
            progress: value,
            color: color,
            trackColor: trackColor,
            strokeWidth: strokeWidth,
            inset: inset,
            lapSeconds: lapSeconds,
            isDark: isDark,
          ),
        );
      },
    );
  }
}

class _StadiumPainter extends CustomPainter {
  _StadiumPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
    required this.inset,
    required this.lapSeconds,
    required this.isDark,
  });

  final double progress;
  final Color color;
  final Color trackColor;
  final double strokeWidth;
  final double inset;
  final double lapSeconds;
  final bool isDark;

  Path _stadiumPath(Rect rect) {
    final radius = rect.shortestSide / 2;
    return Path()
      ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));
  }

  @override
  void paint(Canvas canvas, Size size) {
    // same paint logic as the ring above

    if (size.width <= 0 || size.height <= 0) return;
    final gap = inset + strokeWidth / 2;
    final rect = Rect.fromLTWH(
      gap,
      gap,
      size.width - gap * 2,
      size.height - gap * 2,
    );
    final path = _stadiumPath(rect);

    Paint strokePaint() =>
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, strokePaint()..color = trackColor);

    if (progress <= 0) return;

    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;
    final metric = metrics.first;
    final len = metric.length;

    final laps = progress.floor();
    final fraction = progress - laps;
    final overtime = laps >= 1;
    final tipFraction = overtime ? (fraction == 0 ? 1.0 : fraction) : fraction;
    final progLen = len * tipFraction;

    final tipColor = isDark ? color.darken(20) : color.lighten(20);

    const glowSeconds = 0.35;
    const gradientSeconds = 0.35;
    final glowWindow =
        lapSeconds > 0 ? (glowSeconds / lapSeconds).clamp(0.0, 0.9) : 0.06;
    final gradientWindow =
        lapSeconds > 0 ? (gradientSeconds / lapSeconds).clamp(0.0, 0.9) : 0.06;
    final glowT = (fraction / glowWindow).clamp(0.0, 1.0);
    final gradientT = (fraction / gradientWindow).clamp(0.0, 1.0);
    final arcStartColor =
        overtime ? Color.lerp(tipColor, color, gradientT)! : color;

    final gradient =
        strokePaint()
          ..strokeCap = StrokeCap.butt
          ..shader = LinearGradient(
            colors: [arcStartColor, tipColor],
          ).createShader(rect);

    final tan = metric.getTangentForOffset(progLen);
    final tipCapPaint = Paint()..color = tipColor;

    if (!overtime) {
      canvas.drawPath(metric.extractPath(0, progLen), gradient);
      if (tan != null) {
        canvas.drawCircle(tan.position, strokeWidth / 2, tipCapPaint);
      }
      return;
    }

    canvas.drawPath(metric.extractPath(0, len), strokePaint()..color = color);

    if (fraction < glowWindow) {
      final ghostOpacity = 1 - glowT;

      final ghostTipColor = Color.lerp(tipColor, color, glowT)!;
      canvas.saveLayer(
        rect.inflate(strokeWidth),
        Paint()..color = Colors.white.withValues(alpha: ghostOpacity),
      );
      canvas.drawPath(
        metric.extractPath(0, len),
        strokePaint()
          ..strokeCap = StrokeCap.butt
          ..shader = LinearGradient(
            colors: [color, ghostTipColor],
          ).createShader(rect),
      );
      canvas.restore();
    }

    final shadowMargin = strokeWidth * 0.5;
    final shadowStart = shadowMargin;
    final shadowEnd = math.max(shadowStart, progLen - shadowMargin);
    final shadowBandColor = isDark ? Colors.black : Colors.white;
    canvas.drawPath(
      metric.extractPath(shadowStart, shadowEnd),
      strokePaint()
        ..strokeCap = StrokeCap.butt
        ..color = shadowBandColor.withValues(alpha: 0.28)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, strokeWidth * 0.6),
    );

    final shadowOpacity =
        ((progLen - strokeWidth * 0.92) / (strokeWidth * 1.58)).clamp(0.0, 1.0);
    if (tan != null) {
      _paintTipShadow(
        canvas,
        tan.position,
        tan.vector,
        strokeWidth,
        opacity: shadowOpacity,
        isDark: isDark,
      );
    }
    canvas.drawPath(metric.extractPath(0, progLen), gradient);
    if (tan != null) {
      canvas.drawCircle(tan.position, strokeWidth / 2, tipCapPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _StadiumPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.trackColor != trackColor ||
      old.strokeWidth != strokeWidth ||
      old.inset != inset ||
      old.lapSeconds != lapSeconds ||
      old.isDark != isDark;
}
