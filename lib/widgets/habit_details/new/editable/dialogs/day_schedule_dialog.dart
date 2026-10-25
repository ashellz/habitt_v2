import 'package:flutter/material.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/widgets/default/animated_radio.dart';
import 'package:habitt/widgets/default/new_default_dialog.dart';
import 'package:habitt/widgets/habit_details/new/editable/dialogs/day_schedule_flow.dart';
import 'package:provider/provider.dart';

/// "Set day schedule": tapping an option pops it right away; Done pops the
/// preselected one. The flow decides whether that closes or moves forward.
class DayScheduleDialog extends StatelessWidget {
  const DayScheduleDialog({super.key, required this.initial});

  final DaySchedule initial;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return NewDefaultDialog(
      title: loc.setDaySchedule,
      primaryButtonLabel: loc.done,
      onPrimaryButtonPressed: () => Navigator.of(context).pop(initial),
      child: Column(
        spacing: 10,
        children: [
          for (final option in DaySchedule.values)
            _DayScheduleOption(
              option: option,
              selected: option == initial,
              onTap: () => Navigator.of(context).pop(option),
            ),
        ],
      ),
    );
  }
}

class _DayScheduleOption extends StatelessWidget {
  const _DayScheduleOption({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final DaySchedule option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final loc = AppLocalizations.of(context)!;

    final (title, desc) = switch (option) {
      DaySchedule.anyTime => (loc.anyTime, loc.noFixedTime),
      DaySchedule.morning => (
        loc.morning,
        loc.habitAppearsInSection(loc.morning),
      ),
      DaySchedule.afternoon => (
        loc.afternoon,
        loc.habitAppearsInSection(loc.afternoon),
      ),
      DaySchedule.evening => (
        loc.evening,
        loc.habitAppearsInSection(loc.evening),
      ),
      DaySchedule.specificTime => (loc.specificTime, loc.specificTimeDesc),
      DaySchedule.timeRange => (loc.timeRange, loc.timeRangeDesc),
    };

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? cp.main.withValues(alpha: 0.1) : null,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? cp.main.withValues(alpha: 0.3) : cp.border,
          ),
        ),
        child: Row(
          spacing: 10,
          children: [
            AnimatedRadio<DaySchedule>(
              value: option,
              groupValue: selected ? option : null,
              onChanged: (_) => onTap(),
            ),
            Expanded(
              child: Column(
                spacing: 4,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: cp.text,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    desc,
                    style: TextStyle(
                      color: cp.isDark ? cp.greyText : cp.lightGreyText,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
