import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/widgets/default/animated_checkbox.dart';
import 'package:habitt/widgets/whats_new/whats_new_graphic_frame.dart';
import 'package:provider/provider.dart';

/// A shaking alarm clock with ringing arcs, and the Alarm tick that turns it on.
class WhatsNewAlarmGraphic extends StatefulWidget {
  const WhatsNewAlarmGraphic({super.key});

  @override
  State<WhatsNewAlarmGraphic> createState() => _WhatsNewAlarmGraphicState();
}

class _WhatsNewAlarmGraphicState extends State<WhatsNewAlarmGraphic>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ring = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat();

  @override
  void dispose() {
    _ring.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final loc = AppLocalizations.of(context)!;

    return WhatsNewGraphicFrame(
      glows: [
        WhatsNewGlow(
          color: cp.orange,
          alignment: const Alignment(0, -0.5),
          size: 280,
          strength: 0.45,
        ),
        const WhatsNewGlow(
          color: Color(0xFFFF6B9A),
          alignment: Alignment(-1.3, 1.2),
          size: 200,
          strength: 0.25,
        ),
        WhatsNewGlow(
          color: cp.main,
          alignment: const Alignment(1.3, 1.3),
          size: 200,
          strength: 0.3,
        ),
      ],
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ─── Clock with ringing arcs ──────────────────────
          Align(
            alignment: const Alignment(0, -0.38),
            child: AnimatedBuilder(
              animation: _ring,
              builder: (context, _) {
                final t = _ring.value;
                // shakes for the first part of every cycle, then rests
                final shake =
                    t < 0.65 ? math.sin(t * 2 * math.pi * 7) * 0.13 : 0.0;
                return SizedBox(
                  width: 230,
                  height: 120,
                  child: CustomPaint(
                    painter: _RingPainter(color: cp.orange, progress: t),
                    child: Center(
                      child: Transform.rotate(angle: shake, child: _clock(cp)),
                    ),
                  ),
                );
              },
            ),
          ),
          // ─── Floating chips ───────────────────────────────
          Align(
            alignment: const Alignment(-0.82, -0.78),
            child: Transform.rotate(
              angle: -0.12,
              child: _chip(cp, child: _time(cp)),
            ),
          ),
          Align(
            alignment: const Alignment(0.84, -0.7),
            child: Transform.rotate(
              angle: 0.14,
              child: _chip(
                cp,
                child: SvgPicture.asset(
                  'assets/images/new-svg/notify.svg',
                  width: 22,
                  height: 22,
                  colorFilter: ColorFilter.mode(cp.orange, BlendMode.srcIn),
                ),
              ),
            ),
          ),
          // ─── Alarm option ─────────────────────────────────
          Align(
            alignment: const Alignment(0, 0.82),
            child: IgnorePointer(
              child: Container(
                width: 210,
                padding: const EdgeInsets.fromLTRB(16, 10, 14, 10),
                decoration: BoxDecoration(
                  color: cp.graphicCard,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: cp.border, width: 1),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        loc.habitAlarmTitle,
                        style: TextStyle(
                          color: cp.text,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    AnimatedCheckbox(value: true, onChanged: (_) {}),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _clock(ColorProvider cp) {
    return Container(
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cp.leftOrangeGraident, cp.rightOrangeGradient],
        ),
        boxShadow: [
          BoxShadow(
            color: cp.orange.withValues(alpha: 0.5),
            blurRadius: 28,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Icon(Icons.alarm_rounded, size: 48, color: Colors.white),
    );
  }

  Widget _time(ColorProvider cp) {
    return Text(
      '07:00',
      style: TextStyle(
        color: cp.text,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _chip(ColorProvider cp, {required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: cp.graphicCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cp.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: cp.isDark ? 0.35 : 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Three arcs on each side of the clock that pulse outwards.
class _RingPainter extends CustomPainter {
  _RingPainter({required this.color, required this.progress});

  final Color color;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    for (var i = 0; i < 3; i++) {
      final radius = 62.0 + i * 15;
      final wave = (math.sin(progress * 2 * math.pi - i * 0.9) + 1) / 2;
      final paint =
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeWidth = 5
            ..color = color.withValues(
              alpha: 0.15 + 0.7 * wave * (1 - i * 0.2),
            );
      const sweep = math.pi / 3;
      final rect = Rect.fromCircle(center: center, radius: radius);
      canvas.drawArc(rect, -sweep / 2, sweep, false, paint);
      canvas.drawArc(rect, math.pi - sweep / 2, sweep, false, paint);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}
