import 'package:flutter/material.dart';
import 'package:habitt/providers/theme_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/widgets/custom_shader_mask.dart';
import 'package:habitt/widgets/select_habit_time_page/habit_time_bottom_options.dart';
import 'package:provider/provider.dart';
import 'package:tinycolor2/tinycolor2.dart';

enum TimeType { regular, midnight, overday }

class SelectHabitTimeBody extends StatefulWidget {
  const SelectHabitTimeBody({
    super.key,
    required this.listViewHeight,
    required this.timeIntervalEnabled,
    required this.timeIntervalStart,
    required this.timeIntervalEnd,
  });

  final bool timeIntervalEnabled;
  final double listViewHeight;
  final int timeIntervalStart;
  final int timeIntervalEnd;

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

  @override
  void didUpdateWidget(covariant oldWidget) {
    super.didUpdateWidget(oldWidget);

    final durationMinutes = widget.timeIntervalEnd - widget.timeIntervalStart;

    hourHeight =
        durationMinutes < 0
            ? 50
            : durationMinutes <= 10
            ? 300
            : durationMinutes <= 30
            ? 200
            : 100;

    if (oldWidget.timeIntervalStart != widget.timeIntervalStart ||
        oldWidget.timeIntervalEnd != widget.timeIntervalEnd ||
        oldWidget.timeIntervalEnabled != widget.timeIntervalEnabled) {
      _scrollController.animateTo(
        (widget.timeIntervalStart / 60 * hourHeight) - 150,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  bool shouldShowHabitName(TimeType timeType) {
    return !(widget.timeIntervalEnd - widget.timeIntervalStart <= 5 &&
        timeType == TimeType.regular);
  }

  Color getContainerColor(ThemeProvider tp, StateProvider sp) {
    if (tp.isDark) {
      return sp.habitColor?.darken(50).withOpacity(0.7) ??
          tp.primaryColor.darken(50).withOpacity(0.7);
    } else {
      return sp.habitColor?.lighten(30).withOpacity(0.7) ??
          tp.primaryColor.lighten(30).withOpacity(0.7);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    final sp = context.watch<StateProvider>();
    final habitName = sp.nameController.text;

    TimeType timeType =
        widget.timeIntervalEnd == 0
            ? TimeType.midnight
            : widget.timeIntervalStart > widget.timeIntervalEnd
            ? TimeType.overday
            : TimeType.regular;

    debugPrint("Time type: $timeType");

    double? startHour =
        sp.timeIntervalEnabled ? widget.timeIntervalStart / 60 : null;

    double? duration() {
      if (!sp.timeIntervalEnabled) return null;
      if (timeType == TimeType.regular) {
        return sp.timeIntervalEnd / 60 - widget.timeIntervalStart / 60;
      } else {
        return sp.timeIntervalEnd / 60;
      }
    }

    // if start hour is bigger than the end hour
    // then extend the container until the end of day
    // and show another container from beggining of the day
    // until the end time

    return CustomShaderMask(
      child: SizedBox(
        height: widget.listViewHeight,
        child: ListView(
          scrollDirection: Axis.vertical,
          children: [
            CustomShaderMask(
              child: SizedBox(
                height: widget.listViewHeight - 100,
                child: ListView(
                  controller: _scrollController,
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
                                      style: TextStyle(
                                        color: tp.mutedTextColor,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Divider(
                                      thickness: 1,
                                      height: 0,
                                      color: tp.mutedTextColor.withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          if (startHour != null && duration() != null)
                            AnimatedPositioned(
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.fastOutSlowIn,
                              top: startHour * hourHeight + hourHeight / 2,
                              left: 60,
                              right: 20,
                              height:
                                  timeType != TimeType.regular
                                      ? (24 * hourHeight) -
                                          (startHour * hourHeight)
                                      : duration()! * hourHeight,
                              child: Container(
                                padding: EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: getContainerColor(tp, sp),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 4,
                                      height: double.infinity,
                                      decoration: BoxDecoration(
                                        color: sp.habitColor ?? tp.primaryColor,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                    SizedBox(width: 5),
                                    AnimatedSwitcher(
                                      duration: const Duration(
                                        milliseconds: 500,
                                      ),
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
                                          shouldShowHabitName(timeType),
                                        ),
                                        child:
                                            shouldShowHabitName(timeType)
                                                ? Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  spacing: 4,
                                                  children: [
                                                    Image.asset(
                                                      sp.iconPath,
                                                      width: 24,
                                                      height: 24,
                                                    ),
                                                    Text(
                                                      habitName,
                                                      style: TextStyle(
                                                        color:
                                                            sp.habitColor ??
                                                            tp.primaryColor,
                                                        fontWeight:
                                                            FontWeight.w500,
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

                          if (timeType == TimeType.overday &&
                              sp.timeIntervalEnabled)
                            AnimatedPositioned(
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.fastOutSlowIn,
                              top: hourHeight / 2,
                              left: 60,
                              right: 20,
                              height: widget.timeIntervalEnd / 60 * hourHeight,
                              child: Container(
                                padding: EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: sp.habitColor ?? tp.primaryColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    width: 4,
                                    height: double.infinity,
                                    decoration: BoxDecoration(
                                      color: sp.habitColor ?? tp.primaryColor,
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
            ),

            HabitTimeBottomOptions(tp: tp, sp: sp),
          ],
        ),
      ),
    );
  }
}
