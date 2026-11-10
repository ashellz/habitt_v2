import 'package:flutter/material.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/widgets/default/dual_option_selector.dart';
import 'package:provider/provider.dart';

/// Android only: whether habit alarms ring during Do Not Disturb, as an
/// Off / Alarms selector ("Alarms" makes clear regular reminders stay quiet).
/// The same widget is used on the notification settings page and in the
/// dialog shown the first time an alarm is turned on. See
/// docs/habit_alarms.md.
class AlarmDndSetting extends StatelessWidget {
  const AlarmDndSetting({
    super.key,
    required this.ringDuringDnd,
    required this.onChanged,
    this.color,
    this.selectorColor,
  });

  final bool ringDuringDnd;
  final ValueChanged<bool> onChanged;

  /// Background of the row; defaults to the settings page card colour.
  final Color? color;

  /// Background of the Off / Alarms pill; defaults to the field colour.
  final Color? selectorColor;

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final loc = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        // ─── Selector row ─────────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.only(top: 4, left: 12, right: 4, bottom: 4),
          clipBehavior: Clip.antiAlias,
          decoration: ShapeDecoration(
            color: color ?? (cp.isDark ? cp.habitBg : cp.bg),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          child: Row(
            spacing: 12,
            children: [
              Expanded(
                child: Text(
                  loc.alarmDndTitle,
                  style: TextStyle(
                    color: cp.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              SizedBox(
                width: 190,
                child: DualOptionSelector<bool>(
                  firstLabel: loc.alarmDndOff,
                  secondLabel: loc.alarmDndAlarms,
                  firstValue: false,
                  secondValue: true,
                  selectedValue: ringDuringDnd,
                  allowDeselect: false,
                  color: selectorColor,
                  onSelect: (value) {
                    if (value != null) onChanged(value);
                  },
                ),
              ),
            ],
          ),
        ),
        // ─── Explanation ──────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            loc.alarmDndDesc,
            style: TextStyle(color: cp.lightGreyText, fontSize: 14),
          ),
        ),
      ],
    );
  }
}
