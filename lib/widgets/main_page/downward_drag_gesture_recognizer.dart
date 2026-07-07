import 'package:flutter/gestures.dart';

// custom vertical drag recognizer that captures when drag direction is downward
class DownwardDragGestureRecognizer extends VerticalDragGestureRecognizer {
  DownwardDragGestureRecognizer({super.debugOwner});

  double _totalVerticalDistance = 0;
  bool _accepted = false;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    _totalVerticalDistance = 0;
    _accepted = false;
    super.addAllowedPointer(event);
  }

  @override
  void acceptGesture(int pointer) {
    _accepted = true;
    super.acceptGesture(pointer);
  }

  @override
  void handleEvent(PointerEvent event) {
    if (!_accepted && event is PointerMoveEvent) {
      _totalVerticalDistance += event.delta.dy;
      // Reject before the base recognizer can accept (it accepts at
      // kTouchSlop regardless of sign), leaving a little jitter tolerance.
      if (_totalVerticalDistance < -kTouchSlop / 2) {
        resolve(GestureDisposition.rejected);
        stopTrackingPointer(event.pointer);
        return;
      }
    }
    super.handleEvent(event);
  }
}
