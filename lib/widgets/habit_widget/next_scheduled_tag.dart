import 'package:flutter/material.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/util/next_scheduled_label.dart';
import 'package:habitt/widgets/habit_widget/habit_tag.dart';

/// Tag with a calendar icon and the day a habit is next scheduled on, for
/// habits that are not scheduled today ("Tomorrow", "Tuesday", "12th Oct").
class NextScheduledTag extends StatelessWidget {
  const NextScheduledTag({super.key, required this.date, required this.cp});

  final DateTime date;
  final ColorProvider cp;

  @override
  Widget build(BuildContext context) {
    final color = cp.isDark ? cp.greyText : cp.lightGreyText;
    return HabitTag(
      label: nextScheduledLabel(
        AppLocalizations.of(context)!,
        Localizations.localeOf(context),
        date,
      ),
      color: color,
      backgroundColor: cp.habitBg,
      icon: Icon(Icons.event_rounded, size: 12, color: color),
    );
  }
}
