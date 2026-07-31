import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/pages/other_pages/habit_details_page.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/widgets/default/new_default_button.dart';
import 'package:habitt/widgets/habit_widget/new_habit_icon.dart';
import 'package:habitt/widgets/main_page/habits/habit_widget/main_habit_info.dart';
import 'package:provider/provider.dart';

class HabitCard extends StatelessWidget {
  const HabitCard({
    required this.habit,
    required this.cp,
    required this.size,
    required Key key,
    this.deleted = false,
  }) : super(key: key);

  final Habit habit;
  final ColorProvider cp;
  final double size;
  final bool deleted;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            settings: RouteSettings(arguments: habit.id),
            builder: (_) => HabitDetailsPage(habitId: habit.id),
          ),
        );
      },
      child: Container(
        alignment: Alignment.topLeft,
        width: size,
        height: deleted ? null : size,
        padding: const EdgeInsets.all(16),
        decoration: ShapeDecoration(
          color: Colors.transparent,
          shape: RoundedRectangleBorder(
            side: BorderSide(width: 1, color: cp.border),
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
                NewHabitIcon(iconPath: habit.iconPath, isCompleted: false),
                if (deleted)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "Deleted",
                        style: TextStyle(
                          color: cp.isDark ? cp.lightGreyText : cp.greyText,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        "2 days ago",
                        style: TextStyle(
                          color: cp.isDark ? cp.lightGreyText : cp.greyText,
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  )
                else
                  SvgPicture.asset(
                    "assets/images/new-svg/reorder.svg",
                    colorFilter: ColorFilter.mode(cp.disabled, BlendMode.srcIn),
                  ),
              ],
            ),
            SizedBox(height: 16),
            MainHabitInfo(habit: habit, cp: cp, habitsPage: true),
            if (deleted)
              Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: NewDefaultButton.primarySmall(
                  width: null,

                  label: "Restore",
                  onPressed: () {
                    context.read<HabitProvider>().restoreHabit(habit);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
