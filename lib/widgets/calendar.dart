import 'package:flutter/material.dart';
import 'package:habitt/providers/calendar_provider.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class Calendar extends StatelessWidget {
  const Calendar({
    super.key,
    required this.colorProvider,
    required this.calendarProvider,
    required this.focusedDay,
  });

  final ColorProvider colorProvider;
  final CalendarProvider calendarProvider;
  final DateTime focusedDay;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorProvider.standardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: TableCalendar(
          onDaySelected: calendarProvider.onDaySelected,
          availableGestures: AvailableGestures.horizontalSwipe,
          firstDay: DateTime.utc(2025, 1, 1),
          lastDay: DateTime.now().add(const Duration(days: 365)),
          focusedDay: focusedDay,
          selectedDayPredicate: (day) => isSameDay(day, focusedDay),
          // calendarFormat: CalendarFormat.month,
          startingDayOfWeek: StartingDayOfWeek.monday,
          headerStyle: HeaderStyle(
            titleTextStyle: TextStyle(
              color: colorProvider.textColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            formatButtonVisible: false,
            leftChevronIcon: Icon(
              Icons.chevron_left,
              color: colorProvider.textColor,
            ),
            rightChevronIcon: Icon(
              Icons.chevron_right,
              color: colorProvider.textColor,
            ),
          ),
          daysOfWeekStyle: DaysOfWeekStyle(
            dowTextFormatter: (date, locale) {
              return DateFormat.E(locale).format(date).toUpperCase();
            },
            weekendStyle: TextStyle(
              color: colorProvider.textColor,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
            weekdayStyle: TextStyle(
              color: colorProvider.textColor,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
          calendarStyle: CalendarStyle(
            todayDecoration: BoxDecoration(
              color: colorProvider.colorScheme.strokeColor,
              shape: BoxShape.circle,
            ),
            selectedDecoration: BoxDecoration(
              color: colorProvider.colorScheme.darkerStandardColor,
              shape: BoxShape.circle,
            ),
            outsideDaysVisible: false,

            defaultTextStyle: TextStyle(color: colorProvider.textColor),
            weekendTextStyle: TextStyle(color: colorProvider.textColor),
          ),
        ),
      ),
    );
  }
}
