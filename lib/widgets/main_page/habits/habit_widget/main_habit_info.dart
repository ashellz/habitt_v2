import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/language_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/util/amount_label_preset.dart';
import 'package:habitt/util/get_duration_string.dart';
import 'package:habitt/util/resolve_amount_label_for_value.dart';
import 'package:provider/provider.dart';

class MainHabitInfo extends StatelessWidget {
  const MainHabitInfo({
    super.key,
    required this.habit,
    required this.cp,
    required this.habitsPage,
  });

  final Habit habit;
  final ColorProvider cp;
  final bool habitsPage;

  @override
  Widget build(BuildContext context) {
    final bool isAmount = habit.tracksAmount;
    final bool isDuration = habit.tracksDuration;

    final bool hasProgress =
        isAmount ? habit.amountCompleted > 0 : habit.durationCompleted > 0;
    final bool isCompleted = habit.completed;

    String amountText() {
      final loc = AppLocalizations.of(context)!;
      final sp = context.read<StateProvider>();
      final int amountForLabel =
          hasProgress && !isCompleted
              ? habit.amount
              : (isCompleted ? habit.amountCompleted : habit.amount);
      final String amountLabel = resolveAmountLabelForValue(
        habit.amountLabel.isEmpty
            ? AmountLabelPreset.times.plural
            : habit.amountLabel,
        amountForLabel,
        loc,
        customSingulars: sp.customSingulars,
      );

      if (hasProgress && !isCompleted) {
        return "${habit.amountCompleted} / ${habit.amount} $amountLabel";
      } else if (isCompleted) {
        return "${habit.amountCompleted} $amountLabel";
      }
      return "${habit.amount} $amountLabel";
    }

    String durationText() {
      if (hasProgress && !isCompleted) {
        return "${getDurationString(habit.durationCompleted)} / ${getDurationString(habit.duration)}";
      } else if (isCompleted) {
        return getDurationString(habit.durationCompleted);
      }
      return getDurationString(habit.duration);
    }

    final loc = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          spacing: 8,
          children: [
            Flexible(
              child: Text(
                habit.resolvedName(
                  context.watch<LanguageProvider>().locale?.languageCode ??
                      Localizations.localeOf(context).languageCode,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: cp.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (habit.optional && !habitsPage) optionalTag(loc),
          ],
        ),

        if (habit.optional && habitsPage)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: optionalTag(loc),
          ),
        if (isAmount || isDuration)
          Padding(
            padding: const EdgeInsets.only(top: 10.0),
            child: Row(
              spacing: 8,
              children: [
                isAmount
                    ? Icon(Icons.repeat, size: 14, color: cp.lightGreyText)
                    : SvgPicture.asset(
                      "assets/images/new-svg/clock.svg",
                      width: 14,
                      height: 14,
                    ),
                Text(
                  isAmount ? amountText() : durationText(),
                  style: TextStyle(color: cp.lightGreyText, fontSize: 13),
                ),
              ],
            ),
          )
        else if (habit.description != "")
          Text(
            habit.description,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: cp.lightGreyText, fontSize: 13),
          ),
      ],
    );
  }

  AnimatedContainer optionalTag(AppLocalizations loc) {
    return AnimatedContainer(
      curve: Curves.linear,
      duration: Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: habit.completed && !habitsPage ? cp.bg : cp.habitBg,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 2),
      child: Text(
        loc.optional,
        style: TextStyle(
          color: cp.isDark ? cp.greyText : cp.lightGreyText,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
