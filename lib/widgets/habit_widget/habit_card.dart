import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/pages/other_pages/habit_details_page.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/widgets/default/new_default_button.dart';
import 'package:habitt/widgets/habit_widget/new_habit_icon.dart';
import 'package:habitt/widgets/main_page/habits/habit_widget/main_habit_info.dart';
import 'package:provider/provider.dart';

class HabitCard extends StatefulWidget {
  const HabitCard({
    required this.habit,
    required this.cp,
    required this.size,
    required Key key,
    this.deleted = false,
    this.onRestored,
  }) : super(key: key);

  final Habit habit;
  final ColorProvider cp;
  final double size;
  final bool deleted;
  final VoidCallback? onRestored;

  @override
  State<HabitCard> createState() => _HabitCardState();
}

String _deletedTimeAgoLabel(AppLocalizations loc, DateTime? deletedAt) {
  if (deletedAt == null) return loc.deletedToday;
  final days = DateTime.now().toUtc().difference(deletedAt).inDays;
  if (days <= 0) return loc.deletedToday;
  if (days == 1) return loc.deletedOneDayAgo;
  return loc.deletedDaysAgoLabel(days);
}

class _HabitCardState extends State<HabitCard> {
  bool isRestoring = false;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            settings: RouteSettings(arguments: widget.habit.id),
            builder: (_) => HabitDetailsPage(habitId: widget.habit.id),
          ),
        );
      },
      child: Container(
        alignment: Alignment.topLeft,
        width: widget.size,
        height: widget.deleted ? null : widget.size,
        padding: const EdgeInsets.all(16),
        decoration: ShapeDecoration(
          color: Colors.transparent,
          shape: RoundedRectangleBorder(
            side: BorderSide(width: 1, color: widget.cp.border),
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                NewHabitIcon(
                  iconPath: widget.habit.iconPath,
                  isCompleted: false,
                ),
                if (widget.deleted)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        loc.deleted,
                        style: TextStyle(
                          color:
                              widget.cp.isDark
                                  ? widget.cp.lightGreyText
                                  : widget.cp.greyText,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        _deletedTimeAgoLabel(loc, widget.habit.deletedAt),
                        style: TextStyle(
                          color:
                              widget.cp.isDark
                                  ? widget.cp.lightGreyText
                                  : widget.cp.greyText,
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  )
                else
                  SvgPicture.asset(
                    "assets/images/new-svg/reorder.svg",
                    colorFilter: ColorFilter.mode(
                      widget.cp.disabled,
                      BlendMode.srcIn,
                    ),
                  ),
              ],
            ),
            SizedBox(height: 16),
            MainHabitInfo(habit: widget.habit, cp: widget.cp, habitsPage: true),
            if (widget.deleted)
              Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: NewDefaultButton.primarySmall(
                  width: null,
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  isLoading: isRestoring,
                  label: loc.restore,
                  onPressed: () async {
                    setState(() {
                      isRestoring = true;
                    });
                    await Future.delayed(const Duration(milliseconds: 400));
                    if (!context.mounted) return;
                    await context.read<HabitProvider>().restoreHabit(
                      widget.habit,
                    );
                    widget.onRestored?.call();
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
