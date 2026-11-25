import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/services/goal_check_in_analyzer.dart';
import 'package:habitt/util/goal_value_format.dart';
import 'package:habitt/widgets/default/accent_svg.dart';
import 'package:habitt/widgets/default/new_default_button.dart';
import 'package:habitt/widgets/habit_widget/text_icon.dart';
import 'package:provider/provider.dart';

/// Where a card in the weekly check-in stands.
enum GoalCardStatus { open, applied, skipped }

/// One habit's goal suggestion in the weekly check-in sheet.
class GoalSuggestionCard extends StatelessWidget {
  const GoalSuggestionCard({
    super.key,
    required this.habit,
    required this.suggestion,
    required this.status,
    required this.onApply,
    required this.onNotNow,
    required this.onUndo,
  });

  final Habit habit;
  final GoalSuggestion suggestion;
  final GoalCardStatus status;
  final VoidCallback onApply;
  final VoidCallback onNotNow;
  final VoidCallback onUndo;

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final loc = AppLocalizations.of(context)!;
    final singulars = context.read<StateProvider>().customSingulars;
    String fmt(int v) =>
        formatGoalValue(habit, v, loc, customSingulars: singulars);

    final isLower = suggestion.direction == GoalDirection.lower;
    final lighterOnly =
        isLower &&
        suggestion.daysMet / suggestion.daysUsed >=
            GoalCheckInAnalyzer.lowerHitRate;
    final reason =
        isLower
            ? (lighterOnly
                ? loc.goalCheckInReasonLighter(
                  suggestion.lighterDays,
                  fmt(suggestion.typicalValue),
                )
                : loc.goalCheckInReasonLower(
                  suggestion.daysMet,
                  suggestion.daysUsed,
                  fmt(suggestion.typicalValue),
                ))
            : loc.goalCheckInReasonRaise(
              suggestion.daysPastGoal,
              suggestion.daysUsed,
            );
    final suggested = fmt(suggestion.suggestedValue);
    final name = habit.resolvedName(
      Localizations.localeOf(context).languageCode,
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cp.isDark ? cp.field : cp.bg,
        border: Border.all(color: cp.border),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 14,
        children: [
          // ─── Header ───────────────────────────────────────────
          Row(
            spacing: 12,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: cp.isDark ? cp.bg : cp.habitIconBg,
                  shape: BoxShape.circle,
                ),
                child: Center(child: TextIcon(habit.iconPath, size: 22)),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 2,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        color: cp.text,
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      reason,
                      style: TextStyle(color: cp.greyText, fontSize: 13),
                    ),
                  ],
                ),
              ),
              SvgPicture.asset(
                isLower
                    ? 'assets/images/new-svg/decrease.svg'
                    : 'assets/images/new-svg/increase.svg',
                width: 28,
                height: 28,
              ),
            ],
          ),

          // ─── Last days ────────────────────────────────────────
          Row(
            spacing: 4,
            children: [
              for (final mark in suggestion.marks)
                Expanded(
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: switch (mark) {
                        GoalDayMark.met => cp.main,
                        GoalDayMark.partial => cp.mid,
                        GoalDayMark.missed => cp.disabled,
                      },
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
            ],
          ),

          // ─── Current → Suggested ──────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: cp.isDark ? cp.bg : cp.field,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                _value(loc.current, fmt(suggestion.currentValue), cp, false),
                Container(
                  width: 32,
                  height: 32,
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: cp.isDark ? cp.field : cp.bg,
                    shape: BoxShape.circle,
                  ),
                  child: const AccentSvg('assets/images/new-svg/arrow.svg'),
                ),
                _value(loc.suggested, suggested, cp, true),
              ],
            ),
          ),

          // ─── Actions ──────────────────────────────────────────
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child:
                status == GoalCardStatus.open
                    ? Row(
                      key: const ValueKey('open'),
                      mainAxisAlignment: MainAxisAlignment.end,
                      spacing: 8,
                      children: [
                        NewDefaultButton.secondarySmall(
                          width: null,
                          onPressed: onNotNow,
                          label: loc.goalCheckInNotNow,
                        ),
                        Flexible(
                          child: NewDefaultButton.primarySmall(
                            width: null,
                            onPressed: onApply,
                            label:
                                isLower
                                    ? loc.goalCheckInLowerTo(suggested)
                                    : loc.goalCheckInRaiseTo(suggested),
                          ),
                        ),
                      ],
                    )
                    : SizedBox(
                      key: const ValueKey('closed'),
                      height: 36,
                      child: Row(
                        spacing: 8,
                        children: [
                          if (status == GoalCardStatus.applied)
                            Icon(
                              Icons.check_circle_rounded,
                              color: cp.main,
                              size: 18,
                            ),
                          Expanded(
                            child: Text(
                              status == GoalCardStatus.applied
                                  ? (isLower
                                      ? loc.goalCheckInLoweredTo(suggested)
                                      : loc.goalCheckInRaisedTo(suggested))
                                  : loc.goalCheckInSkipped,
                              style: TextStyle(
                                color: cp.greyText,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: onUndo,
                            child: Text(
                              loc.goalCheckInUndo,
                              style: TextStyle(
                                color: cp.text,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _value(String label, String value, ColorProvider cp, bool accent) {
    return Expanded(
      child: Column(
        spacing: 2,
        children: [
          Text(
            label,
            style: TextStyle(
              color:
                  accent
                      ? cp.main
                      : (cp.isDark ? cp.lightGreyText : cp.greyText),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: accent ? cp.main : cp.text,
              fontSize: 22,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
