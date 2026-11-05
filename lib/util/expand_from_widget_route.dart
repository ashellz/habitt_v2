import 'dart:ui' show lerpDouble;

import 'package:flutter/gestures.dart' show VelocityTracker;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Opens a page by growing it out of an on-screen widget, like an iOS app
/// launching from its icon (a "container transform").
///
/// The widget's rect (found via [sourceKey]) expands into the full screen
/// while its corners go from [closedBorderRadius] to square:
/// - [closedForeground] (the widget's text / icons) fades out early,
/// - [closedBackground] fills the growing container,
/// - the page fades in on top of it, scaled to fit the container, so the
///   widget's background visually turns into the page's.
///
/// Popping plays the same thing in reverse back into the widget. If the source
/// widget is gone by then (e.g. it was replaced after a purchase), the page
/// just fades out.
///
/// [onSourceHiddenChanged] is told to hide the source widget while the route
/// covers it, so it doesn't show twice; keep its layout (e.g. `Opacity(0)`)
/// so its position stays measurable for the reverse animation.
class ExpandFromWidgetRoute<T> extends PageRoute<T> {
  ExpandFromWidgetRoute({
    required this.sourceKey,
    required this.builder,
    required this.closedBackground,
    this.closedForeground,
    this.closedBorderRadius = 24,
    this.onSourceHiddenChanged,
    super.settings,
  });

  final GlobalKey sourceKey;
  final WidgetBuilder builder;
  final Widget closedBackground;
  final Widget? closedForeground;
  final double closedBorderRadius;
  final ValueChanged<bool>? onSourceHiddenChanged;

  static const Curve _curve = Curves.decelerate;
  static const Interval _foregroundFadeOut = Interval(0.0, 0.25);
  static const Interval _pageFadeIn = Interval(0.2, 0.7, curve: Curves.easeIn);

  Rect? _lastSourceRect;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  bool get opaque => true;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 320);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 250);

  @override
  TickerFuture didPush() {
    onSourceHiddenChanged?.call(true);
    animation!.addStatusListener(_handleStatus);
    return super.didPush();
  }

  /// True while closing from fully open (e.g. back button). The animation then
  /// runs the opening curve mirrored in time, so closing also starts fast and
  /// lands softly instead of crawling out and snapping into the widget.
  bool _closing = false;

  void _handleStatus(AnimationStatus status) {
    if (status.isCompleted || status.isDismissed) _linear = false;
    if (status == AnimationStatus.reverse) {
      // Popped mid-opening: keep the opening curve so nothing jumps.
      _closing = animation!.value >= 1.0;
    } else if (status != AnimationStatus.dismissed) {
      _closing = false;
    }
    if (status == AnimationStatus.dismissed) {
      onSourceHiddenChanged?.call(false);
    }
  }

  // ─── Pull down to dismiss ───────────────────────────────────────────
  //
  // Pulling the page down while it is scrolled to the top shrinks it back
  // towards the source widget, following the finger; letting go far / fast
  // enough pops it, otherwise it springs back open.

  /// Drag distance (as a fraction of screen height) that fully closes it.
  static const double _dismissDragFraction = 0.6;
  static const double _popBelowProgress = 0.8;
  static const double _popFlingVelocity = 700;

  /// While a drag drives the animation (and while it settles afterwards),
  /// follow the finger 1:1 instead of the open/close curve.
  bool _linear = false;
  bool _dismissing = false;
  int? _pointer;
  double _lastPointerY = 0;
  double _dragStartY = 0;
  double _screenHeight = 1;
  VelocityTracker? _velocityTracker;

  void _onPointerDown(PointerDownEvent event) {
    if (_pointer != null) return;
    _pointer = event.pointer;
    _lastPointerY = event.position.dy;
    _velocityTracker = VelocityTracker.withKind(event.kind)
      ..addPosition(event.timeStamp, event.position);
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (event.pointer != _pointer) return;
    _lastPointerY = event.position.dy;
    _velocityTracker?.addPosition(event.timeStamp, event.position);
    if (!_dismissing) return;
    final dragged = (event.position.dy - _dragStartY).clamp(
      0.0,
      double.infinity,
    );
    controller!.value = (1 - dragged / (_screenHeight * _dismissDragFraction))
        .clamp(0.0, 1.0);
  }

  void _onPointerEnd(PointerEvent event) {
    if (event.pointer != _pointer) return;
    final velocity = _velocityTracker?.getVelocity().pixelsPerSecond.dy ?? 0;
    _pointer = null;
    _velocityTracker = null;
    if (_dismissing) _endDismissDrag(event is PointerUpEvent ? velocity : 0);
  }

  /// Starts the dismiss drag when the page is pulled down past its top.
  bool _onScrollNotification(ScrollNotification notification) {
    if (_dismissing ||
        _pointer == null ||
        notification is! OverscrollNotification ||
        notification.dragDetails == null ||
        notification.overscroll >= 0 ||
        notification.metrics.axis != Axis.vertical ||
        !isCurrent ||
        !(controller?.isCompleted ?? false)) {
      return false;
    }
    final nav = navigator;
    if (nav == null) return false;

    _dismissing = true;
    _linear = true;
    _dragStartY = _lastPointerY;
    nav.didStartUserGesture();
    // Stop the list from scrolling for the rest of this drag.
    final ctx = notification.context;
    final position = ctx == null ? null : Scrollable.maybeOf(ctx)?.position;
    position?.jumpTo(position.pixels);
    return false;
  }

  void _endDismissDrag(double velocityY) {
    _dismissing = false;
    final nav = navigator!;
    final c = controller!;
    final shouldPop =
        velocityY > _popFlingVelocity ||
        (velocityY > -_popFlingVelocity && c.value < _popBelowProgress);

    // Finish from where the finger left it, easing out (the drag runs in
    // linear mode, so the controller's own curve is what the user sees).
    if (shouldPop) {
      final ms =
          lerpDouble(60, reverseTransitionDuration.inMilliseconds, c.value)!;
      nav.pop();
      if (c.isAnimating) {
        c.animateBack(
          0,
          duration: Duration(milliseconds: ms.round()),
          curve: Curves.easeOutCubic,
        );
      }
    } else {
      final ms = lerpDouble(60, 250, 1 - c.value)!;
      c.animateTo(
        1,
        duration: Duration(milliseconds: ms.round()),
        curve: Curves.easeOutCubic,
      );
    }

    if (c.isAnimating) {
      late final AnimationStatusListener onDone;
      onDone = (status) {
        if (status.isAnimating) return;
        nav.didStopUserGesture();
        c.removeStatusListener(onDone);
      };
      c.addStatusListener(onDone);
    } else {
      nav.didStopUserGesture();
    }
  }

  @override
  void dispose() {
    animation?.removeStatusListener(_handleStatus);
    // Covers removal without a reverse animation (e.g. removeRoute).
    SchedulerBinding.instance.addPostFrameCallback(
      (_) => onSourceHiddenChanged?.call(false),
    );
    super.dispose();
  }

  /// The source widget's current rect in the navigator's coordinates, or null
  /// if it is no longer on screen.
  Rect? _currentSourceRect() {
    final box = sourceKey.currentContext?.findRenderObject();
    final ancestor = navigator?.context.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return null;
    if (ancestor is! RenderBox) return null;
    return box.localToGlobal(Offset.zero, ancestor: ancestor) & box.size;
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    _screenHeight = MediaQuery.sizeOf(context).height;
    final platformPhysics = ScrollConfiguration.of(
      context,
    ).getScrollPhysics(context);
    return Listener(
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerEnd,
      onPointerCancel: _onPointerEnd,
      child: NotificationListener<ScrollNotification>(
        onNotification: _onScrollNotification,
        child: ScrollConfiguration(
          // Page scrollables that don't set their own physics stop at the top
          // instead of bouncing, so pulling down there reports overscroll.
          behavior: ScrollConfiguration.of(context).copyWith(
            physics: _TopClampedScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(parent: platformPhysics),
            ),
          ),
          child: Builder(builder: builder),
        ),
      ),
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, page) {
        final screen = MediaQuery.sizeOf(context);
        final fullRect = Offset.zero & screen;

        final liveRect = _currentSourceRect();
        if (liveRect != null) _lastSourceRect = liveRect;
        final hasSource = liveRect != null;
        final sourceRect =
            _lastSourceRect ??
            Rect.fromCenter(
              center: fullRect.center,
              width: screen.width * 0.9,
              height: screen.height * 0.9,
            );

        final raw = animation.value;
        final t =
            _linear ? raw : (_closing ? _curve.flipped : _curve).transform(raw);
        final rect = Rect.lerp(sourceRect, fullRect, t)!;
        final radius = lerpDouble(closedBorderRadius, 0, t)!;

        final foregroundOpacity =
            hasSource ? 1 - _foregroundFadeOut.transform(raw) : 0.0;
        final pageOpacity = _pageFadeIn.transform(raw);
        // Without a source to shrink into, fade the whole thing instead.
        final overallOpacity = hasSource ? 1.0 : t;

        return Stack(
          children: [
            Positioned.fromRect(
              rect: rect,
              child: Opacity(
                opacity: overallOpacity,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(radius),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // ─── Closed background ──────────────────────────
                      closedBackground,
                      // ─── Closed foreground ──────────────────────────
                      if (closedForeground != null)
                        Positioned(
                          left: 0,
                          top: 0,
                          width: sourceRect.width,
                          height: sourceRect.height,
                          child: Opacity(
                            opacity: foregroundOpacity,
                            child: Material(
                              type: MaterialType.transparency,
                              child: closedForeground,
                            ),
                          ),
                        ),
                      // ─── Page ───────────────────────────────────────
                      Opacity(
                        opacity: pageOpacity,
                        child: FittedBox(
                          fit: BoxFit.cover,
                          alignment: Alignment.topCenter,
                          clipBehavior: Clip.hardEdge,
                          child: SizedBox.fromSize(size: screen, child: page),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Clamps vertical scrolling at the top edge (no bounce there) while keeping
/// the parent's behaviour everywhere else, so pulling down at the top produces
/// an [OverscrollNotification] the route can turn into a dismiss drag.
class _TopClampedScrollPhysics extends ScrollPhysics {
  const _TopClampedScrollPhysics({super.parent});

  @override
  _TopClampedScrollPhysics applyTo(ScrollPhysics? ancestor) =>
      _TopClampedScrollPhysics(parent: buildParent(ancestor));

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    if (position.axis == Axis.vertical) {
      final min = position.minScrollExtent;
      // Already at / above the top and moving further up.
      if (value < position.pixels && position.pixels <= min) {
        return value - position.pixels;
      }
      // Crossing the top edge.
      if (value < min && min < position.pixels) return value - min;
    }
    return super.applyBoundaryConditions(position, value);
  }
}
