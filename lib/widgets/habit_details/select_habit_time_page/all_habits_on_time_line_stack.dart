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

class Interval {
  Interval.habit({
    required this.habit,
    required this.startY,
    required this.endY,
    required this.height,
  }) : kind = 'habit',
       primary = null;

  Interval.primary({
    required this.primary,
    required this.startY,
    required this.endY,
    required this.height,
  }) : kind = 'primary',
       habit = null;

  final String kind;
  final dynamic habit;
  final PrimaryHabitConfig? primary;
  final double startY;
  final double endY;
  final double height;
  int? columnIndex;
}

class AllHabitsOnTimelineStack extends StatelessWidget {
  const AllHabitsOnTimelineStack({
    super.key,
    required this.hourHeight,
    this.ignoreId,
    this.primary,
    this.dimOthers = false,
    this.showOthers = true,
    this.maxWidth,
  });

  final double hourHeight;
  final int? ignoreId;
  final PrimaryHabitConfig? primary;
  final bool dimOthers;
  final double? maxWidth;
  final bool showOthers;

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
    final List<Interval> intervals =
        habits.map((habit) {
          final startY = habit.getStartHour() * hourHeight + hourHeight / 2;
          final height =
              habit.getTimeType() != TimeType.regular
                  ? (24 * hourHeight) - (habit.getStartHour() * hourHeight)
                  : habit.getTimeDuration() * hourHeight;
          final endY = startY + height;
          return Interval.habit(
            habit: habit,
            startY: startY,
            endY: endY,
            height: height,
          );
        }).toList();

    // Include primary habit in intervals for clustering
    if (primary != null && primary!.enabled) {
      final double startY = primary!.startHour * hourHeight + hourHeight / 2;
      final double height =
          primary!.timeType != TimeType.regular
              ? (24 * hourHeight) - (primary!.startHour * hourHeight)
              : (primary!.durationHours ?? 0) * hourHeight;
      final double endY = startY + height;
      intervals.add(
        Interval.primary(
          primary: primary!,
          startY: startY,
          endY: endY,
          height: height,
        ),
      );
    }

    intervals.sort((a, b) => a.startY.compareTo(b.startY));

    // Group overlapping intervals into clusters with column packing
    // Each cluster contains columns, each column is a list of intervals
    final List<List<List<Interval>>> clusterColumns = [];

    for (final iv in intervals) {
      final startY = iv.startY;
      final endY = iv.endY;

      if (clusterColumns.isEmpty) {
        // First interval, create first cluster with one column
        clusterColumns.add([
          [iv],
        ]);
        continue;
      }

      final currentCluster = clusterColumns.last;

      // Try to fit this interval into an existing column in the current cluster
      int? targetColumn;
      for (int colIndex = 0; colIndex < currentCluster.length; colIndex++) {
        final column = currentCluster[colIndex];
        final columnEnd = column.last.endY;
        if (startY >= columnEnd) {
          targetColumn = colIndex;
          break; // Found a column where it fits
        }
      }

      if (targetColumn != null) {
        // Add to existing column
        currentCluster[targetColumn].add(iv);
      } else {
        // Doesn't fit in any existing column
        // Check if we should add a new column or start a new cluster

        // Find the maximum end time across all intervals in current cluster
        double maxEnd = 0;
        for (final col in currentCluster) {
          for (final interval in col) {
            final end = interval.endY;
            if (end > maxEnd) maxEnd = end;
          }
        }

        if (startY >= maxEnd) {
          // No overlap with current cluster, start new cluster
          clusterColumns.add([
            [iv],
          ]);
        } else {
          // Overlaps with current cluster, add new column
          currentCluster.add([iv]);
        }
      }
    }

    // Convert to cluster format with column tracking
    final List<List<Interval>> clusters = [];
    for (final clusterCols in clusterColumns) {
      final List<Interval> clusterData = [];
      for (int colIndex = 0; colIndex < clusterCols.length; colIndex++) {
        for (final iv in clusterCols[colIndex]) {
          iv.columnIndex = colIndex;
          clusterData.add(iv);
        }
      }
      clusters.add(clusterData);
    }

    // Determine dynamic width for horizontal scrolling when many columns
    final maxClusterColumns =
        clusters.isEmpty
            ? 0
            : clusters
                .map((cluster) {
                  final cols = cluster.map((iv) => iv.columnIndex ?? 0).toSet();
                  return cols.length;
                })
                .reduce((a, b) => a > b ? a : b);
    final screenWidth = maxWidth ?? MediaQuery.of(context).size.width;
    final extraWidth =
        maxClusterColumns > 2
            ? (maxClusterColumns - 2) * (screenWidth * 0.5)
            : 0.0;
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
                // Single interval: render as before
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.fastOutSlowIn,
                  top: cluster[0].startY,
                  left: 0,
                  right: 16,
                  height: cluster[0].height,
                  child: _clusterChild(cluster[0], tp, dimOthers, showOthers),
                )
              else
                // Multiple intervals: render by columns
                Builder(
                  builder: (context) {
                    // Group intervals by column
                    final Map<int, List<Interval>> columnMap = {};
                    for (final iv in cluster) {
                      final colIndex = iv.columnIndex ?? 0;
                      columnMap.putIfAbsent(colIndex, () => []);
                      columnMap[colIndex]!.add(iv);
                    }

                    // Calculate overall cluster bounds
                    final groupTop = cluster
                        .map((e) => e.startY)
                        .reduce((a, b) => a < b ? a : b);
                    final groupEnd = cluster
                        .map((e) => e.endY)
                        .reduce((a, b) => a > b ? a : b);
                    final groupHeight = groupEnd - groupTop;

                    // Build row with columns
                    final numColumns =
                        columnMap.keys.reduce((a, b) => a > b ? a : b) + 1;
                    final List<Widget> rowChildren = [];

                    for (int colIndex = 0; colIndex < numColumns; colIndex++) {
                      if (colIndex > 0)
                        rowChildren.add(const SizedBox(width: 4));

                      final columnIntervals = columnMap[colIndex] ?? [];

                      rowChildren.add(
                        Expanded(
                          child: Stack(
                            children: [
                              for (final iv in columnIntervals)
                                AnimatedPositioned(
                                  duration: const Duration(milliseconds: 500),
                                  curve: Curves.fastOutSlowIn,
                                  top: iv.startY - groupTop,
                                  left: 0,
                                  right: 0,
                                  height: iv.height,
                                  child: _clusterChild(
                                    iv,
                                    tp,
                                    dimOthers,
                                    showOthers,
                                  ),
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
                      left: 0,
                      right: 16,
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
                  left: 0,
                  right: 36,
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
                left: 0,
                right: 36,
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
  Interval iv,
  ThemeProvider tp,
  bool dimOthers,
  bool showOthers,
) {
  if (iv.kind == 'primary') {
    debugPrint('Rendering PRIMARY habit tile');
    final PrimaryHabitConfig cfg = iv.primary as PrimaryHabitConfig;
    return _PrimaryHabitTile(config: cfg);
  }

  final widget = _HabitTile(habit: iv.habit, tp: tp);
  final double targetOpacity =
      !showOthers
          ? 0
          : dimOthers
          ? 0.5
          : 1.0;

  return AnimatedOpacity(
    opacity: targetOpacity,
    duration: const Duration(milliseconds: 250),
    child: widget,
  );
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
