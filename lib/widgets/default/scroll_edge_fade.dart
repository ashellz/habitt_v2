import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

// Fades the edges of a scrollable ([child]: SingleChildScrollView, ListView...)
// that have more content behind them: the start once scrolled away from it, the
// end while there is more to scroll to. Content that fits gets no fade.
//
// The fade is an alpha mask over the content itself, so it works on any
// background and stays inside the widget's bounds (no colour to match, nothing
// painted outside a rounded card). It is not a blur: a BackdropFilter re-blurs
// the scrolling content every frame and made sheets laggy.
//
// A mask only shows on content that contrasts with the background, so over
// light on light content (empty space, pale fields) the fade is hard to see.
// Pass the background's colour as [startOverlayColor] to draw the start fade as
// an overlay of that colour instead: same look on content that contrasts, and
// it still reads as a fade on content that doesn't. The background has to be a
// solid colour for that to blend in.
class ScrollEdgeFade extends StatefulWidget {
  const ScrollEdgeFade({
    super.key,
    required this.child,
    this.axis = Axis.vertical,
    this.fadeExtent = 16,
    this.startOverlayColor,
  });

  final Widget child;
  final Axis axis;

  // length of the fade in logical pixels
  final double fadeExtent;

  // colour of the background behind the content, null to fade the start with a
  // mask like the end
  final Color? startOverlayColor;

  // the animated 0 (none) to 1 (full) strength of each fade, read by tests
  static const startFadeKey = ValueKey('scroll-edge-fade-start');
  static const endFadeKey = ValueKey('scroll-edge-fade-end');
  static const startOverlayKey = ValueKey('scroll-edge-fade-start-overlay');

  @override
  State<ScrollEdgeFade> createState() => _ScrollEdgeFadeState();
}

class _ScrollEdgeFadeState extends State<ScrollEdgeFade> {
  bool _fadeStart = false;
  bool _fadeEnd = false;

  // latest fades seen while the frame was being laid out, applied after it
  ({bool start, bool end})? _deferredFades;

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

    _setFades(
      fadeStart: metrics.extentBefore > _epsilon,
      fadeEnd: metrics.extentAfter > _epsilon,
    );
    return false;
  }

  void _setFades({required bool fadeStart, required bool fadeEnd}) {
    // the scrollable dispatches scroll notifications synchronously from its own
    // layout when its content shrinks (e.g. a row disappearing while scrolled to
    // the bottom), and setState isn't allowed while the frame is being laid out
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      final alreadyScheduled = _deferredFades != null;
      _deferredFades = (start: fadeStart, end: fadeEnd);
      if (alreadyScheduled) return;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        final fades = _deferredFades;
        _deferredFades = null;
        if (mounted && fades != null) {
          _setFades(fadeStart: fades.start, fadeEnd: fades.end);
        }
      });
      return;
    }

    if (fadeStart == _fadeStart && fadeEnd == _fadeEnd) return;
    setState(() {
      _fadeStart = fadeStart;
      _fadeEnd = fadeEnd;
    });
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
        builder: (context, start, child) {
          final overlayColor = widget.startOverlayColor;
          final faded = TweenAnimationBuilder<double>(
            key: ScrollEdgeFade.endFadeKey,
            tween: Tween<double>(end: _fadeEnd ? 1 : 0),
            duration: _duration,
            child: child,
            builder:
                (context, end, child) => ShaderMask(
                  blendMode: BlendMode.dstIn,
                  shaderCallback:
                      (bounds) => _shader(
                        bounds,
                        // the overlay does the start fade
                        overlayColor == null ? start : 0,
                        end,
                      ),
                  child: child,
                ),
          );

          if (overlayColor == null) return faded;

          final horizontal = widget.axis == Axis.horizontal;
          return Stack(
            children: [
              faded,
              Positioned(
                top: 0,
                left: 0,
                right: horizontal ? null : 0,
                bottom: horizontal ? 0 : null,
                width: horizontal ? widget.fadeExtent : null,
                height: horizontal ? null : widget.fadeExtent,
                child: IgnorePointer(
                  child: Opacity(
                    key: ScrollEdgeFade.startOverlayKey,
                    opacity: start,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin:
                              horizontal
                                  ? Alignment.centerLeft
                                  : Alignment.topCenter,
                          end:
                              horizontal
                                  ? Alignment.centerRight
                                  : Alignment.bottomCenter,
                          colors: [
                            overlayColor,
                            overlayColor.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
