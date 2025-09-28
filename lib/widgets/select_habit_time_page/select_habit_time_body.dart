import 'package:flutter/material.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/widgets/faded_list_view.dart';
import 'package:habitt/widgets/select_habit_time_page/habit_time_bottom_options.dart';
import 'package:provider/provider.dart';

class SelectHabitTimeBody extends StatefulWidget {
  const SelectHabitTimeBody({
    super.key,
    required this.listViewHeight,
    required this.timeIntervalStart,
    required this.timeIntervalEnd,
  });

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

    if (oldWidget.timeIntervalStart != widget.timeIntervalStart) {
      _scrollController.animateTo(
        (widget.timeIntervalStart / 60 * hourHeight) - 150,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      print("asdafsaf: ${widget.timeIntervalStart / 60 * hourHeight}");
      print("time changed: ${widget.timeIntervalStart}");
    }

    if (oldWidget.timeIntervalEnd != widget.timeIntervalEnd) {
      _scrollController.animateTo(
        (widget.timeIntervalStart / 60 * hourHeight) - 150,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      print("time changed: ${widget.timeIntervalEnd}");
    }
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final sp = context.watch<StateProvider>();
    final habitName = sp.nameController.text;

    bool isOverADay = widget.timeIntervalStart > widget.timeIntervalEnd;
    debugPrint("isOverADay: $isOverADay");

    double? startHour =
        sp.timeIntervalEnabled ? widget.timeIntervalStart / 60 : null;
    double? duration =
        isOverADay
            ? sp.timeIntervalEnd / 60
            : sp.timeIntervalEnabled
            ? sp.timeIntervalEnd / 60 - widget.timeIntervalStart / 60
            : null;

    // if start hour is bigger than the end hour
    // then extend the container until the end of day
    // and show another container from beggining of the day
    // until the end time

    return FadedListView(
      scrollDirection: Axis.vertical,
      height: widget.listViewHeight,
      children: [
        FadedListView(
          scrollDirection: Axis.vertical,
          height: widget.listViewHeight,
          children: [
            SizedBox(
              height: widget.listViewHeight - 100,
              child: ListView(
                controller: _scrollController,
                scrollDirection: Axis.vertical,
                children: [
                  SizedBox(
                    height: 24 * hourHeight, // full day
                    child: Stack(
                      children: [
                        // Background hours
                        for (int i = 0; i < 24; i++)
                          AnimatedPositioned(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.fastOutSlowIn,
                            top: i * hourHeight,
                            left: 0,
                            right: 0,
                            height: hourHeight,
                            child: Row(
                              children: [
                                Text(
                                  "${i.toString().padLeft(2, '0')}:00",
                                  style: TextStyle(color: cp.mutedTextColor),
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Divider(
                                    thickness: 1,
                                    color: cp.mutedTextColor.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        if (startHour != null && duration != null)
                          AnimatedPositioned(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.fastOutSlowIn,
                            top: startHour * hourHeight + hourHeight / 2,
                            left: 60,
                            right: 20,
                            height:
                                isOverADay
                                    ? (24 * hourHeight) -
                                        (startHour * hourHeight +
                                            hourHeight / 2)
                                    : duration * hourHeight,
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
                                        widget.timeIntervalEnd -
                                                    widget.timeIntervalStart >
                                                5 ||
                                            isOverADay,
                                      ),
                                      child:
                                          widget.timeIntervalEnd -
                                                          widget
                                                              .timeIntervalStart >
                                                      5 ||
                                                  isOverADay
                                              ? Text(
                                                habitName,
                                                style: TextStyle(
                                                  color:
                                                      cp.colorScheme.vividColor,
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

                        if (isOverADay && sp.timeIntervalEnabled)
                          AnimatedPositioned(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.fastOutSlowIn,
                            top: 0,
                            left: 60,
                            right: 20,
                            height: widget.timeIntervalEnd / 60 * hourHeight,
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

            HabitTimeBottomOptions(cp: cp, sp: sp),
          ],
        ),
      ],
    );
  }
}
