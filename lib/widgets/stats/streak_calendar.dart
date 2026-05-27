import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:table_calendar/table_calendar.dart';

class StreakCalendar extends StatefulWidget {
  const StreakCalendar({
    super.key,
    required this.allStats,
    required this.perfectDayCompletion,
    this.today,
    this.isActive = true,
  });

  final Map<DateTime, double> allStats;
  final Map<DateTime, bool> perfectDayCompletion;
  final DateTime? today;
  final bool isActive;

  @override
  State<StreakCalendar> createState() => _StreakCalendarState();
}

class _StreakCalendarState extends State<StreakCalendar> {
  late DateTime _focusedDay;

  Map<int, Map<DateTime, _StreakVisualDayData>> _monthMetadataCache = {};
  List<_ToleratedMissRun> _cachedRuns = const [];
  DateTime? _cachedSelectableFirstDay;
  DateTime? _cachedToday;
  Map<DateTime, double>? _cachedAllStatsReference;
  Map<DateTime, bool>? _cachedPerfectDayCompletionReference;
  int? _activeMonthKey;
  bool _isMonthMetadataReady = false;
  bool _streakCacheReady = false;
  int _monthLoadToken = 0;
  int? _scheduledMonthKey;

  @override
  void initState() {
    super.initState();
    final now = widget.today ?? DateTime.now();
    _focusedDay = DateTime(now.year, now.month, 1);
    if (widget.isActive) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _computeAndScheduleStreakCache(),
      );
    }
  }

  @override
  void didUpdateWidget(covariant StreakCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final dataChanged =
        !identical(oldWidget.allStats, widget.allStats) ||
        !identical(oldWidget.perfectDayCompletion, widget.perfectDayCompletion);
    final becameActive = !oldWidget.isActive && widget.isActive;

    if (becameActive || (widget.isActive && dataChanged)) {
      if (dataChanged) _invalidateStreakCaches();
      _computeAndScheduleStreakCache();
    }
  }

  void _computeAndScheduleStreakCache() {
    if (!mounted) return;
    setState(() => _streakCacheReady = false);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final today = _normalize(widget.today ?? DateTime.now());
      _ensureStreakCachesUpToDate(today);

      final selectableFirstDay = _cachedSelectableFirstDay ?? today;
      final focusedDay = _clampFocusedDay(
        _focusedDay,
        _monthStart(selectableFirstDay),
        today,
      );

      _scheduleMonthMetadataLoad(
        focusedDay: focusedDay,
        selectableFirstDay: selectableFirstDay,
        today: today,
      );

      if (mounted) setState(() => _streakCacheReady = true);
    });
  }

  DateTime _monthStart(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  DateTime _clampFocusedDay(DateTime day, DateTime createdAt, DateTime today) {
    final minMonth = _monthStart(createdAt);
    final maxMonth = _monthStart(today);
    final candidate = _monthStart(day);

    if (candidate.isBefore(minMonth)) {
      return minMonth;
    }
    if (candidate.isAfter(maxMonth)) {
      return maxMonth;
    }
    return candidate;
  }

  String _capitalizeFirstLetter(String value) {
    if (value.isEmpty) {
      return value;
    }

    return value[0].toUpperCase() + value.substring(1);
  }

  void _invalidateStreakCaches() {
    _cachedRuns = const [];
    _cachedSelectableFirstDay = null;
    _cachedToday = null;
    _cachedAllStatsReference = null;
    _cachedPerfectDayCompletionReference = null;
    _monthMetadataCache = {};
    _activeMonthKey = null;
    _isMonthMetadataReady = false;
    _scheduledMonthKey = null;
    _monthLoadToken++;
  }

  DateTime _resolveSelectableFirstDay(DateTime today) {
    if (widget.allStats.isEmpty) {
      return today;
    }

    final createdAtRaw = _normalize(
      widget.allStats.keys.reduce((a, b) => a.isBefore(b) ? a : b),
    );
    return createdAtRaw.isAfter(today) ? today : createdAtRaw;
  }

  void _ensureStreakCachesUpToDate(DateTime today) {
    if (identical(_cachedAllStatsReference, widget.allStats) &&
        identical(
          _cachedPerfectDayCompletionReference,
          widget.perfectDayCompletion,
        ) &&
        _cachedToday == today &&
        _cachedSelectableFirstDay != null) {
      return;
    }

    final selectableFirstDay = _resolveSelectableFirstDay(today);
    final completedDays = <DateTime>{
      for (final entry in widget.perfectDayCompletion.entries)
        if (entry.value) _normalize(entry.key),
    };

    _cachedRuns = _buildToleratedMissRuns(
      selectableFirstDay: selectableFirstDay,
      today: today,
      completedDays: completedDays,
    );
    _cachedSelectableFirstDay = selectableFirstDay;
    _cachedToday = today;
    _cachedAllStatsReference = widget.allStats;
    _cachedPerfectDayCompletionReference = widget.perfectDayCompletion;
    _monthMetadataCache = {};
    _activeMonthKey = null;
    _isMonthMetadataReady = false;
    _scheduledMonthKey = null;
    _monthLoadToken++;
  }

  int _monthKey(DateTime day) => day.year * 100 + day.month;

  bool _isMonthInRange({
    required DateTime month,
    required DateTime selectableFirstDay,
    required DateTime today,
  }) {
    final normalizedMonth = _monthStart(month);
    final minMonth = _monthStart(selectableFirstDay);
    final maxMonth = _monthStart(today);
    return !normalizedMonth.isBefore(minMonth) &&
        !normalizedMonth.isAfter(maxMonth);
  }

  void _scheduleMonthMetadataLoad({
    required DateTime focusedDay,
    required DateTime selectableFirstDay,
    required DateTime today,
  }) {
    final month = _monthStart(focusedDay);
    final key = _monthKey(month);
    if (_scheduledMonthKey == key) {
      return;
    }

    final hasMetadata = _monthMetadataCache.containsKey(key);
    if (hasMetadata && _activeMonthKey == key && _isMonthMetadataReady) {
      return;
    }

    _scheduledMonthKey = key;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _scheduledMonthKey = null;
      _loadMonthMetadata(
        focusedDay: month,
        selectableFirstDay: selectableFirstDay,
        today: today,
      );
    });
  }

  Future<void> _loadMonthMetadata({
    required DateTime focusedDay,
    required DateTime selectableFirstDay,
    required DateTime today,
  }) async {
    final month = _monthStart(focusedDay);
    final key = _monthKey(month);

    final cached = _monthMetadataCache[key];
    if (cached != null) {
      if (!mounted) return;
      setState(() {
        _activeMonthKey = key;
        _isMonthMetadataReady = true;
      });
      return;
    }

    final token = ++_monthLoadToken;
    if (mounted) {
      setState(() {
        _activeMonthKey = key;
        _isMonthMetadataReady = false;
      });
    }

    await Future<void>.delayed(Duration.zero);

    final metadata = _buildStreakVisualMetadata(
      runs: _cachedRuns,
      selectableFirstDay: selectableFirstDay,
      today: today,
      focusedDay: month,
    );

    if (!mounted || token != _monthLoadToken) {
      return;
    }

    setState(() {
      _monthMetadataCache[key] = metadata;
      _activeMonthKey = key;
      _isMonthMetadataReady = true;
    });

    _prefetchAdjacentMonthMetadata(
      focusedDay: month,
      selectableFirstDay: selectableFirstDay,
      today: today,
    );
  }

  void _prefetchAdjacentMonthMetadata({
    required DateTime focusedDay,
    required DateTime selectableFirstDay,
    required DateTime today,
  }) {
    final candidates = [
      DateTime(focusedDay.year, focusedDay.month - 1, 1),
      DateTime(focusedDay.year, focusedDay.month + 1, 1),
    ];

    for (final candidate in candidates) {
      if (!_isMonthInRange(
        month: candidate,
        selectableFirstDay: selectableFirstDay,
        today: today,
      )) {
        continue;
      }

      final key = _monthKey(candidate);
      if (_monthMetadataCache.containsKey(key)) {
        continue;
      }

      _monthMetadataCache[key] = _buildStreakVisualMetadata(
        runs: _cachedRuns,
        selectableFirstDay: selectableFirstDay,
        today: today,
        focusedDay: candidate,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final today = _normalize(widget.today ?? DateTime.now());

    final selectableFirstDay = _cachedSelectableFirstDay ?? today;
    final calendarFirstDay = _monthStart(selectableFirstDay);
    final focusedDay = _clampFocusedDay(_focusedDay, calendarFirstDay, today);

    if (_focusedDay != focusedDay) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        setState(() {
          _focusedDay = focusedDay;
        });
      });
    }

    if (_streakCacheReady) {
      _scheduleMonthMetadataLoad(
        focusedDay: focusedDay,
        selectableFirstDay: selectableFirstDay,
        today: today,
      );
    }
    final currentMonthKey = _monthKey(focusedDay);
    final streakVisualMetadata =
        _monthMetadataCache[currentMonthKey] ??
        const <DateTime, _StreakVisualDayData>{};
    final streakDecorationsOpacity =
        (_isMonthMetadataReady && _activeMonthKey == currentMonthKey)
            ? 1.0
            : 0.0;

    Widget buildDayCell({
      required BuildContext context,
      required DateTime day,
      required bool isOutside,
      required bool isToday,
      bool forceDisabled = false,
    }) {
      final metadata =
          streakVisualMetadata[_normalize(day)] ?? const _StreakVisualDayData();
      return _dayCell(
        context: context,
        day: day,
        createdAt: selectableFirstDay,
        today: today,
        isOutside: isOutside,
        isToday: isToday,
        forceDisabled: forceDisabled,
        hasLeftConnector: metadata.hasLeftConnector,
        hasRightConnector: metadata.hasRightConnector,
        isOngoingStreakStartCompletedDay:
            metadata.isOngoingStreakStartCompletedDay,
        streakDecorationsOpacity: streakDecorationsOpacity,
      );
    }

    final calendarWidget = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _calendarHeader(cp, calendarFirstDay, today, focusedDay),
        const SizedBox(height: 16),
        TableCalendar<void>(
          locale: AppLocalizations.of(context)!.localeName,
          key: ValueKey(
            'habit-details-calendar-${calendarFirstDay.millisecondsSinceEpoch}-${today.millisecondsSinceEpoch}',
          ),
          firstDay: calendarFirstDay,
          lastDay: today,
          focusedDay: focusedDay,
          calendarFormat: CalendarFormat.month,
          headerVisible: false,
          availableGestures: AvailableGestures.horizontalSwipe,
          startingDayOfWeek: StartingDayOfWeek.monday,
          daysOfWeekHeight: 30,
          enabledDayPredicate:
              (day) => _isEnabledDay(day, selectableFirstDay, today),
          calendarBuilders: CalendarBuilders(
            defaultBuilder:
                (context, day, _) => buildDayCell(
                  context: context,
                  day: day,
                  isOutside: _isOutsideMonth(day, focusedDay),
                  isToday: _normalize(day) == today,
                ),
            todayBuilder:
                (context, day, _) => buildDayCell(
                  context: context,
                  day: day,
                  isOutside: _isOutsideMonth(day, focusedDay),
                  isToday: _normalize(day) == today,
                ),
            outsideBuilder:
                (context, day, _) => buildDayCell(
                  context: context,
                  day: day,
                  isOutside: true,
                  isToday: false,
                  forceDisabled: true,
                ),
            disabledBuilder:
                (context, day, _) => buildDayCell(
                  context: context,
                  day: day,
                  isOutside: _isOutsideMonth(day, focusedDay),
                  isToday: false,
                  forceDisabled: true,
                ),
          ),
          daysOfWeekStyle: DaysOfWeekStyle(
            weekendStyle: TextStyle(color: cp.lightGreyText, fontSize: 13),
            weekdayStyle: TextStyle(color: cp.lightGreyText, fontSize: 13),
            dowTextFormatter: (date, locale) {
              return _capitalizeFirstLetter(DateFormat.E(locale).format(date));
            },
          ),
          onPageChanged: (focusedDay) {
            setState(() {
              _focusedDay = _clampFocusedDay(
                focusedDay,
                calendarFirstDay,
                today,
              );
            });
          },
        ),
      ],
    );

    final shimmerWidget = Shimmer.fromColors(
      baseColor: cp.bg,
      highlightColor: cp.field,
      child: Container(
        height: 320,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );

    return AnimatedCrossFade(
      duration: const Duration(milliseconds: 350),
      crossFadeState:
          _streakCacheReady
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
      firstChild: shimmerWidget,
      secondChild: calendarWidget,
      sizeCurve: Curves.easeInOut,
    );
  }

  Widget _calendarHeader(
    ColorProvider cp,
    DateTime firstDay,
    DateTime today,
    DateTime focusedDay,
  ) {
    final locale = Localizations.localeOf(context);
    final monthLabel = _capitalizeFirstLetter(
      DateFormat('MMMM yyyy', locale.toString()).format(focusedDay),
    );

    final previousMonth = DateTime(focusedDay.year, focusedDay.month - 1, 1);
    final nextMonth = DateTime(focusedDay.year, focusedDay.month + 1, 1);

    final minMonth = DateTime(firstDay.year, firstDay.month, 1);
    final maxMonth = DateTime(today.year, today.month, 1);

    final canGoBack = !previousMonth.isBefore(minMonth);
    final canGoForward = !nextMonth.isAfter(maxMonth);

    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: ShapeDecoration(
        color: cp.field,
        shape: RoundedRectangleBorder(
          side: BorderSide(width: 1, color: cp.border),
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      child: Row(
        children: [
          _headerButton(
            svgPath: 'assets/images/new-svg/back.svg',
            enabled: canGoBack,
            onPressed: () {
              if (!canGoBack) {
                return;
              }
              setState(() {
                _focusedDay = _clampFocusedDay(previousMonth, firstDay, today);
              });
            },
          ),
          Expanded(
            child: Center(
              child: Text(
                monthLabel,
                style: TextStyle(
                  color: cp.isDark ? cp.lightGreyText : cp.greyText,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          _headerButton(
            rotate: true,
            svgPath: 'assets/images/new-svg/back.svg',
            enabled: canGoForward,
            onPressed: () {
              if (!canGoForward) {
                return;
              }
              setState(() {
                _focusedDay = _clampFocusedDay(nextMonth, firstDay, today);
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _headerButton({
    required String svgPath,
    required bool enabled,
    required VoidCallback onPressed,
    bool rotate = false,
  }) {
    final cp = context.watch<ColorProvider>();

    return RotatedBox(
      quarterTurns: rotate ? 2 : 0,
      child: SizedBox(
        width: 28,
        height: 28,
        child: IconButton(
          onPressed: enabled ? onPressed : null,
          iconSize: 20,
          padding: EdgeInsets.zero,
          splashRadius: 20,
          color: enabled ? cp.text : cp.lightGreyText.withValues(alpha: 0.4),
          icon: SvgPicture.asset(
            svgPath,
            colorFilter: ColorFilter.mode(
              enabled ? cp.text : cp.lightGreyText.withValues(alpha: 0.4),
              BlendMode.srcIn,
            ),
          ),
        ),
      ),
    );
  }

  Widget _dayCell({
    required BuildContext context,
    required DateTime day,
    required DateTime createdAt,
    required DateTime today,
    required bool isOutside,
    required bool isToday,
    required bool hasLeftConnector,
    required bool hasRightConnector,
    required bool isOngoingStreakStartCompletedDay,
    required double streakDecorationsOpacity,
    bool forceDisabled = false,
  }) {
    final cp = context.watch<ColorProvider>();
    const dayCircleSize = 38.0;
    final normalizedDay = _normalize(day);
    final enabled =
        !forceDisabled && _isEnabledDay(normalizedDay, createdAt, today);
    final outsideOrDisabled = isOutside || !enabled;

    final progress = widget.allStats[normalizedDay] ?? 0;
    late Color fillColor;
    late Color textColor;
    late Color borderColor;

    final outsideDisabledFill = cp.bg;
    final outsideDisabledText = cp.lightGreyText;

    if (outsideOrDisabled) {
      fillColor = outsideDisabledFill;
      textColor = outsideDisabledText;
      borderColor = outsideDisabledFill;
    } else {
      fillColor = _colorForProgress(cp, progress, isToday) ?? cp.bg;
      borderColor =
          _colorForProgress(cp, progress, isToday, isBorder: true) ?? cp.bg;
      textColor =
          isOngoingStreakStartCompletedDay
              ? Colors.white
              : _colorForProgress(cp, progress, isToday, isText: true) ??
                  cp.text;

      if (isOngoingStreakStartCompletedDay) {
        fillColor =
            Color.lerp(fillColor, cp.orange300, streakDecorationsOpacity) ??
            fillColor;
      }
    }

    final connectorColor = cp.orange100;
    final showLeftConnector =
        hasLeftConnector && normalizedDay.weekday != DateTime.monday;
    final showRightConnector =
        hasRightConnector && normalizedDay.weekday != DateTime.sunday;

    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned.fill(
          child: Align(
            alignment: Alignment.center,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              opacity: streakDecorationsOpacity,
              child: SizedBox(
                height: dayCircleSize,
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: dayCircleSize,
                        color:
                            showLeftConnector
                                ? connectorColor
                                : Colors.transparent,
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: dayCircleSize,
                        color:
                            showRightConnector
                                ? connectorColor
                                : Colors.transparent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Center(
          child: Container(
            width: dayCircleSize,
            height: dayCircleSize,
            decoration: ShapeDecoration(
              color: fillColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(100),
                side: BorderSide(width: 1, color: borderColor),
              ),
            ),
            child: Center(
              child: Text(
                '${day.day}',
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Map<DateTime, _StreakVisualDayData> _buildStreakVisualMetadata({
    required List<_ToleratedMissRun> runs,
    required DateTime selectableFirstDay,
    required DateTime today,
    required DateTime focusedDay,
  }) {
    final visibleDays = _visibleMonthGridDays(focusedDay);

    final visibleSet = visibleDays.toSet();

    final metadata = {
      for (final day in visibleDays) day: const _StreakVisualDayData(),
    };

    if (selectableFirstDay.isAfter(today) || runs.isEmpty) {
      return metadata;
    }

    for (final run in runs) {
      for (int i = 0; i < run.days.length - 1; i++) {
        final leftDay = run.days[i];
        final rightDay = run.days[i + 1];
        final segmentTouchesOutside =
            _isOutsideMonth(leftDay, focusedDay) ||
            _isOutsideMonth(rightDay, focusedDay);

        if (segmentTouchesOutside && !run.includesToday) {
          continue;
        }

        if (rightDay.isAfter(today)) {
          continue;
        }

        if (visibleSet.contains(leftDay)) {
          metadata[leftDay] = (metadata[leftDay] ??
                  const _StreakVisualDayData())
              .copyWith(hasRightConnector: true);
        }
        if (visibleSet.contains(rightDay)) {
          metadata[rightDay] = (metadata[rightDay] ??
                  const _StreakVisualDayData())
              .copyWith(hasLeftConnector: true);
        }
      }
    }

    _ToleratedMissRun? ongoingRun;
    for (final run in runs) {
      if (run.includesToday) {
        ongoingRun = run;
      }
    }

    final ongoingStart = ongoingRun?.firstCompletedDay;
    if (ongoingStart != null && visibleSet.contains(ongoingStart)) {
      metadata[ongoingStart] = (metadata[ongoingStart] ??
              const _StreakVisualDayData())
          .copyWith(isOngoingStreakStartCompletedDay: true);
    }

    return metadata;
  }

  List<DateTime> _visibleMonthGridDays(DateTime focusedDay) {
    final monthStart = DateTime(focusedDay.year, focusedDay.month, 1);
    final monthEnd = DateTime(focusedDay.year, focusedDay.month + 1, 0);

    final daysBefore = (monthStart.weekday - DateTime.monday) % 7;
    final start = monthStart.subtract(Duration(days: daysBefore));

    final daysAfter = (DateTime.sunday - monthEnd.weekday) % 7;
    final end = monthEnd.add(Duration(days: daysAfter));

    final dayCount = end.difference(start).inDays + 1;
    return List<DateTime>.generate(
      dayCount,
      (index) => _normalize(start.add(Duration(days: index))),
    );
  }

  List<_ToleratedMissRun> _buildToleratedMissRuns({
    required DateTime selectableFirstDay,
    required DateTime today,
    required Set<DateTime> completedDays,
  }) {
    final runs = <_ToleratedMissRun>[];
    final currentDays = <DateTime>[];
    final currentCompletedDays = <DateTime>[];

    var hasCompletion = false;
    var toleratedMissesUsed = 0;
    var cursor = selectableFirstDay;

    while (!cursor.isAfter(today.add(const Duration(days: 1)))) {
      final normalizedCursor = _normalize(cursor);
      final isCompleted = completedDays.contains(normalizedCursor);

      if (!hasCompletion) {
        if (isCompleted) {
          hasCompletion = true;
          toleratedMissesUsed = 0;
          currentDays.add(normalizedCursor);
          currentCompletedDays.add(normalizedCursor);
        }
        cursor = cursor.add(const Duration(days: 1));
        continue;
      }

      if (isCompleted) {
        currentDays.add(normalizedCursor);
        currentCompletedDays.add(normalizedCursor);
        toleratedMissesUsed = 0;
      } else if (toleratedMissesUsed == 0) {
        currentDays.add(normalizedCursor);
        toleratedMissesUsed = 1;
      } else {
        // If a second miss happens, the previous tolerated miss did not bridge
        // to a completion and should not be part of the rendered streak run.
        if (currentDays.isNotEmpty &&
            !completedDays.contains(currentDays.last)) {
          currentDays.removeLast();
        }

        if (currentDays.isNotEmpty && currentCompletedDays.isNotEmpty) {
          runs.add(
            _ToleratedMissRun(
              days: List<DateTime>.from(currentDays),
              completedDays: List<DateTime>.from(currentCompletedDays),
              includesToday: false,
            ),
          );
        }

        currentDays.clear();
        currentCompletedDays.clear();
        hasCompletion = false;
        toleratedMissesUsed = 0;
      }

      cursor = cursor.add(const Duration(days: 1));
    }

    if (hasCompletion &&
        currentDays.isNotEmpty &&
        currentCompletedDays.isNotEmpty) {
      runs.add(
        _ToleratedMissRun(
          days: List<DateTime>.from(currentDays),
          completedDays: List<DateTime>.from(currentCompletedDays),
          includesToday: currentDays.last == today,
        ),
      );
    }

    return runs;
  }

  static bool _isEnabledDay(DateTime day, DateTime createdAt, DateTime today) {
    final normalizedDay = _normalize(day);
    final normalizedCreatedAt = _normalize(createdAt);
    final normalizedToday = _normalize(today);

    return !normalizedDay.isBefore(normalizedCreatedAt) &&
        !normalizedDay.isAfter(normalizedToday);
  }

  static bool _isOutsideMonth(DateTime day, DateTime focusedDay) {
    return day.year != focusedDay.year || day.month != focusedDay.month;
  }

  Color? _colorForProgress(
    ColorProvider cp,
    double progress,
    bool isToday, {
    bool isBorder = false,
    bool isText = false,
  }) {
    if (progress <= 0) {
      return null;
    }
    final clamped = progress.clamp(0.0, 1.0);

    if (isText) {
      if (clamped == 1 && isToday) {
        return Colors.white;
      }
      return cp.text;
    }

    if (isBorder) {
      if (clamped == 1) {
        if (isToday) {
          return cp.orange300;
        }
        return cp.orange200;
      } else if (clamped != 0) {
        return cp.disabled;
      }
      return cp.bg;
    }

    if (clamped == 1 && isToday) {
      return cp.orange300;
    }
    return cp.bg;
  }

  static DateTime _normalize(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}

class _StreakVisualDayData {
  const _StreakVisualDayData({
    this.hasLeftConnector = false,
    this.hasRightConnector = false,
    this.isOngoingStreakStartCompletedDay = false,
  });

  final bool hasLeftConnector;
  final bool hasRightConnector;
  final bool isOngoingStreakStartCompletedDay;

  _StreakVisualDayData copyWith({
    bool? hasLeftConnector,
    bool? hasRightConnector,
    bool? isOngoingStreakStartCompletedDay,
  }) {
    return _StreakVisualDayData(
      hasLeftConnector: hasLeftConnector ?? this.hasLeftConnector,
      hasRightConnector: hasRightConnector ?? this.hasRightConnector,
      isOngoingStreakStartCompletedDay:
          isOngoingStreakStartCompletedDay ??
          this.isOngoingStreakStartCompletedDay,
    );
  }
}

class _ToleratedMissRun {
  const _ToleratedMissRun({
    required this.days,
    required this.completedDays,
    required this.includesToday,
  });

  final List<DateTime> days;
  final List<DateTime> completedDays;
  final bool includesToday;

  DateTime? get firstCompletedDay {
    if (completedDays.isEmpty) {
      return null;
    }
    return completedDays.first;
  }
}
