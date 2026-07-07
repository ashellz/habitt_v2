import 'package:flutter/animation.dart';

// custom controller used by mainpage to control expanding of progress calendar sheet
class CalendarExpansionController {
  CalendarExpansionController({
    required this.animation,
    required this.onDragUpdate,
    required this.onDragEnd,
  });

  // 0 = normal, 1 = expanded
  final Animation<double> animation;

  // delta is above 0 = downward drag
  final void Function(double delta) onDragUpdate;
  final void Function(double velocity) onDragEnd;

  void Function(DateTime day)? _revealDay;

  void attachRevealDay(void Function(DateTime day) handler) {
    _revealDay = handler;
  }

  void detachRevealDay(void Function(DateTime day) handler) {
    if (_revealDay == handler) {
      _revealDay = null;
    }
  }

  void revealDay(DateTime day) => _revealDay?.call(day);
}
