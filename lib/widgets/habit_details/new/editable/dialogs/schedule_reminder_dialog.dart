import 'package:flutter/material.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/util/schedule_reminder.dart';
import 'package:habitt/widgets/default/animated_radio.dart';
import 'package:habitt/widgets/default/new_default_dialog.dart';
import 'package:provider/provider.dart';

/// Shown after an exact time / time range is set: offers to move the habit's
/// reminder to match. Pops the chosen offset in minutes (0 = at the time),
/// or null to keep the current reminder.
class ScheduleReminderDialog extends StatefulWidget {
  const ScheduleReminderDialog({
    super.key,
    required this.hasReminders,
    required this.remindersEnabled,
    required this.isRange,
    required this.startMinutes,
  });

  final bool hasReminders;
  final bool remindersEnabled;
  final bool isRange;
  final int startMinutes;

  @override
  State<ScheduleReminderDialog> createState() => _ScheduleReminderDialogState();
}

class _ScheduleReminderDialogState extends State<ScheduleReminderDialog> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final cp = context.watch<ColorProvider>();

    final desc =
        !widget.remindersEnabled
            ? loc.scheduleReminderDescOff
            : widget.hasReminders
            ? loc.scheduleReminderDescReplace
            : loc.scheduleReminderDescAdd;

    return NewDefaultDialog(
      title: loc.scheduleReminderTitle,
      desc: desc,
      primaryButtonLabel: loc.scheduleReminderSet,
      secondaryButtonLabel: loc.scheduleReminderKeep,
      onPrimaryButtonPressed: () => Navigator.of(context).pop(_selected),
      onSecondaryButtonPressed: () => Navigator.of(context).pop(),
      child: Column(
        spacing: 10,
        children: [
          for (final offset in availableReminderOffsets(widget.startMinutes))
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _selected = offset),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:
                      offset == _selected
                          ? cp.main.withValues(alpha: 0.1)
                          : null,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color:
                        offset == _selected
                            ? cp.main.withValues(alpha: 0.3)
                            : cp.border,
                  ),
                ),
                child: Row(
                  spacing: 10,
                  children: [
                    AnimatedRadio<int>(
                      value: offset,
                      groupValue: _selected,
                      onChanged: (_) => setState(() => _selected = offset),
                    ),
                    Expanded(
                      child: Text(
                        offset == 0
                            ? (widget.isRange
                                ? loc.scheduleReminderAtStart
                                : loc.scheduleReminderAtTime)
                            : loc.scheduleReminderMinutesBefore(offset),
                        style: TextStyle(
                          color: cp.text,
                          fontSize: 16,
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
}
