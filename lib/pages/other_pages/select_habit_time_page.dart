import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:habitt/providers/theme_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/widgets/default/gradient_background.dart';
import 'package:habitt/widgets/default/nav_back_button.dart';
import 'package:habitt/widgets/select_habit_time_page/select_habit_time_body.dart';
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
        body: GradientBackground(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  NavBackButton(tp: tp),
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
