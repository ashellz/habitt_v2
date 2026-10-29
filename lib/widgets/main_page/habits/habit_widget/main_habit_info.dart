import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/models/health_metric_type.dart';
import 'package:habitt/models/schedule_type.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/providers/language_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/providers/timer_provider.dart';
import 'package:habitt/util/amount_label_preset.dart';
import 'package:habitt/util/format_minutes_of_day.dart';
import 'package:habitt/util/get_duration_string.dart';
import 'package:habitt/util/get_sleep_amount_string.dart';
import 'package:habitt/util/resolve_amount_label_for_value.dart';
import 'package:habitt/widgets/habit_widget/habit_tag.dart';
import 'package:habitt/widgets/habit_widget/next_scheduled_tag.dart';
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
    final bool isTimeOfDay = habit.tracksTimeOfDay;
    // sleep is an amount goal in minutes, so it reads as a duration (clock
    // icon, "8h") rather than a count
    final bool isSleep = habit.healthMetric == HealthMetricType.sleep;
    // follow the running timer live, same as NewHabitProgress.
    final liveDurationSeconds = context.select<TimerProvider, int?>(
      (t) => t.liveProgressFor(habit.id),
    );
    final int durationCompletedValue =
        liveDurationSeconds ?? habit.durationCompleted;

    final bool hasProgress =
        isAmount || isTimeOfDay
            ? habit.amountCompleted > 0
            : durationCompletedValue > 0;
    final bool isCompleted = habit.completed;

    String amountText() {
      if (habit.healthMetric == HealthMetricType.sleep) {
        return getSleepAmountString(habit);
      }
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
      if ((hasProgress && !isCompleted) &&
          durationCompletedValue < habit.duration) {
        return "${getDurationString(durationCompletedValue)} / ${getDurationString(habit.duration)}";
      } else if (isCompleted || durationCompletedValue >= habit.duration) {
        return getDurationString(durationCompletedValue);
      }
      return getDurationString(habit.duration);
    }

    String timeOfDayText() {
      // show the real logged start bedtime or wake time once there is one, otherwise the target
      return formatMinutesOfDay(
        context,
        hasProgress ? habit.amountCompleted : habit.amount,
      );
    }

    String getText() {
      switch (habit.trackingType) {
        case HabitTrackingType.amount:
          return amountText();
        case HabitTrackingType.duration:
          return durationText();
        case HabitTrackingType.timeOfDay:
          return timeOfDayText();
        default:
          return "";
      }
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
            if (habit.optional && !habitsPage) _optionalTag(loc),
          ],
        ),

        if (habitsPage) _habitsPageTags(context, loc),
        if (isAmount || isDuration || isTimeOfDay)
          Padding(
            padding: const EdgeInsets.only(top: 10.0),
            child: Row(
              spacing: 8,
              children: [
                isAmount && !isSleep
                    ? Icon(Icons.repeat, size: 14, color: cp.lightGreyText)
                    : SvgPicture.asset(
                      "assets/images/new-svg/clock.svg",
                      width: 14,
                      height: 14,
                    ),
                Text(
                  getText(),
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

  // ─── Tags ─────────────────────────────────────────────

  // Habits page only: paused wins over everything, otherwise optional and the
  // next scheduled day (for habits not scheduled today) sit side by side.
  Widget _habitsPageTags(BuildContext context, AppLocalizations loc) {
    if (habit.isDeleted == true) return const SizedBox.shrink();

    final List<Widget> tags;
    if (habit.isPaused == true) {
      tags = [_pausedTag(loc)];
    } else {
      final habitProvider = context.watch<HabitProvider>();
      // A custom "show again if missed" habit stays on today's list until
      // it is done, so once completed it shows when it comes up next.
      final settledToday =
          habit.scheduleType == ScheduleType.custom &&
          habit.showIfMissed &&
          habit.completed;
      final nextDate =
          habitProvider.appearsOnDay(habit, DateTime.now()) && !settledToday
              ? null
              : habitProvider.nextScheduledDate(habit);
      tags = [
        if (habit.optional) _optionalTag(loc),
        if (nextDate != null) NextScheduledTag(date: nextDate, cp: cp),
      ];
    }
    if (tags.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Wrap(spacing: 4, runSpacing: 4, children: tags),
    );
  }

  Widget _optionalTag(AppLocalizations loc) {
    return HabitTag(
      label: loc.optional,
      color: cp.isDark ? cp.greyText : cp.lightGreyText,
      backgroundColor: habit.completed && !habitsPage ? cp.bg : cp.habitBg,
    );
  }

  Widget _pausedTag(AppLocalizations loc) {
    return HabitTag(
      label: loc.pausedTag,
      color: ColorProvider.current,
      backgroundColor: cp.currentTint,
    );
  }
}
