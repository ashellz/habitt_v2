import 'package:flutter/material.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/services/color_service.dart';
import 'package:habitt/util/get_duration_string.dart';

class DurationDisplay extends StatefulWidget {
  const DurationDisplay({super.key, required this.habit});

  final Habit habit;

  @override
  State<DurationDisplay> createState() => DurationDisplayState();
}

class DurationDisplayState extends State<DurationDisplay> {
  double _fontSize = 12;
  String? _lastBottomText;
  final TextPainter _painter = TextPainter(
    textDirection: TextDirection.ltr,
    maxLines: 1,
  );

  @override
  void didUpdateWidget(DurationDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.habit.duration != oldWidget.habit.duration) {
      _adjustFontSize();
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _adjustFontSize());
  }

  void _adjustFontSize() {
    final currentBottomText = getDurationString(widget.habit.duration);

    // Only recalculate if text changed or we haven't calculated before
    if (_lastBottomText == currentBottomText) return;

    _lastBottomText = currentBottomText;
    const maxWidth = 48 * 0.85; // 85% of container width as safety margin
    const double minFontSize = 8;
    const double maxFontSize = 12;

    double testFontSize = maxFontSize;
    bool foundFit = false;

    while (testFontSize >= minFontSize && !foundFit) {
      _painter.text = TextSpan(
        text: currentBottomText,
        style: TextStyle(fontSize: testFontSize, fontWeight: FontWeight.bold),
      );

      _painter.layout(minWidth: 0, maxWidth: double.infinity);

      if (_painter.width <= maxWidth) {
        foundFit = true;
      } else {
        testFontSize -= 0.5;
      }
    }

    final newFontSize = foundFit ? testFontSize : minFontSize;
    if (_fontSize != newFontSize) {
      setState(() => _fontSize = newFontSize);
    }
  }

  @override
  void dispose() {
    _painter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final durationCompletedString = getDurationString(
      widget.habit.durationCompleted,
    );
    final durationString = getDurationString(widget.habit.duration);

    final TextStyle textStyle = TextStyle(
      shadows: [
        Shadow(
          color: Colors.black.withAlpha(100),
          offset: const Offset(0, 1),
          blurRadius: 5,
        ),
      ],
      color: widget.habit.skipped ? ColorService.textMuted : Colors.white,
      fontWeight: FontWeight.bold,
      fontSize: _fontSize,
    );

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          durationCompletedString,
          style: textStyle,
          maxLines: 1,
          softWrap: false,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Divider(
            height: 2,
            thickness: 2,
            color: widget.habit.skipped ? ColorService.textMuted : Colors.white,
          ),
        ),
        Text(durationString, style: textStyle, maxLines: 1, softWrap: false),
      ],
    );
  }
}
