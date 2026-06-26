import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/stats_provider.dart';
import 'package:habitt/util/streak_praise.dart';
import 'package:habitt/widgets/default/new_default_dialog.dart';
import 'package:habitt/widgets/dialogs/streak_celebration/streak_day_strip.dart';
import 'package:provider/provider.dart';

/// Celebration shown when the perfect-days streak grows. Presented via
/// `showDialogSheet` using the shared [NewDefaultDialog] shell, with a custom
/// fire + animated day-strip body in its `child` slot.
class StreakCelebrationDialog extends StatefulWidget {
  const StreakCelebrationDialog({
    super.key,
    required this.streak,
    required this.dayStatuses,
    required this.allStats,
    this.today,
  });

  final int streak;
  final Map<DateTime, DayCompletionStatus> dayStatuses;
  final Map<DateTime, double> allStats;
  final DateTime? today;

  @override
  State<StreakCelebrationDialog> createState() =>
      _StreakCelebrationDialogState();
}

class _StreakCelebrationDialogState extends State<StreakCelebrationDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _progress;

  static const int _hapticSteps = 15;
  int _lastHapticStep = 0;
  bool _hapticsEnabled = false;

  static final _random = Random();
  String? _praise;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final loc = AppLocalizations.of(context)!;
    final options = streakPraiseOptions(loc);
    _praise ??= options[_random.nextInt(options.length)];
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );
    _progress = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _progress.addListener(_maybeHaptic);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.disableAnimationsOf(context)) {
        // reduced motion for accessibility
        _controller.value = 1.0;
        return;
      }
      _hapticsEnabled = true;
      // delay to start after sheet slide-in
      Future.delayed(const Duration(milliseconds: 280), () {
        if (mounted) _controller.forward();
      });
    });
  }

  void _maybeHaptic() {
    if (!_hapticsEnabled) return;
    final step = (_progress.value * _hapticSteps).floor();
    if (step > _lastHapticStep && step <= _hapticSteps) {
      _lastHapticStep = step;
      HapticFeedback.selectionClick();
    }
  }

  @override
  void dispose() {
    _progress.removeListener(_maybeHaptic);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final loc = AppLocalizations.of(context)!;

    return NewDefaultDialog(
      title: loc.greatProgress,
      desc: _praise ?? loc.buildingRealConsistency,
      showSecondaryButton: false,
      showCloseButton: true,
      primaryButtonLabel: loc.keepGoing,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 130,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.bottomCenter,
              children: [
                Container(
                  width: 130,
                  height: 130,
                  padding: const EdgeInsets.only(
                    top: 14,
                    left: 20,
                    right: 20,
                    bottom: 26,
                  ),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cp.isDark ? cp.field : null,
                    gradient:
                        cp.isDark
                            ? null
                            : LinearGradient(
                              begin: Alignment(1.00, 0.00),
                              end: Alignment(0.00, 1.00),
                              colors: [
                                const Color(0xFFFFF6DA),
                                const Color(0xFFFFDEB1),
                              ],
                            ),
                  ),
                ),
                // Glow that blooms behind the fire to the peak then fades out.
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    final pulse = sin(_controller.value * pi).clamp(0.0, 1.0);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 1.0),
                      child: Opacity(opacity: pulse, child: child),
                    );
                  },
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          cp.orange300.withValues(alpha: 0.55),
                          cp.orange300.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
                // Fire grows to the peak then back to its original size.
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    final pulse = sin(_controller.value * pi).clamp(0.0, 1.0);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 31.0),
                      child: Transform.scale(scale: 1 + 0.2 * pulse, child: child),
                    );
                  },
                  child: SvgPicture.asset(
                    'assets/images/new-svg/streak.svg',
                    width: 80,
                    height: 80,
                  ),
                ),
                Positioned(
                  bottom: -20,
                  child: // ─── Streak pill (count ticks n-1 → n with the reveal) ──────────
                      AnimatedBuilder(
                    animation: _progress,
                    builder: (context, _) {
                      final showNew =
                          widget.streak <= 1 || _progress.value >= 0.55;
                      final count = showNew ? widget.streak : widget.streak - 1;
                      final dayWord = count == 1 ? loc.day : loc.days;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: ShapeDecoration(
                          color: cp.bg,
                          shape: RoundedRectangleBorder(
                            side: BorderSide(width: 1, color: cp.orange200),
                            borderRadius: BorderRadius.circular(100),
                          ),
                        ),
                        child: Text(
                          '$count $dayWord',
                          style: TextStyle(
                            color: cp.orange300,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 45),
          StreakDayStrip(
            dayStatuses: widget.dayStatuses,
            allStats: widget.allStats,
            today: widget.today,
            progress: _progress,
          ),
        ],
      ),
    );
  }
}
