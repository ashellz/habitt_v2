import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/widgets/default/dual_option_selector.dart';
import 'package:habitt/widgets/whats_new/whats_new_graphic_frame.dart';
import 'package:provider/provider.dart';

/// The home page list / plan toggle, big and glowing. While [active] it flips
/// from the list to the plan, and the day's timeline appears below it.
class WhatsNewPlanGraphic extends StatefulWidget {
  const WhatsNewPlanGraphic({super.key, required this.active});

  final bool active;

  @override
  State<WhatsNewPlanGraphic> createState() => _WhatsNewPlanGraphicState();
}

class _WhatsNewPlanGraphicState extends State<WhatsNewPlanGraphic> {
  static const _times = ['08:00', '12:30', '19:00'];
  static const _widths = [0.62, 0.8, 0.5];

  bool _plan = false;
  Timer? _flip;

  @override
  void initState() {
    super.initState();
    if (widget.active) _scheduleFlip();
  }

  @override
  void didUpdateWidget(WhatsNewPlanGraphic oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active == oldWidget.active) return;
    _flip?.cancel();
    if (widget.active) {
      _scheduleFlip();
    } else {
      _plan = false;
    }
  }

  void _scheduleFlip() {
    _flip = Timer(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _plan = true);
    });
  }

  @override
  void dispose() {
    _flip?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();

    return WhatsNewGraphicFrame(
      glows: [
        WhatsNewGlow(
          color: cp.main,
          alignment: const Alignment(0, -0.45),
          size: 300,
          strength: 0.5,
        ),
        const WhatsNewGlow(
          color: Color(0xFF3CACFF),
          alignment: Alignment(-1.3, 1.3),
          size: 220,
          strength: 0.3,
        ),
        const WhatsNewGlow(
          color: Color(0xFFBA86FF),
          alignment: Alignment(1.3, 1.2),
          size: 200,
          strength: 0.3,
        ),
      ],
      child: Stack(
        children: [
          // ─── Toggle ───────────────────────────────────────
          Align(
            alignment: const Alignment(0, -0.5),
            child: IgnorePointer(
              child: Transform.scale(
                scale: 2,
                child: DualOptionSelector<bool>.icons(
                  firstValue: false,
                  secondValue: true,
                  selectedValue: _plan,
                  onSelect: (_) {},
                  firstIcon:
                      (color) =>
                          _icon('assets/images/new-svg/list-view.svg', color),
                  secondIcon:
                      (color) =>
                          _icon('assets/images/new-svg/plan-view.svg', color),
                ),
              ),
            ),
          ),
          // ─── Timeline ─────────────────────────────────────
          Align(
            alignment: const Alignment(0, 0.88),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOut,
              opacity: _plan ? 1 : 0,
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutCubic,
                offset: _plan ? Offset.zero : const Offset(0, 0.25),
                child: SizedBox(
                  width: 250,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 6,
                    children: [
                      for (var i = 0; i < _times.length; i++)
                        _timelineRow(cp, _times[i], _widths[i]),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _timelineRow(ColorProvider cp, String time, double width) {
    return Row(
      spacing: 10,
      children: [
        SizedBox(
          width: 42,
          child: Text(
            time,
            style: TextStyle(color: cp.lightGreyText, fontSize: 12),
          ),
        ),
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: width,
              child: Container(
                height: 18,
                decoration: BoxDecoration(
                  color: cp.main.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: cp.mainBorder, width: 1),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _icon(String path, Color color) {
    return SizedBox.square(
      dimension: 20,
      child: Center(
        child: SvgPicture.asset(
          path,
          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        ),
      ),
    );
  }
}
