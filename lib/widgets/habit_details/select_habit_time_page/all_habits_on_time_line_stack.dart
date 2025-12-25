import 'package:flutter/material.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/providers/theme_provider.dart';
import 'package:habitt/widgets/habit_details/select_habit_time_page/select_habit_time_body.dart';
import 'package:provider/provider.dart';

class PrimaryHabitConfig {
  const PrimaryHabitConfig({
    required this.enabled,
    required this.timeType,
    required this.startHour,
    this.durationHours,
    this.endHour,
    required this.iconPath,
    required this.name,
    required this.containerColor,
    required this.lineColor,
  });

  final bool enabled;
  final TimeType timeType;
  final double startHour; // in hours
  final double? durationHours; // used for regular type
  final double? endHour; // used for overday/midnight extra segment
  final String iconPath;
  final String name;
  final Color containerColor;
  final Color lineColor;
}

class AllHabitsOnTimelineStack extends StatelessWidget {
  const AllHabitsOnTimelineStack({
    super.key,
    required this.hourHeight,
    this.ignoreId,
    this.primary,
    this.dimOthers = false,
  });

  final double hourHeight;
  final int? ignoreId;
  final PrimaryHabitConfig? primary;
  final bool dimOthers;

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    final habitsRaw = context.watch<HabitProvider>().habits;
    // remove the habits that are not enabled for time intervals and are not the one to ignore
    final habits =
        habitsRaw
            .where(
              (habit) =>
                  habit.timeIntervalEnabled &&
                  (ignoreId == null || habit.id != ignoreId),
            )
            .toList();

    // Build intervals for overlap detection
    final intervals =
        habits.map((habit) {
          final startY = habit.getStartHour() * hourHeight + hourHeight / 2;
          final height =
              habit.getTimeType() != TimeType.regular
                  ? (24 * hourHeight) - (habit.getStartHour() * hourHeight)
                  : habit.getTimeDuration() * hourHeight;
          final endY = startY + height;
          return {
            'kind': 'habit',
            'habit': habit,
            'startY': startY,
            'endY': endY,
            'height': height,
          };
        }).toList();

    // Include primary habit in intervals for clustering
    if (primary != null && primary!.enabled) {
      final double startY = primary!.startHour * hourHeight + hourHeight / 2;
      final double height =
          primary!.timeType != TimeType.regular
              ? (24 * hourHeight) - (primary!.startHour * hourHeight)
              : (primary!.durationHours ?? 0) * hourHeight;
      final double endY = startY + height;
      intervals.add({
        'kind': 'primary',
        'startY': startY,
        'endY': endY,
        'height': height,
        'primary': primary!,
      });
    }

    intervals.sort(
      (a, b) => (a['startY'] as double).compareTo(b['startY'] as double),
    );

    // Group overlapping intervals into clusters
    final List<List<Map<String, dynamic>>> clusters = [];

    /// [
    ///   [
    ///     {
    ///        "interval1": value,
    ///        "interval1": value2
    ///     },
    ///     {"interval2": value},
    ///   ],
    ///   [
    ///     {"interval1": value},
    ///     {"interval2": value},
    ///   ],
    /// ]
    ///

    double? currentClusterEnd;
    for (final iv in intervals) {
      final startY = iv['startY'] as double;
      final endY = iv['endY'] as double;

      // Checking every interval against the current cluster end to see if it overlaps
      // If startY (current habit start time) is over currentClusterEnd (last habit end time)
      // then a new cluster needs to be created
      // otherwise, it belongs to the current cluster because the end time of last habit is in the way
      // of the current habit start time
      if (clusters.isEmpty ||
          (currentClusterEnd != null && startY >= currentClusterEnd)) {
        // New cluster gets created for non-overlapping interval
        clusters.add([iv]);
        currentClusterEnd = endY;
      } else {
        // Overlapping interval goes into the last cluster
        clusters.last.add(iv);
        if (endY > currentClusterEnd!) currentClusterEnd = endY;
      }
    }

    // Determine dynamic width for horizontal scrolling when many columns
    final maxClusterSize =
        clusters.isEmpty
            ? 0
            : clusters.map((c) => c.length).reduce((a, b) => a > b ? a : b);
    final screenWidth = MediaQuery.of(context).size.width;
    final extraWidth =
        maxClusterSize > 2 ? (maxClusterSize - 2) * (screenWidth * 0.5) : 0.0;
    final contentWidth = screenWidth + extraWidth;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: contentWidth,
        child: Stack(
          children: [
            // Render clusters: overlapping habits side-by-side with 4px spacing
            for (final cluster in clusters)
              if (cluster.length == 1)
                // Non-overlapping: render as before
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.fastOutSlowIn,
                  top: cluster[0]['startY'] as double,
                  left: 60,
                  right: 20,
                  height: cluster[0]['height'] as double,
                  child: _clusterChild(cluster[0], tp, dimOthers),
                )
              else
                // Overlapping: render row container with equal-width columns
                Builder(
                  builder: (context) {
                    // Calculating group height
                    final groupTop = (cluster
                        .map((e) => e['startY'] as double)
                        .reduce((a, b) => a < b ? a : b));
                    final groupEnd = (cluster
                        .map((e) => e['endY'] as double)
                        .reduce((a, b) => a > b ? a : b));
                    final groupHeight = groupEnd - groupTop;

                    // Build children with 4px spacing
                    final List<Widget> rowChildren = [];
                    for (int i = 0; i < cluster.length; i++) {
                      final iv = cluster[i];
                      final startY = iv['startY'] as double;
                      final height = iv['height'] as double;
                      final relativeTop = startY - groupTop;

                      if (i > 0) rowChildren.add(const SizedBox(width: 4));

                      rowChildren.add(
                        Expanded(
                          child: Stack(
                            children: [
                              AnimatedPositioned(
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.fastOutSlowIn,
                                top: relativeTop,
                                left: 0,
                                right: 0,
                                height: height,
                                child: _clusterChild(iv, tp, dimOthers),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return AnimatedPositioned(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.fastOutSlowIn,
                      top: groupTop,
                      left: 60,
                      right: 20,
                      height: groupHeight,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: rowChildren,
                      ),
                    );
                  },
                ),

            for (var habit in habits)
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

            // Primary overday overlay segment
            if (primary != null &&
                primary!.enabled &&
                primary!.timeType == TimeType.overday)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 500),
                curve: Curves.fastOutSlowIn,
                top: hourHeight / 2,
                left: 60,
                right: 20,
                height: (primary!.endHour ?? 0) * hourHeight,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: primary!.containerColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: 4,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        color: primary!.lineColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

Widget _clusterChild(
  Map<String, dynamic> iv,
  ThemeProvider tp,
  bool dimOthers,
) {
  if (iv['kind'] == 'primary') {
    final PrimaryHabitConfig cfg = iv['primary'] as PrimaryHabitConfig;
    return _PrimaryHabitTile(config: cfg);
  }
  final widget = _HabitTile(habit: iv['habit'], tp: tp);
  return dimOthers ? Opacity(opacity: 0.5, child: widget) : widget;
}

class _HabitTile extends StatelessWidget {
  const _HabitTile({required this.habit, required this.tp});

  final dynamic habit; // Using dynamic to avoid explicit imports here
  final ThemeProvider tp;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
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
          const SizedBox(width: 5),
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
                child: FadeTransition(opacity: animation, child: child),
              );
            },
            child: KeyedSubtree(
              key: ValueKey<bool>(habit.shouldShowName(habit.getTimeType())),
              child:
                  habit.shouldShowName(habit.getTimeType())
                      ? Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Image.asset(habit.iconPath, width: 24, height: 24),
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
    );
  }
}

class _PrimaryHabitTile extends StatelessWidget {
  const _PrimaryHabitTile({required this.config});

  final PrimaryHabitConfig config;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: config.containerColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: double.infinity,
            decoration: BoxDecoration(
              color: config.lineColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 5),
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
                child: FadeTransition(opacity: animation, child: child),
              );
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(config.iconPath, width: 24, height: 24),
                Text(
                  config.name,
                  style: TextStyle(
                    color: config.lineColor,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
