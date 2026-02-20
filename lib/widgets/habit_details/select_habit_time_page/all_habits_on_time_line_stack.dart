import 'package:flutter/material.dart' hide Interval;
import 'package:flutter/rendering.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/models/timeline/primary_habit_config.dart';
import 'package:habitt/models/timeline/interval.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/providers/theme_provider.dart';
import 'package:habitt/widgets/habit_details/select_habit_time_page/select_habit_time_body.dart';
import 'package:habitt/widgets/habit_widget/habit_name.dart';
import 'package:provider/provider.dart';

class AllHabitsOnTimelineStack extends StatelessWidget {
  const AllHabitsOnTimelineStack({
    super.key,
    required this.hourHeight,
    this.ignoreId,
    this.primary,
    this.dimOthers = false,
    this.showOthers = true,
    this.maxWidth,
    this.markCompleted = false,
  });

  final double hourHeight;
  final int? ignoreId;
  final PrimaryHabitConfig? primary;
  final bool dimOthers;
  final double? maxWidth;
  final bool showOthers;
  final bool markCompleted;

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
    Interval? primaryInterval;
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
      primaryInterval = Interval.primary(
        primary: primary!,
        startY: startY,
        endY: endY,
        height: height,
      );
      intervals.add(primaryInterval);
    }

    intervals.sort((a, b) => a.startY.compareTo(b.startY));

    // Group overlapping intervals into clusters with column packing
    // Each cluster contains columns, each column is a list of intervals
    final List<List<List<Interval>>> clusterColumns = [];

    for (final iv in intervals) {
      final startY = iv.startY;

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

    final bool showOnlyPrimary = primaryInterval != null && !showOthers;
    final double screenWidth = maxWidth ?? MediaQuery.of(context).size.width;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child:
          showOnlyPrimary
              ? SizedBox(
                key: const ValueKey('primary-only'),
                width: screenWidth,
                child: Stack(
                  children: [
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.fastOutSlowIn,
                      top: primaryInterval.startY,
                      left: 0,
                      right: 0,
                      height: primaryInterval.height,
                      child: _clusterChild(
                        primaryInterval,
                        tp,
                        dimOthers,
                        showOthers,
                      ),
                    ),
                    if (primary != null &&
                        primary!.enabled &&
                        primary!.timeType == TimeType.overday)
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.fastOutSlowIn,
                        top: hourHeight / 2,
                        left: 0,
                        right: 0,
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
              )
              : _FullTimelineView(
                key: const ValueKey('full-timeline'),
                clusters: clusters,
                habits: habits,
                hourHeight: hourHeight,
                tp: tp,
                dimOthers: dimOthers,
                showOthers: showOthers,
                screenWidth: screenWidth,
                maxWidth: maxWidth,
                primary: primary,
              ),
    );
  }
}

class _FullTimelineView extends StatelessWidget {
  const _FullTimelineView({
    super.key,
    required this.clusters,
    required this.habits,
    required this.hourHeight,
    required this.tp,
    required this.dimOthers,
    required this.showOthers,
    required this.screenWidth,
    required this.maxWidth,
    required this.primary,
  });

  final List<List<Interval>> clusters;
  final List<dynamic> habits;
  final double hourHeight;
  final ThemeProvider tp;
  final bool dimOthers;
  final bool showOthers;
  final double screenWidth;
  final double? maxWidth;
  final PrimaryHabitConfig? primary;

  @override
  Widget build(BuildContext context) {
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

    final extraWidth =
        maxClusterColumns > 2
            ? (maxClusterColumns - 2) * (screenWidth * 0.5)
            : 0.0;
    final contentWidth = screenWidth + extraWidth;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
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
                      if (colIndex > 0) {
                        rowChildren.add(const SizedBox(width: 4));
                      }

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

            // Cluster overday midnight segments into dedicated columns
            if (habits.any((h) => h.getTimeType() == TimeType.overday) ||
                (primary != null &&
                    primary!.enabled &&
                    primary!.timeType == TimeType.overday &&
                    showOthers))
              Builder(
                builder: (context) {
                  final overdayHabits =
                      habits
                          .where((h) => h.getTimeType() == TimeType.overday)
                          .toList();

                  final bool includePrimaryOverday =
                      primary != null &&
                      primary!.enabled &&
                      primary!.timeType == TimeType.overday &&
                      showOthers;

                  final List<_OverdayColumnItem> columnItems = [
                    ...overdayHabits.map(
                      (h) => _OverdayColumnItem(
                        startTime: TimeOfDay(
                          hour: h.timeIntervalStart ~/ 60,
                          minute: h.timeIntervalStart % 60,
                        ),
                        height: h.timeIntervalEnd / 60 * hourHeight,
                        containerColor: h.getContainerColor(tp),
                        lineColor: h.getNameColor(tp),
                        completed: h.completed,
                      ),
                    ),
                    if (includePrimaryOverday)
                      _OverdayColumnItem(
                        startTime: TimeOfDay(
                          hour: primary!.startHour.toInt(),
                          minute: 0,
                        ),
                        height: (primary!.endHour ?? 0) * hourHeight,
                        containerColor: primary!.containerColor,
                        lineColor: primary!.lineColor,
                        completed: false,
                      ),
                  ];

                  // Sort by start time
                  columnItems.sort((a, b) {
                    final aMinutes = a.startTime.hour * 60 + a.startTime.minute;
                    final bMinutes = b.startTime.hour * 60 + b.startTime.minute;
                    return aMinutes.compareTo(bMinutes);
                  });

                  if (columnItems.isEmpty) return const SizedBox.shrink();

                  final double maxOverdayHeight = columnItems
                      .map((c) => c.height)
                      .reduce((a, b) => a > b ? a : b);

                  final List<Widget> columns = [];
                  for (int i = 0; i < columnItems.length; i++) {
                    if (i > 0) columns.add(const SizedBox(width: 4));
                    final item = columnItems[i];
                    columns.add(
                      Expanded(
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: SizedBox(
                            height: item.height,
                            child: Opacity(
                              opacity: dimOthers || item.completed ? 0.5 : 1.0,
                              child: Container(
                                padding: EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: item.containerColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    width: 4,
                                    height: double.infinity,
                                    decoration: BoxDecoration(
                                      color: item.lineColor,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  return AnimatedPositioned(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.fastOutSlowIn,
                    top: hourHeight / 2,
                    left: 0,
                    right: 36,
                    height: maxOverdayHeight,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: columns,
                    ),
                  );
                },
              ),

            // Primary overday overlay segment
            if (primary != null &&
                primary!.enabled &&
                primary!.timeType == TimeType.overday &&
                !showOthers)
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

class _OverdayColumnItem {
  const _OverdayColumnItem({
    required this.height,
    required this.containerColor,
    required this.lineColor,
    required this.startTime,
    required this.completed,
  });

  final double height;
  final Color containerColor;
  final Color lineColor;
  final TimeOfDay startTime;
  final bool completed;
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

  final widget = _HabitTile(habit: iv.habit!, tp: tp);
  final double targetOpacity =
      !showOthers
          ? 0
          : dimOthers || (iv.habit?.completed ?? false)
          ? 0.5
          : 1.0;

  return AnimatedOpacity(
    opacity: targetOpacity,
    duration: const Duration(milliseconds: 150),
    child: widget,
  );
}

class _HabitTile extends StatelessWidget {
  const _HabitTile({required this.habit, required this.tp});

  final Habit habit; // Using dynamic to avoid explicit imports here
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
          LayoutBuilder(
            builder: (context, constraints) {
              return AnimatedSwitcher(
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
                  key: ValueKey<bool>(
                    habit.shouldShowName(habit.getTimeType()),
                  ),
                  child:
                      habit.shouldShowName(habit.getTimeType())
                          ? Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                habit.iconPath,
                                style: const TextStyle(fontSize: 20),
                              ),
                              const SizedBox(width: 4),
                              // Always cap width; fall back to a safe width when unbounded to avoid infinite constraints.
                              ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth:
                                      constraints.hasBoundedWidth
                                          ? (constraints.maxWidth - 32).clamp(
                                            0,
                                            double.infinity,
                                          )
                                          : 220,
                                ),
                                child: HabitNameDisplay(
                                  text: habit.name,
                                  completed: habit.completed,
                                  textColor: habit.getNameColor(tp),
                                  skipped: habit.skipped,
                                ),
                              ),
                            ],
                          )
                          : Container(),
                ),
              );
            },
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
                Text(config.iconPath, style: const TextStyle(fontSize: 20)),
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
