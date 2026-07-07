import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/widgets/main_page/last_week_progress.dart'
    show PartialArcPainter;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

class MonthProgressCalendar extends StatefulWidget {
  const MonthProgressCalendar({
    super.key,
    required this.onDaySelected,
    this.onMonthChanged,
  });

  final void Function(DateTime day) onDaySelected;

  // used only to recalculate amount of weeks so it displays proeper height of the sheet on main page
  final void Function(DateTime month)? onMonthChanged;

  static const double rowHeight = 58;
  static const double headerHeight = 46;
  static const double daysOfWeekHeight = 30;

  static int weeksInMonth(DateTime month) {
    final firstOfMonth = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leadingOffset = (firstOfMonth.weekday - DateTime.monday) % 7;
    return ((leadingOffset + daysInMonth) / 7).ceil();
  }

  @override
  State<MonthProgressCalendar> createState() => _MonthProgressCalendarState();
}

class _MonthProgressCalendarState extends State<MonthProgressCalendar> {
  static const double _rowHeight = MonthProgressCalendar.rowHeight;

  late DateTime _focusedMonth;

  @override
  void initState() {
    super.initState();
    final habitProvider = context.read<HabitProvider>();
    final anchor = habitProvider.selectedDate ?? DateTime.now();
    _focusedMonth = _monthStart(anchor);
    _primeMonth(_focusedMonth);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onMonthChanged?.call(_focusedMonth);
    });
  }

  void _setFocusedMonth(DateTime month) {
    setState(() {
      _focusedMonth = month;
    });
    _primeMonth(month);
    widget.onMonthChanged?.call(month);
  }

  static DateTime _normalize(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  DateTime _monthStart(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  DateTime _clampMonth(DateTime month, DateTime minMonth, DateTime maxMonth) {
    final candidate = _monthStart(month);
    if (candidate.isBefore(minMonth)) return minMonth;
    if (candidate.isAfter(maxMonth)) return maxMonth;
    return candidate;
  }

  /// data filled from provider to avoid recalculating progress for each day on every build
  void _primeMonth(DateTime month) {
    final habitProvider = context.read<HabitProvider>();
    final today = _normalize(DateTime.now());
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;

    final days = <DateTime>[];
    for (int i = 1; i <= daysInMonth; i++) {
      final day = DateTime(month.year, month.month, i);
      if (!day.isAfter(today)) {
        days.add(day);
      }
    }
    habitProvider.primeDayProgress(days);
  }

  bool _isEnabledDay(DateTime day, DateTime joined, DateTime today) {
    final normalized = _normalize(day);
    return !normalized.isBefore(joined) && !normalized.isAfter(today);
  }

  bool _isOutsideMonth(DateTime day, DateTime focusedMonth) {
    return day.year != focusedMonth.year || day.month != focusedMonth.month;
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
    final habitProvider = context.watch<HabitProvider>();
    final today = _normalize(DateTime.now());
    final joined = _normalize(habitProvider.dateJoined);
    final selectableFirstDay = joined.isAfter(today) ? today : joined;

    final minMonth = _monthStart(selectableFirstDay);
    final maxMonth = _monthStart(today);
    final focusedMonth = _clampMonth(_focusedMonth, minMonth, maxMonth);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _calendarHeader(cp, minMonth, maxMonth, focusedMonth),
        const SizedBox(height: 16),
        TableCalendar<void>(
          locale: Localizations.localeOf(context).toString(),
          key: ValueKey(
            'month-progress-calendar-${minMonth.millisecondsSinceEpoch}-${today.millisecondsSinceEpoch}',
          ),
          formatAnimationDuration: Duration(milliseconds: 300),
          firstDay: minMonth,
          lastDay: today,
          focusedDay: focusedMonth,
          calendarFormat: CalendarFormat.month,
          headerVisible: false,
          rowHeight: _rowHeight,
          availableGestures: AvailableGestures.horizontalSwipe,
          startingDayOfWeek: StartingDayOfWeek.monday,
          daysOfWeekHeight: MonthProgressCalendar.daysOfWeekHeight,
          enabledDayPredicate:
              (day) => _isEnabledDay(day, selectableFirstDay, today),
          onDaySelected: (selectedDay, focusedDay) {
            widget.onDaySelected(_normalize(selectedDay));
          },
          calendarBuilders: CalendarBuilders(
            defaultBuilder:
                (context, day, _) => _dayCell(
                  day: day,
                  joined: selectableFirstDay,
                  today: today,
                  isOutside: _isOutsideMonth(day, focusedMonth),
                  isToday: false,
                ),
            todayBuilder:
                (context, day, _) => _dayCell(
                  day: day,
                  joined: selectableFirstDay,
                  today: today,
                  isOutside: _isOutsideMonth(day, focusedMonth),
                  isToday: true,
                ),
            outsideBuilder:
                (context, day, _) => _dayCell(
                  day: day,
                  joined: selectableFirstDay,
                  today: today,
                  isOutside: true,
                  isToday: false,
                  forceDisabled: true,
                ),
            disabledBuilder:
                (context, day, _) => _dayCell(
                  day: day,
                  joined: selectableFirstDay,
                  today: today,
                  isOutside: _isOutsideMonth(day, focusedMonth),
                  isToday: false,
                  forceDisabled: true,
                ),
          ),
          daysOfWeekStyle: DaysOfWeekStyle(
            weekendStyle: TextStyle(
              color: cp.isDark ? cp.lightGreyText : cp.greyText,
              fontSize: 13,
            ),
            weekdayStyle: TextStyle(
              color: cp.isDark ? cp.lightGreyText : cp.greyText,
              fontSize: 13,
            ),
            dowTextFormatter: (date, locale) {
              return _capitalizeFirstLetter(DateFormat.E(locale).format(date));
            },
          ),
          onPageChanged: (focusedDay) {
            _setFocusedMonth(_clampMonth(focusedDay, minMonth, maxMonth));
          },
        ),
      ],
    );
  }

  Widget _calendarHeader(
    ColorProvider cp,
    DateTime minMonth,
    DateTime maxMonth,
    DateTime focusedMonth,
  ) {
    final locale = Localizations.localeOf(context);
    final monthLabel = DateFormat(
      'MMMM yyyy',
      locale.toString(),
    ).format(focusedMonth);

    final previousMonth = DateTime(
      focusedMonth.year,
      focusedMonth.month - 1,
      1,
    );
    final nextMonth = DateTime(focusedMonth.year, focusedMonth.month + 1, 1);

    final canGoBack = !previousMonth.isBefore(minMonth);
    final canGoForward = !nextMonth.isAfter(maxMonth);

    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: ShapeDecoration(
        color: cp.field,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
              _setFocusedMonth(_clampMonth(previousMonth, minMonth, maxMonth));
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
              _setFocusedMonth(_clampMonth(nextMonth, minMonth, maxMonth));
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
    required DateTime day,
    required DateTime joined,
    required DateTime today,
    required bool isOutside,
    required bool isToday,
    bool forceDisabled = false,
  }) {
    final cp = context.watch<ColorProvider>();
    final habitProvider = context.read<HabitProvider>();
    final darkMode = cp.isDark;
    final normalizedDay = _normalize(day);

    final isSelectable =
        !forceDisabled && !isOutside && _isEnabledDay(day, joined, today);
    final selectedDate = _normalize(
      habitProvider.selectedDate ?? DateTime.now(),
    );
    final isSelected = isSelectable && normalizedDay == selectedDate;

    final progressValue =
        isSelectable
            ? (habitProvider.cachedDayProgress(normalizedDay) ?? 0.0).clamp(
              0.0,
              1.0,
            )
            : 0.0;

    Color getBgColor() {
      if (isSelected) {
        return cp.pill;
      }
      if (isToday && !darkMode) {
        return cp.border;
      }
      return Colors.transparent;
    }

    Color getBorderColor() {
      if (isToday && darkMode && !isSelected) {
        return cp.border;
      }
      return Colors.transparent;
    }

    Color getDayNumberColor() {
      if (isSelected) {
        if (darkMode) return Colors.white;
        return cp.bg;
      }
      if (!isSelectable) {
        return cp.lightGreyText;
      }
      return cp.text;
    }

    Color progressColor() {
      if (progressValue >= 0.5) return cp.main;
      if (progressValue >= 0.3) return cp.mid;
      return cp.fail;
    }

    Color emptyProgressColor() {
      if (isSelected) {
        return cp.progressBarSelected;
      }
      if (isToday) {
        return cp.disabled;
      }
      if (!isSelectable) {
        if (darkMode) return const Color(0xFF1A1A1A);
        return const Color(0xFFF1F1F1);
      }
      return cp.disabled;
    }

    return Center(
      child: Container(
        width: 45,
        height: _rowHeight - 4,
        decoration: ShapeDecoration(
          color: getBgColor(),
          shape: StadiumBorder(
            side: BorderSide(color: getBorderColor(), width: 1),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${day.day}',
              style: TextStyle(
                color: getDayNumberColor(),
                fontSize: 17,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: 27,
              child: CustomPaint(
                painter: PartialArcPainter(
                  progress: progressValue,
                  color: progressColor(),
                  backgroundColor: emptyProgressColor(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
