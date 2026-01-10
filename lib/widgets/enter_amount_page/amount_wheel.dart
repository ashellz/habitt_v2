import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/physics.dart';
import 'package:habitt/providers/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:tinycolor2/tinycolor2.dart';

class InteractiveWheel extends StatefulWidget {
  const InteractiveWheel({
    super.key,
    required this.wheelValue,
    required this.increaseWheelValue,
    required this.decreaseWheelValue,
    required this.onDone,
  });

  final int wheelValue;
  final VoidCallback increaseWheelValue;
  final VoidCallback decreaseWheelValue;
  final VoidCallback onDone;

  @override
  InteractiveWheelState createState() => InteractiveWheelState();
}

class InteractiveWheelState extends State<InteractiveWheel>
    with SingleTickerProviderStateMixin {
  double _rotationAngle = 0.0;
  double _cumulativeRotation = 0.0;
  double _angularVelocity = 0.0; // radians per second
  double _lastPanAngle = 0.0;
  DateTime? _lastUpdateTime;

  late final AnimationController _controller;

  static const double _stepSize = 0.2; // radians needed for one tick change
  static const double _minFlingVelocity =
      1.2; // radians/sec threshold to start fling

  @override
  void initState() {
    super.initState();
    _controller = AnimationController.unbounded(vsync: this)
      ..addListener(_handleAnimationTick);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Normalize delta to range [-pi, pi] to avoid jumps when crossing the boundary.
  double _normalizeDelta(double delta) => (delta + pi) % (2 * pi) - pi;

  double _angleForGlobalPosition(Offset globalPosition) {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final Offset center = renderBox.size.center(Offset.zero);
    final Offset local = renderBox.globalToLocal(globalPosition);
    final double deltaX = local.dx - center.dx;
    final double deltaY = local.dy - center.dy;
    return atan2(deltaY, deltaX);
  }

  void _applyDelta(double delta) {
    if (delta == 0) return;

    _rotationAngle += delta;
    _cumulativeRotation += delta;

    // Consume as many full steps as the user rotated, preserving remainder.
    while (_cumulativeRotation.abs() >= _stepSize) {
      if (_cumulativeRotation > 0) {
        widget.increaseWheelValue();
      } else {
        widget.decreaseWheelValue();
      }
      HapticFeedback.selectionClick();
      _cumulativeRotation += _cumulativeRotation > 0 ? -_stepSize : _stepSize;
    }
  }

  void _handleAnimationTick() {
    final double newAngle = _controller.value;
    final double delta = _normalizeDelta(newAngle - _rotationAngle);
    _applyDelta(delta);
    setState(() {});
  }

  void _onPanStart(DragStartDetails details) {
    _controller.stop();
    _lastUpdateTime = null;
    _angularVelocity = 0.0;
    _lastPanAngle = _angleForGlobalPosition(details.globalPosition);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final double angle = _angleForGlobalPosition(details.globalPosition);

    final DateTime now = DateTime.now();
    final double delta = _normalizeDelta(angle - _lastPanAngle);
    final double? dtSeconds =
        _lastUpdateTime == null
            ? null
            : now.difference(_lastUpdateTime!).inMicroseconds / 1e6;

    _applyDelta(delta);
    setState(() {});

    _lastPanAngle = angle;

    if (dtSeconds != null && dtSeconds > 0) {
      _angularVelocity = delta / dtSeconds;
    }
    _lastUpdateTime = now;
  }

  void _onPanEnd(DragEndDetails details) {
    // If the user flicked with noticeable speed, start a friction-based fling.
    if (_angularVelocity.abs() >= _minFlingVelocity) {
      _startFling(_angularVelocity);
    }
  }

  void _startFling(double initialVelocity) {
    // Use angle as the simulated "position" so the painter keeps rotating.
    _controller.stop();
    _controller.value = _rotationAngle;
    final simulation = FrictionSimulation(
      0.15,
      _rotationAngle,
      initialVelocity,
    );
    _controller.animateWith(simulation);
  }

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    final double width = MediaQuery.of(context).size.width;
    final Size size = Size(width, width);

    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Static Gradient (no rotation)
          CustomPaint(size: size, painter: GradientPainter(tp)),

          // Rotating Ticks
          Transform.rotate(
            angle: _rotationAngle,
            child: CustomPaint(size: size, painter: TicksPainter(tp)),
          ),

          // Button
          IconButton(
            style: ButtonStyle(
              shadowColor: WidgetStatePropertyAll(tp.surfaceColor),
              elevation: WidgetStatePropertyAll(5),
              side: WidgetStatePropertyAll(
                BorderSide(color: tp.borderColor, width: 2),
              ),
              fixedSize: WidgetStatePropertyAll(size / 5),
              backgroundColor: WidgetStatePropertyAll(tp.surfaceColor),
            ),
            onPressed: () => widget.onDone(),
            icon: Icon(Icons.arrow_forward, color: tp.primaryTextColor),
          ),
        ],
      ),
    );
  }
}

class GradientPainter extends CustomPainter {
  GradientPainter(this.tp);

  final ThemeProvider tp;

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 1.5;
    final Offset center = Offset(size.width / 2, size.height / 2);

    final Color darkColor = tp.primaryColor;

    final LinearGradient saturatedGradient = LinearGradient(
      colors: [darkColor, darkColor.lighten(10)],
      stops: [0.3, 1.0],
    );

    final LinearGradient gradient = LinearGradient(
      colors: [darkColor.desaturate(20), darkColor.lighten(10).desaturate(20)],
      stops: [0.3, 1.0],
    );

    // Draw the gradient circles (static)
    final Paint saturatedCirclePaint =
        Paint()
          ..shader = saturatedGradient.createShader(
            Rect.fromCircle(center: center, radius: radius),
          )
          ..style = PaintingStyle.fill;

    final Paint circlePaint =
        Paint()
          ..shader = gradient.createShader(
            Rect.fromCircle(center: center, radius: radius),
          )
          ..style = PaintingStyle.fill;

    final Paint whiteCirclePaint =
        Paint()
          ..color = tp.backgroundColor
          ..style = PaintingStyle.fill;

    final Paint outlinePaint =
        Paint()
          ..color = tp.mutedTextColor
          ..strokeWidth = 1.0
          ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius + 5, outlinePaint);
    canvas.drawCircle(center, radius, saturatedCirclePaint);
    canvas.drawCircle(center, radius / 1.35, circlePaint);
    canvas.drawCircle(center, radius / 2, whiteCirclePaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class TicksPainter extends CustomPainter {
  TicksPainter(this.tp);

  final ThemeProvider tp;

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 1.5;
    final Offset center = Offset(size.width / 2, size.height / 2);

    final Paint tickPaint =
        Paint()
          ..color = Color(0xFFF8F9FA)
          ..strokeWidth = 1.0
          ..style = PaintingStyle.stroke;

    // Draws 30 ticks around the circle
    final int numberOfTicks = 30;
    final double tickLength = 10.0;
    for (int i = 0; i < numberOfTicks; i++) {
      final double angle = (2 * pi / numberOfTicks) * i;
      final Offset start = Offset(
        center.dx + (radius - tickLength) * cos(angle),
        center.dy + (radius - tickLength) * sin(angle),
      );
      final Offset end = Offset(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      );
      canvas.drawLine(start, end, tickPaint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
