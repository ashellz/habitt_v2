import 'package:flutter/material.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/providers/theme_provider.dart';
import 'package:habitt/widgets/habit_details/select_habit_time_page/select_habit_time_body.dart';
import 'package:provider/provider.dart';

class AllHabitsOnTimelineStack extends StatelessWidget {
  const AllHabitsOnTimelineStack({super.key, required this.hourHeight});

  final double hourHeight;

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    final habits = context.watch<HabitProvider>().habits;

    return Stack(
      children: [
        for (var habit in habits)
          if (habit.timeIntervalEnabled)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 500),
              curve: Curves.fastOutSlowIn,
              top: habit.getStartHour() * hourHeight + hourHeight / 2,
              left: 60,
              right: 20,
              height:
                  habit.getTimeType() != TimeType.regular
                      ? (24 * hourHeight) - (habit.getStartHour() * hourHeight)
                      : habit.getTimeDuration() * hourHeight,
              child: Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: habit.getContainerColor(tp),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 4,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        color: habit.getNameColor(tp),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    SizedBox(width: 5),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      transitionBuilder: (child, animation) {
                        final offsetAnimation = Tween<Offset>(
                          begin: const Offset(0.0, 0.2),
                          end: Offset.zero,
                        ).animate(animation);

                        return SlideTransition(
                          position: offsetAnimation,
                          child: FadeTransition(
                            opacity: animation,
                            child: child,
                          ),
                        );
                      },
                      child: KeyedSubtree(
                        key: ValueKey<bool>(
                          habit.shouldShowName(habit.getTimeType()),
                        ),
                        child:
                            habit.shouldShowName(habit.getTimeType())
                                ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  spacing: 4,
                                  children: [
                                    Image.asset(
                                      habit.iconPath,
                                      width: 24,
                                      height: 24,
                                    ),
                                    Text(
                                      habit.name,
                                      style: TextStyle(
                                        color: habit.getNameColor(tp),
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: 1,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                )
                                : Container(),
                      ),
                    ),
                  ],
                ),
              ),
            ),

        for (var habit in habits)
          if (habit.timeIntervalEnabled)
            if (habit.getTimeType() == TimeType.overday)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 500),
                curve: Curves.fastOutSlowIn,
                top: hourHeight / 2,
                left: 60,
                right: 20,
                height: habit.timeIntervalEnd / 60 * hourHeight,
                child: Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: habit.getContainerColor(tp),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: 4,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        color: habit.getNameColor(tp),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
      ],
    );
  }
}
