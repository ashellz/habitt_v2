import 'package:flutter/material.dart';
import 'package:habitt/providers/calendar_provider.dart';
import 'package:habitt/providers/theme_provider.dart';
import 'package:habitt/widgets/calendar/calendar_day.dart';
import 'package:habitt/widgets/default/glass_feel_container.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class Calendar extends StatelessWidget {
  const Calendar({
    super.key,
    required this.tp,
    required this.calendarProvider,
    required this.focusedDay,
  });

  final ThemeProvider tp;
  final CalendarProvider calendarProvider;
  final DateTime focusedDay;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: GlassFeelContainer(
        child: TableCalendar(
          onDaySelected: calendarProvider.onDaySelected,
          availableGestures: AvailableGestures.horizontalSwipe,
          firstDay: DateTime.utc(2025, 1, 1),
          lastDay: DateTime.now().add(const Duration(days: 365)),
          focusedDay: focusedDay,
          selectedDayPredicate: (day) => isSameDay(day, focusedDay),
          // calendarFormat: CalendarFormat.month,
          startingDayOfWeek: StartingDayOfWeek.monday,
          calendarBuilders: CalendarBuilders(
            defaultBuilder: (context, date, events) => CalendarDay(date: date),
            selectedBuilder:
                (context, date, events) =>
                    CalendarDay(date: date, selected: true),
            todayBuilder:
                (context, date, events) => CalendarDay(date: date, today: true),
          ),
          headerStyle: HeaderStyle(
            titleTextStyle: TextStyle(
              color: tp.primaryTextColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            formatButtonVisible: false,
            leftChevronIcon: Icon(
              Icons.chevron_left,
              color: tp.primaryTextColor,
            ),
            rightChevronIcon: Icon(
              Icons.chevron_right,
              color: tp.primaryTextColor,
            ),
          ),
          daysOfWeekStyle: DaysOfWeekStyle(
            dowTextFormatter: (date, locale) {
              return DateFormat.E(locale).format(date).toUpperCase();
            },
            weekendStyle: TextStyle(
              color: tp.primaryTextColor,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
            weekdayStyle: TextStyle(
              color: tp.primaryTextColor,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
          calendarStyle: CalendarStyle(
            todayDecoration: BoxDecoration(
              color: tp.borderColor,
              shape: BoxShape.circle,
            ),
            selectedDecoration: BoxDecoration(
              color: tp.primaryColor,
              shape: BoxShape.circle,
            ),
            outsideDaysVisible: false,
            defaultTextStyle: TextStyle(color: tp.primaryTextColor),
            weekendTextStyle: TextStyle(color: tp.primaryTextColor),
          ),
        ),
      ),
    );
  }
}
