import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/stats_provider.dart';
import 'package:habitt/util/streak_praise.dart';
import 'package:habitt/widgets/default/new_default_dialog.dart';
import 'package:habitt/widgets/dialogs/streak_celebration/streak_day_strip.dart';
import 'package:provider/provider.dart';

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

class _StreakCelebrationDialogState extends State<StreakCelebrationDialog> {
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
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final loc = AppLocalizations.of(context)!;
    final streak = widget.streak;
    final dayWord = streak == 1 ? loc.day : loc.days;

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
                Padding(
                  padding: const EdgeInsets.only(bottom: 31.0),
                  child: SvgPicture.asset(
                    'assets/images/new-svg/streak.svg',
                    width: 80,
                    height: 80,
                  ),
                ),

                Positioned(
                  bottom: -20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 9,
                    ),
                    decoration: ShapeDecoration(
                      color: cp.bg,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(width: 1, color: cp.orange200),
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                    child: Text(
                      '$streak $dayWord',
                      style: TextStyle(
                        color: cp.orange300,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
          ),
        ],
      ),
    );
  }
}
