import 'package:flutter/material.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _focusedDay = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );

  void onDaySelected(DateTime day, DateTime focusedDay) {
    setState(() {
      _focusedDay = day;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorProvider = context.watch<ColorProvider>();

    return Scaffold(
      backgroundColor: colorProvider.backgroundColor,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ListView(
          children: [
            Text(
              "Calendar",
              style: TextStyle(
                fontSize: 38,
                color: colorProvider.textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorProvider.standardColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TableCalendar(
                  onDaySelected: onDaySelected,
                  availableGestures: AvailableGestures.horizontalSwipe,
                  firstDay: DateTime.utc(2025, 1, 1),
                  lastDay: DateTime.now().add(const Duration(days: 365)),
                  focusedDay: DateTime.now(),
                  selectedDayPredicate: (day) => isSameDay(day, _focusedDay),
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
            ),
          ],
        ),
      ),
    );
  }
}
