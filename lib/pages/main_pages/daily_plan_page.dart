import 'dart:async';

import 'package:flutter/material.dart';
import 'package:habitt/providers/theme_provider.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/widgets/default/custom_shader_mask.dart';
import 'package:habitt/widgets/default/default_annotated_region.dart';
import 'package:habitt/widgets/habit_details/select_habit_time_page/all_habits_on_time_line_stack.dart';
import 'package:provider/provider.dart';
import 'package:habitt/widgets/default/gradient_background.dart';
import 'package:habitt/widgets/default/nav_back_button.dart';

class DailyPlanPage extends StatelessWidget {
  const DailyPlanPage({super.key});

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();

    // bottom and top safe area
    final double safeArea = kToolbarHeight + kBottomNavigationBarHeight;
    final listViewHeight = MediaQuery.of(context).size.height - safeArea - 108;

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
                  Text(
                    "Daily Plan",
                    style: TextStyle(
                      fontSize: 38,
                      color: tp.primaryTextColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SelectHabitTimeBody(listViewHeight: listViewHeight),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SelectHabitTimeBody extends StatefulWidget {
  const SelectHabitTimeBody({super.key, required this.listViewHeight});

  final double listViewHeight;

  @override
  State<SelectHabitTimeBody> createState() => _SelectHabitTimeBodyState();
}

class _SelectHabitTimeBodyState extends State<SelectHabitTimeBody> {
  DateTime currentTime = DateTime.now();
  double hourHeight = 100;
  double? topOffsetForIndicator;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _updateTopOffsetIndicator();
      _scrollController.animateTo(
        topOffsetForIndicator! - widget.listViewHeight / 2,
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });

    Timer.periodic(Duration(minutes: 1), (timer) async {
      setState(() {
        currentTime = DateTime.now();
      });
      await _updateTopOffsetIndicator();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();

    super.dispose();
  }

  Future<void> _updateTopOffsetIndicator() async {
    setState(() {
      topOffsetForIndicator =
          currentTime.hour * hourHeight +
          currentTime.minute / 60 * hourHeight +
          hourHeight / 2;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    final habitProvider = context.watch<HabitProvider>();

    final habits = habitProvider.habits;

    for (final habit in habits) {
      debugPrint(
        "Habit: ${habit.name}, start: ${habit.timeIntervalStart}, end: ${habit.timeIntervalEnd}, enabled: ${habit.timeIntervalEnabled}",
      );
    }

    // if start hour is bigger than the end hour
    // then extend the container until the end of day
    // and show another container from beggining of the day
    // until the end time

    return CustomShaderMask(
      child: SizedBox(
        height: widget.listViewHeight,
        child: ListView(
          controller: _scrollController,
          scrollDirection: Axis.vertical,
          children: [
            SizedBox(
              height: 24 * hourHeight + hourHeight, // full day
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 4.0),
                    child: SizedBox(
                      width: 40,
                      child: Column(
                        children: [
                          for (int i = 0; i < 25; i++) ...[
                            Transform.translate(
                              offset: const Offset(0, -2),
                              child: SizedBox(
                                height: hourHeight,
                                child: Center(
                                  child: Text(
                                    "${(i == 24 ? 0 : i).toString().padLeft(2, '0')}:00",
                                    style: TextStyle(color: tp.mutedTextColor),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Stack(
                          children: [
                            for (int i = 0; i < 25; i++)
                              AnimatedPositioned(
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.fastOutSlowIn,
                                top: i * hourHeight + hourHeight / 2,
                                left: 0,
                                right: 0,
                                height: hourHeight,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Divider(
                                        thickness: 1,
                                        endIndent: 16,
                                        height: 0,
                                        color: tp.mutedTextColor.withOpacity(
                                          0.7,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            AllHabitsOnTimelineStack(
                              hourHeight: hourHeight,
                              maxWidth: constraints.maxWidth,
                            ),
                            // line indicating current time
                            AnimatedPositioned(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.fastOutSlowIn,
                              top: topOffsetForIndicator ?? 0,
                              left: 0,
                              right: 0,
                              child: AnimatedOpacity(
                                duration: const Duration(milliseconds: 500),
                                opacity: topOffsetForIndicator != null ? 1 : 0,
                                child: SizedBox(
                                  width: double.infinity,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Transform.translate(
                                        offset: const Offset(0, -10),
                                        child: Container(
                                          height: 20,
                                          width: 50,
                                          decoration: ShapeDecoration(
                                            color: tp.primaryColor,
                                            shape: StadiumBorder(),
                                          ),

                                          child: Text(
                                            '${currentTime.hour.toString().padLeft(2, '0')}:${currentTime.minute.toString().padLeft(2, '0')}',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 1,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Container(
                                          height: 1,
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            color: tp.primaryColor,
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
