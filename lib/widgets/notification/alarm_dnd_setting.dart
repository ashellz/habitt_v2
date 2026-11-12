import 'package:flutter/material.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/widgets/default/new_default_switch.dart';
import 'package:provider/provider.dart';

/// Android only: whether habit alarms ring during Do Not Disturb, as a
/// regular toggle row.
/// The same widget is used on the notification settings page and in the
/// dialog shown the first time an alarm is turned on. See
/// docs/habit_alarms.md.
class AlarmDndSetting extends StatelessWidget {
  const AlarmDndSetting({
    super.key,
    required this.ringDuringDnd,
    required this.onChanged,
    this.color,
  });

  final bool ringDuringDnd;
  final ValueChanged<bool> onChanged;

  /// Background of the row; defaults to the settings page card colour.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final loc = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        // ─── Toggle row ───────────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
              NewDefaultSwitch(value: ringDuringDnd, onChanged: onChanged),
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
