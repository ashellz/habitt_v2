import 'package:flutter/material.dart';

// Fades the edges of a scrollable ([child]: SingleChildScrollView, ListView...)
// that have more content behind them: the start once scrolled away from it, the
// end while there is more to scroll to. Content that fits gets no fade.
//
// The fade is an alpha mask over the content itself, so it works on any
// background and stays inside the widget's bounds (no colour to match, nothing
// painted outside a rounded card). It is not a blur: a BackdropFilter re-blurs
// the scrolling content every frame and made sheets laggy.
class ScrollEdgeFade extends StatefulWidget {
  const ScrollEdgeFade({
    super.key,
    required this.child,
    this.axis = Axis.vertical,
    this.fadeExtent = 16,
  });

  final Widget child;
  final Axis axis;

  // length of the fade in logical pixels
  final double fadeExtent;

  // the animated 0 (none) to 1 (full) strength of each fade, read by tests
  static const startFadeKey = ValueKey('scroll-edge-fade-start');
  static const endFadeKey = ValueKey('scroll-edge-fade-end');

  @override
  State<ScrollEdgeFade> createState() => _ScrollEdgeFadeState();
}

class _ScrollEdgeFadeState extends State<ScrollEdgeFade> {
  bool _fadeStart = false;
  bool _fadeEnd = false;

  // half a pixel of slack so a fully scrolled view doesn't flicker
  static const double _epsilon = 0.5;
  static const Duration _duration = Duration(milliseconds: 200);

  bool _onNotification(Notification notification) {
    // scrolling, and metrics changing (first layout, keyboard, growing content)
    final ScrollMetrics metrics;
    if (notification is ScrollNotification) {
      metrics = notification.metrics;
    } else if (notification is ScrollMetricsNotification) {
      metrics = notification.metrics;
    } else {
      return false;
    }

    // only the wrapped scrollable, not scrollables inside its content
    if (notification is ViewportNotificationMixin && notification.depth != 0) {
      return false;
    }
    if (metrics.axis != widget.axis) return false;

    final fadeStart = metrics.extentBefore > _epsilon;
    final fadeEnd = metrics.extentAfter > _epsilon;
    if (fadeStart != _fadeStart || fadeEnd != _fadeEnd) {
      setState(() {
        _fadeStart = fadeStart;
        _fadeEnd = fadeEnd;
      });
    }
    return false;
  }

  Shader _shader(Rect bounds, double start, double end) {
    final horizontal = widget.axis == Axis.horizontal;
    final length = horizontal ? bounds.width : bounds.height;
    final fraction =
        length <= 0 ? 0.0 : (widget.fadeExtent / length).clamp(0.0, 0.5);

    return LinearGradient(
      begin: horizontal ? Alignment.centerLeft : Alignment.topCenter,
      end: horizontal ? Alignment.centerRight : Alignment.bottomCenter,
      colors: [
        Colors.white.withValues(alpha: 1 - start),
        Colors.white,
        Colors.white,
        Colors.white.withValues(alpha: 1 - end),
      ],
      stops: [0, fraction, 1 - fraction, 1],
    ).createShader(bounds);
  }

  @override
  Widget build(BuildContext context) {
    // child is passed through the builders so the scrollable isn't rebuilt on
    // every frame of the fade animation
    return NotificationListener<Notification>(
      onNotification: _onNotification,
      child: TweenAnimationBuilder<double>(
        key: ScrollEdgeFade.startFadeKey,
        tween: Tween<double>(end: _fadeStart ? 1 : 0),
        duration: _duration,
        child: widget.child,
        builder:
            (context, start, child) => TweenAnimationBuilder<double>(
              key: ScrollEdgeFade.endFadeKey,
              tween: Tween<double>(end: _fadeEnd ? 1 : 0),
              duration: _duration,
              child: child,
              builder:
                  (context, end, child) => ShaderMask(
                    blendMode: BlendMode.dstIn,
                    shaderCallback: (bounds) => _shader(bounds, start, end),
                    child: child,
                  ),
            ),
      ),
    );
  }
}
