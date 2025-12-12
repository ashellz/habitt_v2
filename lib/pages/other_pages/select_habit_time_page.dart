import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:habitt/providers/theme_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/widgets/default/gradient_background.dart';
import 'package:habitt/widgets/default/nav_back_button.dart';
import 'package:habitt/widgets/habit_details/select_habit_time_page/habit_time_bottom_options.dart';
import 'package:habitt/widgets/habit_details/select_habit_time_page/select_habit_time_body.dart';
import 'package:provider/provider.dart';

class SelectHabitTimePage extends StatelessWidget {
  const SelectHabitTimePage({super.key});

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    final stateProvider = context.watch<StateProvider>();

    final timeIntervalStart = stateProvider.timeIntervalStart;
    final timeIntervalEnd = stateProvider.timeIntervalEnd;
    final timeIntervalEnabled = stateProvider.timeIntervalEnabled;

    final listViewHeight = MediaQuery.of(context).size.height - 293;

    return AnnotatedRegion(
      value: SystemUiOverlayStyle(
        statusBarColor: tp.backgroundColor,
        statusBarIconBrightness: tp.isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness:
            tp.isDark ? Brightness.dark : Brightness.light, // for iOS
      ),
      child: Scaffold(
        backgroundColor: tp.backgroundColor,
        floatingActionButton: FloatingActionButton(
          elevation: 0,
          backgroundColor: tp.primaryColor,
          onPressed: () {
            showModalBottomSheet(
              context: context,
              builder:
                  (context) =>
                      HabitTimeBottomOptions(tp: tp, sp: stateProvider),
            );
          },
          child: AnimatedRotation(
            duration: const Duration(milliseconds: 250),
            turns: stateProvider.showAllHabits ? 0.25 : -0.25,
            child: Icon(Icons.chevron_right, color: tp.primaryTextColor),
          ),
        ),
        body: GradientBackground(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      NavBackButton(tp: tp),
                      Spacer(),
                      FloatingActionButton(
                        mini: true,
                        elevation: 0,
                        backgroundColor: tp.secondaryColor,
                        onPressed: () => stateProvider.toggleShowAllHabits(),
                        child: SvgPicture.asset(
                          stateProvider.showAllHabits
                              ? "assets/images/svg/show.svg"
                              : "assets/images/svg/dont-show.svg",
                          colorFilter: ColorFilter.mode(
                            tp.primaryTextColor,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    "SELECT HABIT TIME:",
                    style: TextStyle(
                      letterSpacing: 2,
                      fontSize: 48,
                      fontWeight: FontWeight.w200,
                      height: 1.2,
                      color: tp.primaryColor,
                    ),
                  ),
                  SelectHabitTimeBody(
                    listViewHeight: listViewHeight,
                    timeIntervalStart: timeIntervalStart,
                    timeIntervalEnd: timeIntervalEnd,
                    timeIntervalEnabled: timeIntervalEnabled,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
