import 'package:flutter/material.dart';

class HabitNameDisplay extends StatefulWidget {
  const HabitNameDisplay({
    super.key,
    required this.text,
    required this.completed,
    required this.textColor,
  });

  final String text;
  final bool completed;
  final Color textColor;

  @override
  HabitNameDisplayState createState() => HabitNameDisplayState();
}

class HabitNameDisplayState extends State<HabitNameDisplay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _lineWidth;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 150),
    );

    _lineWidth = Tween<double>(begin: 0, end: 0).animate(_controller);

    if (widget.completed) {
      // Animate from 0 to full width when completed becomes true
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(covariant HabitNameDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.completed && !oldWidget.completed) {
      // Animate from 0 to full width when completed becomes true
      _controller.forward();
    } else if (!widget.completed && oldWidget.completed) {
      // Animate from full width to 0 when completed becomes false
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _lineWidth = Tween<double>(
          begin: 0,
          end: constraints.maxWidth,
        ).animate(_controller);

        return Stack(
          children: [
            Text(
              widget.text,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              style: TextStyle(fontSize: 16, color: widget.textColor),
            ),
            Positioned(
              top: 12,
              left: 0,
              child: AnimatedBuilder(
                animation: _lineWidth,
                builder: (context, child) {
                  return Container(
                    height: 1,
                    width: _lineWidth.value,
                    color: widget.textColor,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
