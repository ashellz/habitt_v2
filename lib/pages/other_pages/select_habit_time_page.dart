import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:habitt/providers/theme_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/services/color_service.dart';
import 'package:habitt/widgets/default/default_annotated_region.dart';
import 'package:habitt/widgets/default/gradient_background.dart';
import 'package:habitt/widgets/default/nav_back_button.dart';
import 'package:habitt/widgets/habit_details/select_habit_time_page/habit_time_bottom_options.dart';
import 'package:habitt/widgets/habit_details/select_habit_time_page/select_habit_time_body.dart';
import 'package:provider/provider.dart';

class SelectHabitTimePage extends StatefulWidget {
  const SelectHabitTimePage({super.key});

  @override
  State<SelectHabitTimePage> createState() => _SelectHabitTimePageState();
}

class _SelectHabitTimePageState extends State<SelectHabitTimePage> {
  bool sheetExpanded = false; // tracks if the bottom sheet is open

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    final stateProvider = context.watch<StateProvider>();

    final timeIntervalStart = stateProvider.timeIntervalStart;
    final timeIntervalEnd = stateProvider.timeIntervalEnd;
    final timeIntervalEnabled = stateProvider.timeIntervalEnabled;

    final listViewHeight = MediaQuery.of(context).size.height - 293;

    return DefaultAnnotatedRegion(
      child: Scaffold(
        backgroundColor: tp.backgroundColor,
        floatingActionButton: FloatingActionButton(
          heroTag: 'select-time-main-fab',
          elevation: 0,
          backgroundColor: tp.primaryColor,
          onPressed: () async {
            setState(() => sheetExpanded = true);
            await showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: tp.backgroundColor,
              builder: (context) => HabitTimeBottomOptions(tp: tp),
            );
            if (mounted) {
              setState(() => sheetExpanded = false);
            }
          },
          child: AnimatedRotation(
            duration: const Duration(milliseconds: 250),
            turns: sheetExpanded ? 0.25 : 0.75,
            child: Icon(Icons.chevron_right, color: ColorService.bgSurface),
          ),
        ),
        body: GradientBackground(
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      NavBackButton(tp: tp),
                      Spacer(),
                      FloatingActionButton(
                        heroTag: 'select-time-toggle-fab',
                        mini: true,
                        elevation: 0,
                        backgroundColor: tp.secondaryColor,
                        onPressed: () => stateProvider.toggleShowAllHabits(),
                        child: SvgPicture.asset(
                          stateProvider.showAllHabits
                              ? "assets/images/svg/show.svg"
                              : "assets/images/svg/dont-show.svg",
                          colorFilter: ColorFilter.mode(
                            ColorService.bgSurface,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    "SELECT HABIT TIME:",
                    style: TextStyle(
                      letterSpacing: 2,
                      fontSize: 48,
                      fontWeight: FontWeight.w200,
                      height: 1.2,
                      color: tp.primaryColor,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: SelectHabitTimeBody(
                    listViewHeight: listViewHeight,
                    timeIntervalStart: timeIntervalStart,
                    timeIntervalEnd: timeIntervalEnd,
                    timeIntervalEnabled: timeIntervalEnabled,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
