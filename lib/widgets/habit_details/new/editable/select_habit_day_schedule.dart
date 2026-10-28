import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/widgets/habit_details/new/editable/dialogs/day_schedule_flow.dart';
import 'package:habitt/widgets/habit_details/new/editable/schedule_time_column.dart';
import 'package:habitt/widgets/habit_details/new/editable/schedule_time_field.dart';
import 'package:provider/provider.dart';

/// Habit sheet card for when during the day the habit happens: a category,
/// a specific time or a time range. Replaces the old category dropdown.
class SelectHabitDaySchedule extends StatelessWidget {
  const SelectHabitDaySchedule({super.key});

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final sp = context.watch<StateProvider>();
    final loc = AppLocalizations.of(context)!;
    final schedule = currentDaySchedule(sp);

    final label = switch (schedule) {
      DaySchedule.anyTime => loc.anyTime,
      DaySchedule.morning => loc.morning,
      DaySchedule.afternoon => loc.afternoon,
      DaySchedule.evening => loc.evening,
      DaySchedule.specificTime => loc.specificTime,
      DaySchedule.timeRange => loc.timeRange,
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cp.border),
      ),
      child: Column(
        spacing: 16,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.daySchedule,
            style: TextStyle(
              color: cp.text,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          Column(
            spacing: 8,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Schedule field ───────────────────────────────
              GestureDetector(
                onTap: () => showDayScheduleFlow(context),
                child: Container(
                  height: 46,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: cp.field,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        label,
                        style: TextStyle(fontSize: 16, color: cp.text),
                      ),
                      SvgPicture.asset(
                        "assets/images/new-svg/dropdown.svg",
                        colorFilter: ColorFilter.mode(cp.text, BlendMode.srcIn),
                      ),
                    ],
                  ),
                ),
              ),

              // ─── Times / hint ─────────────────────────────────
              if (schedule == DaySchedule.timeRange)
                // same layout as the time range dialog
                Row(
                  spacing: 10,
                  children: [
                    Expanded(
                      child: ScheduleTimeColumn(
                        label: loc.startsAt,
                        minutes: sp.timeIntervalStart,
                        onTap:
                            () =>
                                editScheduleTime(context, editingStart: true),
                      ),
                    ),
                    Expanded(
                      child: ScheduleTimeColumn(
                        label: loc.endsAt,
                        minutes: sp.timeIntervalEnd,
                        onTap:
                            () =>
                                editScheduleTime(context, editingStart: false),
                      ),
                    ),
                  ],
                )
              else if (schedule.isTimed)
                _timeRow(
                  context,
                  label: loc.startsAt,
                  minutes: sp.timeIntervalStart,
                  editingStart: true,
                )
              else
                Text(
                  loc.daySchedulePrompt,
                  style: TextStyle(
                    color: cp.isDark ? cp.greyText : cp.lightGreyText,
                    fontSize: 13,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _timeRow(
    BuildContext context, {
    required String label,
    required int minutes,
    required bool editingStart,
  }) {
    final cp = context.watch<ColorProvider>();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: cp.isDark ? cp.greyText : cp.lightGreyText,
            fontSize: 13,
          ),
        ),
        ScheduleTimeField(
          minutes: minutes,
          onTap: () => editScheduleTime(context, editingStart: editingStart),
        ),
      ],
    );
  }
}
