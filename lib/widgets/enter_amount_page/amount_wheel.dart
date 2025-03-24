import 'dart:math';

import 'package:flutter/material.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:provider/provider.dart';

class InteractiveWheel extends StatefulWidget {
  const InteractiveWheel({
    super.key,
    required this.wheelValue,
    required this.increaseWheelValue,
    required this.decreaseWheelValue,
  });

  final int wheelValue;
  final Function increaseWheelValue;
  final Function decreaseWheelValue;

  @override
  _InteractiveWheelState createState() => _InteractiveWheelState();
}

class _InteractiveWheelState extends State<InteractiveWheel>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _rotationAngle = 0.0;
  double _startAngle = 0.0;
  double _previousAngle = 0.0;
  double _cumulativeRotation = 0.0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    _startAngle = _rotationAngle;
    _previousAngle = _rotationAngle; // Initialize previous angle
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final Offset center = renderBox.size.center(Offset.zero);
    final Offset touchPosition = renderBox.globalToLocal(
      details.globalPosition,
    );

    final double deltaX = touchPosition.dx - center.dx;
    final double deltaY = touchPosition.dy - center.dy;
    final double angle = _startAngle + atan2(deltaY, deltaX);

    // Calculate the change in angle (delta)
    final double deltaAngle = angle - _previousAngle;

    // Normalize the delta to handle wrapping around 2 * pi
    final double normalizedDelta = (deltaAngle + pi) % (2 * pi) - pi;

    // Step size (in radians) required to increment/decrement the wheel value by 1
    const double stepSize = 0.2; // Adjust this value to control sensitivity

    // Update cumulative rotation
    _cumulativeRotation += normalizedDelta;

    // Check if cumulative rotation exceeds the step size
    if (_cumulativeRotation.abs() >= stepSize) {
      if (_cumulativeRotation > 0) {
        // Clockwise rotation (up)
        widget.increaseWheelValue();
      } else {
        // Counterclockwise rotation (down)
        widget.decreaseWheelValue();
      }
      // Reset cumulative rotation
      _cumulativeRotation = 0.0;
    }

    // Update the previous angle for the next frame
    _previousAngle = angle;

    // Update the rotation angle for the UI
    setState(() {
      _rotationAngle = angle;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorProvider = context.watch<ColorProvider>();

    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Static Gradient (no rotation)
          CustomPaint(
            size: Size(400, 400),
            painter: GradientPainter(colorProvider),
          ),

          // Rotating Ticks
          Transform.rotate(
            angle: _rotationAngle,
            child: CustomPaint(
              size: Size(400, 400),
              painter: TicksPainter(colorProvider),
            ),
          ),
        ],
      ),
    );
  }
}

class GradientPainter extends CustomPainter {
  GradientPainter(this.colorProvider);

  final ColorProvider colorProvider;

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 1.5;
    final Offset center = Offset(size.width / 2, size.height / 2);

    final LinearGradient saturatedGradient = LinearGradient(
      colors: [Color(0xFF01377D), Color.fromARGB(255, 38, 101, 194)],
      stops: [0.3, 1.0],
    );

    final LinearGradient gradient = LinearGradient(
      colors: [
        Color.fromARGB(255, 18, 63, 122),
        Color.fromARGB(255, 62, 115, 194),
      ],
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
          ..color = colorProvider.backgroundColor
          ..style = PaintingStyle.fill;

    final Paint outlinePaint =
        Paint()
          ..color = colorProvider.colorScheme.strokeColor
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
  TicksPainter(this.colorProvider);

  final ColorProvider colorProvider;

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 1.5;
    final Offset center = Offset(size.width / 2, size.height / 2);

    final Paint tickPaint =
        Paint()
          ..color = colorProvider.backgroundColor
          ..strokeWidth = 1.0
          ..style = PaintingStyle.stroke;

    // Draw 100 ticks around the circle
    final int numberOfTicks = 100;
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
