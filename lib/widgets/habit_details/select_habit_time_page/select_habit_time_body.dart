import 'package:flutter/material.dart';
import 'package:habitt/models/timeline/primary_habit_config.dart';
import 'package:habitt/providers/theme_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/widgets/default/custom_shader_mask.dart';
import 'package:habitt/widgets/habit_details/select_habit_time_page/all_habits_on_time_line_stack.dart';
import 'package:provider/provider.dart';
import 'package:tinycolor2/tinycolor2.dart';
import 'package:habitt/l10n/app_localizations.dart';

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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToStartTime();
    });
  }

  void _scrollToStartTime() {
    final durationMinutes = widget.timeIntervalEnd - widget.timeIntervalStart;

    setState(() {
      hourHeight =
          durationMinutes < 0
              ? 50
              : durationMinutes <= 10
              ? 300
              : durationMinutes <= 30
              ? 200
              : 100;
    });

    _scrollController.animateTo(
      (widget.timeIntervalStart / 60 * hourHeight) - 150,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant oldWidget) {
    super.didUpdateWidget(oldWidget);

    final durationMinutes = widget.timeIntervalEnd - widget.timeIntervalStart;

    setState(() {
      hourHeight =
          durationMinutes < 0
              ? 50
              : durationMinutes <= 10
              ? 300
              : durationMinutes <= 30
              ? 200
              : 100;
    });

    if (oldWidget.timeIntervalStart != widget.timeIntervalStart ||
        oldWidget.timeIntervalEnd != widget.timeIntervalEnd ||
        oldWidget.timeIntervalEnabled != widget.timeIntervalEnabled) {
      _scrollController.animateTo(
        (widget.timeIntervalStart / 60 * hourHeight),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    final sp = context.watch<StateProvider>();
    final habitName =
        sp.nameController.text.isEmpty ? "Habit name" : sp.nameController.text;

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
                              ignoreId: sp.selectedHabitId,
                              hourHeight: hourHeight,
                              dimOthers: true,
                              showOthers: sp.showAllHabits,
                              maxWidth: constraints.maxWidth,
                              primary:
                                  (startHour != null && sp.timeIntervalEnabled)
                                      ? PrimaryHabitConfig(
                                        enabled: true,
                                        timeType: timeType,
                                        startHour: startHour,
                                        durationHours:
                                            timeType == TimeType.regular
                                                ? duration()
                                                : null,
                                        endHour:
                                            timeType != TimeType.regular
                                                ? sp.timeIntervalEnd / 60
                                                : null,
                                        iconPath: sp.iconPath,
                                        name: habitName,
                                        containerColor: (sp.getHabitColor(tp) !=
                                                    null
                                                ? sp.getHabitColor(tp)!
                                                : tp.primaryColor.darken(30))
                                            .withOpacity(0.7),
                                        lineColor:
                                            sp.getHabitTextColor(tp) ??
                                            tp.primaryColor.lighten(30),
                                      )
                                      : null,
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
