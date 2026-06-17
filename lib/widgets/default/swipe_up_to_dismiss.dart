import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Wraps a top-anchored banner (the sync pill, the hold-to-complete tip) so it
/// can be flicked upward to dismiss.
///
/// Tracks the upward drag and applies it as an internal translation, so the
/// parent keeps a fixed `Positioned.top`. When the user releases below the
/// dismiss threshold the banner springs back smoothly instead of snapping;
/// when they cross the distance/velocity threshold [onDismiss] fires with a
/// light haptic. Reduce-motion settings skip the spring animation.
class SwipeUpToDismiss extends StatefulWidget {
  const SwipeUpToDismiss({
    super.key,
    required this.child,
    required this.onDismiss,
    this.onDragStart,
    this.onSettle,
    this.dismissDistance = 40,
    this.flingVelocity = 200,
  });

  final Widget child;

  /// Fired once the banner is flicked far or fast enough to dismiss.
  final VoidCallback onDismiss;

  /// Fired when a drag begins — e.g. to cancel an auto-dismiss timer.
  final VoidCallback? onDragStart;

  /// Fired after a release that did NOT dismiss, once the banner has settled
  /// back into place — e.g. to re-arm an auto-dismiss timer.
  final VoidCallback? onSettle;

  /// Upward distance (logical px) past which a release dismisses.
  final double dismissDistance;

  /// Upward fling speed (logical px/s) past which a release dismisses.
  final double flingVelocity;

  @override
  State<SwipeUpToDismiss> createState() => _SwipeUpToDismissState();
}

class _SwipeUpToDismissState extends State<SwipeUpToDismiss>
    with SingleTickerProviderStateMixin {
  late final AnimationController _springController;
  Animation<double>? _spring;
  double _dragOffset = 0;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _springController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    )..addListener(() {
      setState(() => _dragOffset = _spring?.value ?? 0);
    });
  }

  @override
  void dispose() {
    _springController.dispose();
    super.dispose();
  }

  void _onDragStart(DragStartDetails _) {
    _springController.stop();
    widget.onDragStart?.call();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    // Only track upward movement (negative dy); ignore downward drag.
    setState(() => _dragOffset = math.min(0, _dragOffset + details.delta.dy));
  }

  void _onDragEnd(DragEndDetails details) {
    final velocity = details.velocity.pixelsPerSecond.dy;
    if (_dragOffset < -widget.dismissDistance ||
        velocity < -widget.flingVelocity) {
      _dismissed = true;
      HapticFeedback.lightImpact();
      widget.onDismiss();
      return;
    }
    _springBack();
  }

  void _springBack() {
    // Honour reduce-motion: snap back without animating.
    if (MediaQuery.disableAnimationsOf(context)) {
      setState(() => _dragOffset = 0);
      widget.onSettle?.call();
      return;
    }

    _spring = Tween<double>(begin: _dragOffset, end: 0).animate(
      CurvedAnimation(parent: _springController, curve: Curves.easeOutCubic),
    );
    _springController
      ..reset()
      ..forward().whenComplete(() {
        if (mounted && !_dismissed) widget.onSettle?.call();
      });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragStart: _onDragStart,
      onVerticalDragUpdate: _onDragUpdate,
      onVerticalDragEnd: _onDragEnd,
      child: Transform.translate(
        offset: Offset(0, _dragOffset),
        child: widget.child,
      ),
    );
  }
}
