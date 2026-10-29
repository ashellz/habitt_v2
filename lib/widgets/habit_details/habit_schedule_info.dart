import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/models/schedule_type.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/util/format_minutes_of_day.dart';
import 'package:habitt/util/next_progress_reset.dart';
import 'package:habitt/util/next_scheduled_label.dart';
import 'package:habitt/util/show_dialog_sheet.dart';
import 'package:habitt/widgets/default/new_default_dialog.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// Habit details: when the habit is scheduled next, and for weekly / monthly
/// "times a period" habits when their progress resets (with an info dialog).
class HabitScheduleInfo extends StatelessWidget {
  const HabitScheduleInfo({super.key, required this.habit, required this.cp});

  final Habit habit;
  final ColorProvider cp;

  // Fixed brand purple of the reset card; its tint is derived per mode.
  static const Color _resetPurple = Color(0xFF8165C8);

  @override
  Widget build(BuildContext context) {
    if (habit.isPaused == true || habit.isDeleted == true) {
      return const SizedBox.shrink();
    }

    final habitProvider = context.watch<HabitProvider>();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final nextDate = habitProvider.nextAppearance(habit);
    final resetDate = nextProgressReset(habit, today);
    if (nextDate == null && resetDate == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        spacing: 8,
        children: [
          if (nextDate != null) _scheduledCard(context, nextDate),
          if (resetDate != null) _resetCard(context, resetDate),
        ],
      ),
    );
  }

  // ─── Next scheduled ───────────────────────────────────

  Widget _scheduledCard(BuildContext context, DateTime date) {
    final loc = AppLocalizations.of(context)!;
    var label = nextScheduledLabel(loc, Localizations.localeOf(context), date);
    if (habit.timeIntervalEnabled) {
      label = loc.dateWithTimeLabel(
        label,
        formatMinutesOfDay(context, habit.timeIntervalStart),
      );
    }

    return _card(
      color: cp.isDark ? cp.field : cp.bg,
      border: Border.all(color: cp.border),
      title: loc.nextScheduledTitle,
      titleColor: cp.isDark ? cp.lightGreyText : cp.greyText,
      pillColor: cp.habitBg,
      pill: Text(label, style: TextStyle(color: cp.text, fontSize: 13)),
    );
  }

  // ─── Next reset ───────────────────────────────────────

  Widget _resetCard(BuildContext context, DateTime date) {
    final loc = AppLocalizations.of(context)!;
    final localeTag = Localizations.localeOf(context).toString();

    return _card(
      color:
          cp.isDark
              ? _resetPurple.withValues(alpha: 0.1)
              : const Color(0xFFF9F5FC),
      title: loc.nextResetTitle,
      titleColor: cp.text,
      pillColor:
          cp.isDark
              ? _resetPurple.withValues(alpha: 0.2)
              : const Color(0xFFF2E8FF),
      onPillTap: () => _showResetInfo(context),
      pill: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 12,
        children: [
          Text(
            DateFormat('EEE, d MMM', localeTag).format(date),
            style: TextStyle(color: cp.text, fontSize: 13),
          ),
          SvgPicture.asset('assets/images/new-svg/info.svg', width: 20),
        ],
      ),
    );
  }

  void _showResetInfo(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    showDialogSheet(
      context: context,
      builder:
          (dialogContext) => NewDefaultDialog(
            desc:
                habit.scheduleType == ScheduleType.monthly
                    ? loc.monthlyResetInfo
                    : loc.weeklyResetInfo,
            showSecondaryButton: false,
            primaryButtonLabel: loc.ok,
          ),
    );
  }

  // ─── Shared card ──────────────────────────────────────

  Widget _card({
    required Color color,
    required String title,
    required Color titleColor,
    required Color pillColor,
    required Widget pill,
    BoxBorder? border,
    VoidCallback? onPillTap,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 4, 4, 4),
      decoration: BoxDecoration(
        color: color,
        border: border,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              title,
              style: TextStyle(color: titleColor, fontSize: 13),
            ),
          ),
          GestureDetector(
            onTap: onPillTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: pillColor,
                borderRadius: BorderRadius.circular(100),
              ),
              child: pill,
            ),
          ),
        ],
      ),
    );
  }
}
