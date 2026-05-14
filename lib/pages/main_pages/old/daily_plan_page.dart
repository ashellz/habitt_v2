import 'package:flutter/material.dart';
import 'package:habitt/providers/theme_provider.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/widgets/default/animated_completion_checkmark.dart';
import 'package:habitt/widgets/daily_plan_page/daily_plan_body.dart';
import 'package:habitt/widgets/default/default_annotated_region.dart';
import 'package:provider/provider.dart';
import 'package:habitt/widgets/default/gradient_background.dart';
import 'package:habitt/widgets/default/nav_back_button.dart';
import 'package:habitt/l10n/app_localizations.dart';

class DailyPlanPage extends StatelessWidget {
  const DailyPlanPage({super.key});

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    final loc = AppLocalizations.of(context)!;

    // bottom and top safe area
    final double safeArea = kToolbarHeight + kBottomNavigationBarHeight;
    final listViewHeight = MediaQuery.of(context).size.height - safeArea - 116;

    final habits = context.watch<HabitProvider>().habits;
    final completedHabitsCount =
        habits.where((habit) => habit.completed).length;
    final bool dayCompleted =
        habits.isNotEmpty && completedHabitsCount == habits.length;

    return DefaultAnnotatedRegion(
      child: Scaffold(
        backgroundColor: tp.backgroundColor,
        body: GradientBackground(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  NavBackButton(tp: tp),
                  Row(
                    spacing: 4,
                    children: [
                      Text(
                        loc.dailyPlan,
                        style: TextStyle(
                          fontSize: 38,
                          color: tp.primaryTextColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (dayCompleted) AnimatedCompletionCheckmark(size: 38),
                    ],
                  ),
                  DailyPlanBody(listViewHeight: listViewHeight),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
