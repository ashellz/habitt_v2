import 'package:flutter/material.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/services/lighter_day_policy.dart';
import 'package:habitt/util/goal_value_format.dart';
import 'package:habitt/widgets/default/accent_svg.dart';
import 'package:habitt/widgets/default/multiple_option_selector.dart';
import 'package:habitt/widgets/default/new_default_dialog.dart';
import 'package:habitt/widgets/habit_widget/text_icon.dart';
import 'package:provider/provider.dart';

/// The evening offer to lower today's goal of one habit, or, when its streak
/// ends tonight and the week's lighter days are used up, to log any amount.
/// See docs/goal_check_in.md.
class LighterDaySheet extends StatefulWidget {
  const LighterDaySheet({
    super.key,
    required this.offer,
    required this.onSetGoal,
    required this.onLogProgress,
  });

  final LighterDayOffer offer;

  /// Sets today's goal. The sheet closes after it.
  final Future<void> Function(int goal) onSetGoal;

  /// Opens the log progress dialog ([LighterDayKind.saveStreak]).
  final VoidCallback onLogProgress;

  @override
  State<LighterDaySheet> createState() => _LighterDaySheetState();
}

class _LighterDaySheetState extends State<LighterDaySheet> {
  late int? _selected = _initialSelection();

  int? _initialSelection() {
    final values = widget.offer.values;
    if (values.isEmpty) return null;
    if (widget.offer.progress > 0) return values.first;
    return values[values.length ~/ 2];
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final loc = AppLocalizations.of(context)!;
    final offer = widget.offer;
    final habit = offer.habit;
    final singulars = context.read<StateProvider>().customSingulars;
    String fmt(int v) =>
        formatGoalValue(habit, v, loc, customSingulars: singulars);
    final name = habit.resolvedName(
      Localizations.localeOf(context).languageCode,
    );
    final isSave = offer.kind == LighterDayKind.saveStreak;
    final selected = _selected;

    final String title;
    final String desc;
    if (offer.streakAtRisk != null) {
      title =
          isSave
              ? loc.saveStreakTitle(offer.streakAtRisk!)
              : loc.lighterDayStreakTitle(offer.streakAtRisk!);
      desc =
          isSave
              ? loc.saveStreakDesc
              : loc.lighterDayStreakDesc(fmt(offer.values.first));
    } else if (offer.progress > 0) {
      title = loc.lighterDayTitle(fmt(offer.usualGoal));
      desc = loc.lighterDayDescPartial(fmt(offer.progress), fmt(offer.usualGoal));
    } else {
      title = loc.lighterDayTitleZero;
      desc =
          offer.missedYesterday
              ? loc.lighterDayDescZeroMissed(name)
              : loc.lighterDayDescZero;
    }

    final countsNow = selected != null && selected <= offer.progress;
    final primaryLabel =
        isSave
            ? loc.saveStreakLog
            : (countsNow
                ? loc.lighterDayCountIt
                : loc.lighterDaySetTo(fmt(selected ?? offer.usualGoal)));

    return NewDefaultDialog(
      titleIcon: TextIcon(habit.iconPath, size: 26),
      title: title,
      desc: desc,
      secondaryButtonLabel: loc.lighterDayKeep(fmt(offer.usualGoal)),
      primaryButtonLabel: primaryLabel,
      primaryButtonEnabled: isSave || selected != null,
      onPrimaryButtonPressed: () async {
        if (isSave) {
          Navigator.of(context).pop();
          widget.onLogProgress();
          return;
        }
        if (selected == null) return;
        await widget.onSetGoal(selected);
        if (context.mounted) Navigator.of(context).pop();
      },
      tip: isSave ? null : loc.lighterDaysLeft(offer.daysLeft),
      child:
          isSave
              ? null
              : Column(
                spacing: 12,
                children: [
                  // ─── Usual → Today ────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cp.isDark ? cp.field : cp.bg,
                      border: Border.all(color: cp.border),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        _value(
                          loc.lighterDayUsualGoal,
                          fmt(offer.usualGoal),
                          cp,
                          false,
                        ),
                        Container(
                          width: 40,
                          height: 40,
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: cp.isDark ? cp.bg : cp.habitBg,
                            shape: BoxShape.circle,
                          ),
                          child: const AccentSvg(
                            'assets/images/new-svg/arrow.svg',
                          ),
                        ),
                        _value(
                          loc.lighterDayToday,
                          fmt(selected ?? offer.usualGoal),
                          cp,
                          true,
                        ),
                      ],
                    ),
                  ),

                  // ─── Values ───────────────────────────────────────
                  MultipleOptionSelector<int>(
                    labels: [
                      for (final v in offer.values)
                        v == offer.progress
                            ? loc.lighterDayDoneOption(
                              formatGoalValue(habit, v, loc, withLabel: false),
                            )
                            : fmt(v),
                    ],
                    values: offer.values,
                    selectedValue: selected,
                    allowDeselect: false,
                    onSelect: (v) => setState(() => _selected = v),
                  ),
                ],
              ),
    );
  }

  Widget _value(String label, String value, ColorProvider cp, bool accent) {
    return Expanded(
      child: Column(
        spacing: 8,
        children: [
          Text(
            label,
            style: TextStyle(
              color:
                  accent
                      ? cp.main
                      : (cp.isDark ? cp.lightGreyText : cp.greyText),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                color: accent ? cp.main : cp.text,
                fontSize: 32,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
