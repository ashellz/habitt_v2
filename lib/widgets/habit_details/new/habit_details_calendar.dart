import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/habit_stats_provider.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

class HabitDetailsCalendar extends StatefulWidget {
  const HabitDetailsCalendar({super.key, required this.stats});

  final HabitStatsData stats;

  @override
  State<HabitDetailsCalendar> createState() => _HabitDetailsCalendarState();
}

class _HabitDetailsCalendarState extends State<HabitDetailsCalendar> {
  static const List<Color> _progressScale = [
    Color(0x1A11F29B),
    Color(0x330CD280),
    Color(0x6611F29B),
    Color(0x9911F29B),
    Color(0xCC11F29B),
    Color(0xFF11F29B),
  ];

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
    final createdAtRaw = _normalize(widget.stats.createdAt.toLocal());
    final selectableFirstDay =
        createdAtRaw.isAfter(today) ? today : createdAtRaw;
    final calendarFirstDay = _monthStart(selectableFirstDay);
    final focusedDay = _clampFocusedDay(_focusedDay, calendarFirstDay, today);

    final dots = _progressScale;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Consistency',
          style: TextStyle(
            color: cp.text,
            fontSize: 22,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Your activity over time',
          style: TextStyle(color: cp.lightGreyText, fontSize: 16),
        ),
        const SizedBox(height: 14),
        _calendarHeader(cp, calendarFirstDay, today, focusedDay),
        const SizedBox(height: 14),
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
                  isOutside: day.month != focusedDay.month,
                  isToday: false,
                ),
            todayBuilder:
                (context, day, _) => _dayCell(
                  context: context,
                  day: day,
                  createdAt: selectableFirstDay,
                  today: today,
                  isOutside: day.month != focusedDay.month,
                  isToday: true,
                ),
            disabledBuilder:
                (context, day, _) => _dayCell(
                  context: context,
                  day: day,
                  createdAt: selectableFirstDay,
                  today: today,
                  isOutside: day.month != focusedDay.month,
                  isToday: false,
                  forceDisabled: true,
                ),
          ),
          daysOfWeekStyle: DaysOfWeekStyle(
            weekendStyle: TextStyle(
              color: cp.lightGreyText,
              fontSize: 16 / 1.3,
              fontWeight: FontWeight.w500,
            ),
            weekdayStyle: TextStyle(
              color: cp.lightGreyText,
              fontSize: 16 / 1.3,
              fontWeight: FontWeight.w500,
            ),
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
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Less',
              style: TextStyle(
                color: cp.lightGreyText,
                fontSize: 25 / 2,
                fontWeight: FontWeight.w500,
              ),
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
              'More',
              style: TextStyle(
                color: cp.lightGreyText,
                fontSize: 25 / 2,
                fontWeight: FontWeight.w500,
              ),
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
                style: TextStyle(color: cp.lightGreyText, fontSize: 16),
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

    final progress = widget.stats.dailyProgress[normalizedDay] ?? 0;
    final Color fillColor;
    final Color textColor;

    Color outsideDisabledFill = cp.bg;
    Color outsideDisabledText = cp.lightGreyText;

    if (outsideOrDisabled) {
      fillColor = outsideDisabledFill;
      textColor = outsideDisabledText;
    } else {
      fillColor = _colorForProgress(progress) ?? cp.habitBg;
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
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              '${day.day}',
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (isToday && !outsideOrDisabled)
              Container(
                width: 38,
                height: 38,
                decoration: ShapeDecoration(
                  shape: OvalBorder(
                    side: BorderSide(width: 1.5, color: cp.main),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static bool _isEnabledDay(DateTime day, DateTime createdAt, DateTime today) {
    return !day.isBefore(createdAt) && !day.isAfter(today);
  }

  Color? _colorForProgress(double progress) {
    if (progress <= 0) {
      return null;
    }

    final clamped = progress.clamp(0.0, 1.0);
    final index = ((clamped * _progressScale.length).ceil() - 1).clamp(
      0,
      _progressScale.length - 1,
    );
    return _progressScale[index];
  }

  static DateTime _normalize(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}
