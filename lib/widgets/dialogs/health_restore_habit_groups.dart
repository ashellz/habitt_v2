import 'package:flutter/material.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/widgets/habit_widget/text_icon.dart';
import 'package:provider/provider.dart';

/// The restore offer's habits on a phone that can read only some of them:
/// the ones that will sync, then the Apple Health exclusive ones under their
/// own label, dimmed.
/// Pills look like the premade habit picker's.
class HealthRestoreHabitGroups extends StatelessWidget {
  const HealthRestoreHabitGroups({
    super.key,
    required this.trackable,
    required this.untrackable,
  });

  final List<Habit> trackable;
  final List<Habit> untrackable;

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final loc = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 20,
      children: [
        _pills(trackable),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 10,
          children: [
            _group(
              cp,
              loc.healthRestoreAppleHealthOnly,
              untrackable,
              dimmed: true,
            ),
            Text(
              loc.healthRestoreIosOnlyDesc,
              style: TextStyle(color: cp.lightGreyText, fontSize: 13),
            ),
          ],
        ),
      ],
    );
  }

  // ─── Group ────────────────────────────────────────────

  Widget _group(
    ColorProvider cp,
    String title,
    List<Habit> habits, {
    bool dimmed = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 10,
      children: [
        Text(
          title,
          style: TextStyle(
            color: cp.text,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        Opacity(opacity: dimmed ? 0.5 : 1, child: _pills(habits)),
      ],
    );
  }

  Widget _pills(List<Habit> habits) => Builder(
    builder: (context) {
      final cp = context.watch<ColorProvider>();
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [for (final habit in habits) _pill(cp, habit)],
      );
    },
  );

  Widget _pill(ColorProvider cp, Habit habit) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: cp.field,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 10,
        children: [
          TextIcon(habit.iconPath, size: 24),
          Flexible(
            child: Text(
              habit.name,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: TextStyle(color: cp.text, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
