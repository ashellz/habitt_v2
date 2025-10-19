import 'package:flutter/material.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/widgets/faded_list_view.dart';
import 'package:habitt/widgets/select_habit_time_page/select_habit_time_body.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:habitt/widgets/gradient_background.dart';
import 'package:habitt/widgets/nav_back_button.dart';

class DailyPlanPage extends StatelessWidget {
  const DailyPlanPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorProvider = context.watch<ColorProvider>();

    final listViewHeight = MediaQuery.of(context).size.height - 217;

    return AnnotatedRegion(
      value: SystemUiOverlayStyle(
        statusBarColor: colorProvider.backgroundColor,
        statusBarIconBrightness:
            colorProvider.isDarkMode ? Brightness.light : Brightness.dark,
        statusBarBrightness:
            colorProvider.isDarkMode
                ? Brightness.dark
                : Brightness.light, // for iOS
      ),
      child: Scaffold(
        backgroundColor: colorProvider.backgroundColor,
        body: GradientBackground(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  NavBackButton(colorProvider: colorProvider),
                  Text(
                    "Daily Plan",
                    style: TextStyle(
                      fontSize: 38,
                      color: colorProvider.textColor,
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
  double hourHeight = 100;
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  bool shouldShowHabitName(TimeType timeType, Habit habit) {
    return !(habit.timeIntervalEnd - habit.timeIntervalStart <= 5 &&
        timeType == TimeType.regular);
  }

  TimeType getHabitTimeType(Habit habit) {
    return habit.timeIntervalEnd == 0
        ? TimeType.midnight
        : habit.timeIntervalStart > habit.timeIntervalEnd
        ? TimeType.overday
        : TimeType.regular;
  }

  double duration(Habit habit) {
    if (getHabitTimeType(habit) == TimeType.regular) {
      return habit.timeIntervalEnd / 60 - habit.timeIntervalStart / 60;
    } else {
      return habit.timeIntervalEnd / 60;
    }
  }

  double getHabitStartHour(Habit habit) {
    return habit.timeIntervalStart / 60;
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
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
        child: FadedListView(
          height: widget.listViewHeight,
          scrollDirection: Axis.vertical,
          children: [
            SizedBox(
              height: 24 * hourHeight + hourHeight, // full day
              child: Stack(
                children: [
                  // Background hours
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
                          Transform.translate(
                            offset: Offset(0, -10),
                            child: Text(
                              "${(i == 24 ? 0 : i).toString().padLeft(2, '0')}:00",
                              style: TextStyle(color: cp.mutedTextColor),
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Divider(
                              thickness: 1,
                              height: 0,
                              color: cp.mutedTextColor.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),

                  for (var habit in habits)
                    if (habit.timeIntervalEnabled)
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.fastOutSlowIn,
                        top:
                            getHabitStartHour(habit) * hourHeight +
                            hourHeight / 2,
                        left: 60,
                        right: 20,
                        height:
                            getHabitTimeType(habit) != TimeType.regular
                                ? (24 * hourHeight) -
                                    (getHabitStartHour(habit) * hourHeight)
                                : duration(habit) * hourHeight,
                        child: Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: cp.colorScheme.darkerStandardColor
                                .withOpacity(0.7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 4,
                                height: double.infinity,
                                decoration: BoxDecoration(
                                  color: cp.colorScheme.vividColor,
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
                                    shouldShowHabitName(
                                      getHabitTimeType(habit),
                                      habit,
                                    ),
                                  ),
                                  child:
                                      shouldShowHabitName(
                                            getHabitTimeType(habit),
                                            habit,
                                          )
                                          ? Text(
                                            habit.name,
                                            style: TextStyle(
                                              color: cp.colorScheme.vividColor,
                                              fontWeight: FontWeight.w500,
                                              letterSpacing: 1,
                                              fontSize: 16,
                                            ),
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
                      if (getHabitTimeType(habit) == TimeType.overday)
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
                              color: cp.colorScheme.darkerStandardColor
                                  .withOpacity(0.7),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                width: 4,
                                height: double.infinity,
                                decoration: BoxDecoration(
                                  color: cp.colorScheme.vividColor,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
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

class CustomShaderMask extends StatelessWidget {
  const CustomShaderMask({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (Rect bounds) {
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.white,
            Colors.white,
            Colors.transparent,
          ],
          stops: [0.0, 0.05, 0.95, 1.0],
        ).createShader(bounds);
      },
      blendMode: BlendMode.dstIn,
      child: child,
    );
  }
}
