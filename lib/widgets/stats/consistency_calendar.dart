import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/habit_stats_provider.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

class ConsistencyCalendar extends StatefulWidget {
  const ConsistencyCalendar({
    super.key,
    this.habitStats,
    this.allStats,
    this.today,
    this.isDemo = false,
  });

  final HabitStatsData? habitStats;
  final Map<DateTime, double>? allStats;
  final DateTime? today;
  final bool isDemo;

  @override
  State<ConsistencyCalendar> createState() => _ConsistencyCalendarState();
}

class _ConsistencyCalendarState extends State<ConsistencyCalendar> {
  static final List<Color> _progressScaleDark = [
    const Color(0xFF11F29B).withValues(alpha: 0.06),
    const Color(0xFF11F29B).withValues(alpha: 0.12),
    const Color(0xFF11F29B).withValues(alpha: 0.18),
    const Color(0xFF11F29B).withValues(alpha: 0.24),
    const Color(0xFF11F29B).withValues(alpha: 0.32),
    const Color(0xFF02D382), // 100% only
  ];

  static final List<Color> _progressScaleLight = [
    const Color(0xFF0CD280).withValues(alpha: 0.08),
    const Color(0xFF0CD280).withValues(alpha: 0.16),
    const Color(0xFF0CD280).withValues(alpha: 0.24),
    const Color(0xFF0CD280).withValues(alpha: 0.32),
    const Color(0xFF0CD280).withValues(alpha: 0.42),
    const Color(0xFF02D382), // 100% only
  ];

  late DateTime _focusedDay;

  @override
  void initState() {
    super.initState();
    final now = widget.today ?? DateTime.now();
    _focusedDay = DateTime(now.year, now.month, 1);
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

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final today = _normalize(widget.today ?? DateTime.now());

    DateTime getCreatedAt() {
      if (widget.habitStats != null) {
        return widget.habitStats!.createdAt.toLocal();
      } else if (widget.allStats != null && widget.allStats!.isNotEmpty) {
        return widget.allStats!.keys.reduce((a, b) => a.isBefore(b) ? a : b);
      } else {
        return today;
      }
    }

    final createdAtRaw = _normalize(getCreatedAt());
    final selectableFirstDay =
        createdAtRaw.isAfter(today) ? today : createdAtRaw;
    final calendarFirstDay = _monthStart(selectableFirstDay);
    final focusedDay = _clampFocusedDay(_focusedDay, calendarFirstDay, today);

    final dots = cp.isDark ? _progressScaleDark : _progressScaleLight;

    final loc = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!widget.isDemo) ...[
          Text(
            loc.consistency,
            style: TextStyle(
              color: cp.text,
              fontSize: 22,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            loc.yourActivityOverTime,
            style: TextStyle(color: cp.lightGreyText, fontSize: 16),
          ),
          const SizedBox(height: 20),
        ],

        _calendarHeader(cp, calendarFirstDay, today, focusedDay),
        const SizedBox(height: 16),
        TableCalendar<void>(
          locale: Localizations.localeOf(context).toString(),
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
                (context, day, _) => _dayCell(
                  context: context,
                  day: day,
                  createdAt: selectableFirstDay,
                  today: today,
                  isOutside: _isOutsideMonth(day, focusedDay),
                  isToday: false,
                ),
            todayBuilder:
                (context, day, _) => _dayCell(
                  context: context,
                  day: day,
                  createdAt: selectableFirstDay,
                  today: today,
                  isOutside: _isOutsideMonth(day, focusedDay),
                  isToday: true,
                ),
            outsideBuilder:
                (context, day, _) => _dayCell(
                  context: context,
                  day: day,
                  createdAt: selectableFirstDay,
                  today: today,
                  isOutside: true,
                  isToday: false,
                  forceDisabled: true,
                ),
            disabledBuilder:
                (context, day, _) => _dayCell(
                  context: context,
                  day: day,
                  createdAt: selectableFirstDay,
                  today: today,
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
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              loc.less,
              style: TextStyle(color: cp.lightGreyText, fontSize: 16),
            ),
            const SizedBox(width: 14),
            for (final color in dots) ...[
              Container(
                width: 10,
                height: 10,
                decoration: ShapeDecoration(
                  color: color,
                  shape: const OvalBorder(),
                ),
              ),
              const SizedBox(width: 8),
            ],
            const SizedBox(width: 6),
            Text(
              loc.more,
              style: TextStyle(color: cp.lightGreyText, fontSize: 16),
            ),
          ],
        ),
      ],
    );
  }

  Widget _calendarHeader(
    ColorProvider cp,
    DateTime firstDay,
    DateTime today,
    DateTime focusedDay,
  ) {
    final locale = Localizations.localeOf(context);
    final monthLabel = DateFormat(
      'MMMM yyyy',
      locale.toString(),
    ).format(focusedDay);

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
          side: BorderSide(
            width: 1,
            color: widget.isDemo ? Colors.transparent : cp.border,
          ),
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
                "${monthLabel[0].toUpperCase()}${monthLabel.substring(1).toLowerCase()}",
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
    bool forceDisabled = false,
  }) {
    final cp = context.watch<ColorProvider>();
    final normalizedDay = _normalize(day);
    final enabled =
        !forceDisabled && _isEnabledDay(normalizedDay, createdAt, today);
    final outsideOrDisabled = isOutside || !enabled;

    Map<DateTime, double> statsMap() {
      if (widget.habitStats != null) {
        return widget.habitStats!.dailyProgress;
      } else if (widget.allStats != null) {
        return widget.allStats!;
      } else {
        return {};
      }
    }

    final progress = statsMap()[normalizedDay] ?? 0;
    final Color fillColor;
    final Color textColor;

    Color outsideDisabledFill = cp.habitBg;
    Color outsideDisabledText = cp.lightGreyText;

    if (outsideOrDisabled) {
      fillColor = outsideDisabledFill;
      textColor = outsideDisabledText;
    } else {
      fillColor =
          _colorForProgress(
            progress,
            cp.isDark ? _progressScaleDark : _progressScaleLight,
          ) ??
          cp.habitBg;
      textColor = cp.text;
    }

    return Center(
      child: Container(
        width: 38,
        height: 38,
        decoration: ShapeDecoration(
          color: fillColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
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
    );
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

  Color? _colorForProgress(double progress, List<Color> progressScale) {
    if (progress <= 0) return null;
    // Only fully completed days get the brightest color.
    if (progress >= 1.0) return progressScale.last;
    // Partial progress maps across all buckets except the last.
    final partialBuckets = progressScale.length - 1;
    final index = (progress * partialBuckets).floor().clamp(0, partialBuckets - 1);
    return progressScale[index];
  }

  static DateTime _normalize(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}
