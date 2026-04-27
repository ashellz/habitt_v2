import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

class StreakCalendar extends StatefulWidget {
  const StreakCalendar({super.key, required this.allStats});

  final Map<DateTime, double> allStats;

  @override
  State<StreakCalendar> createState() => _StreakCalendarState();
}

class _StreakCalendarState extends State<StreakCalendar> {
  late DateTime _focusedDay;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
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

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final today = _normalize(DateTime.now());

    DateTime getCreatedAt() {
      if (widget.allStats.isNotEmpty) {
        return widget.allStats.keys.reduce((a, b) => a.isBefore(b) ? a : b);
      } else {
        return today;
      }
    }

    final createdAtRaw = _normalize(getCreatedAt());
    final selectableFirstDay =
        createdAtRaw.isAfter(today) ? today : createdAtRaw;
    final calendarFirstDay = _monthStart(selectableFirstDay);
    final focusedDay = _clampFocusedDay(_focusedDay, calendarFirstDay, today);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _calendarHeader(cp, calendarFirstDay, today, focusedDay),
        const SizedBox(height: 16),
        TableCalendar<void>(
          key: ValueKey(
            'habit-details-calendar-${calendarFirstDay.millisecondsSinceEpoch}-${today.millisecondsSinceEpoch}',
          ),
          firstDay: calendarFirstDay,
          lastDay: today,
          focusedDay: focusedDay,
          calendarFormat: CalendarFormat.month,
          headerVisible: false,
          availableGestures: AvailableGestures.none,
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
            dowTextFormatter:
                (date, locale) => DateFormat.E(locale).format(date),
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
  }

  Widget _calendarHeader(
    ColorProvider cp,
    DateTime firstDay,
    DateTime today,
    DateTime focusedDay,
  ) {
    final monthLabel = DateFormat('MMMM yyyy').format(focusedDay);

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
    bool forceDisabled = false,
  }) {
    final cp = context.watch<ColorProvider>();
    final normalizedDay = _normalize(day);
    final enabled =
        !forceDisabled && _isEnabledDay(normalizedDay, createdAt, today);
    final outsideOrDisabled = isOutside || !enabled;

    final progress = widget.allStats[normalizedDay] ?? 0;
    final Color fillColor;
    final Color textColor;
    final Color borderColor;

    Color outsideDisabledFill = cp.bg;
    Color outsideDisabledText = cp.lightGreyText;

    if (outsideOrDisabled) {
      fillColor = outsideDisabledFill;
      textColor = outsideDisabledText;
      borderColor = outsideDisabledFill;
    } else {
      fillColor = _colorForProgress(progress, isToday) ?? cp.bg;
      borderColor =
          _colorForProgress(progress, isToday, isBorder: true) ?? cp.bg;
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

  Color? _colorForProgress(
    double progress,
    bool isToday, {
    bool isBorder = false,
  }) {
    if (progress <= 0) {
      return null;
    }

    final cp = context.watch<ColorProvider>();

    final clamped = progress.clamp(0.0, 1.0);

    if (isBorder) {
      if (clamped == 1) {
        if (isToday) {
          return cp.orange300;
        }
        return cp.orange200;
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
