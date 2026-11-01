/// How long before the schedule time the reminder should fire, in minutes.
/// Offered by the dialog shown after an exact time / time range is set.
const List<int> scheduleReminderOffsets = [0, 5, 10, 15, 30];

/// Reminder time (minutes of day) for a schedule starting at
/// [scheduleMinutes] (the start time for a range), [offsetMinutes] earlier.
///
/// Wraps around midnight: 00:10 with 15 minutes before gives 23:55.
int reminderMinutesFor(int scheduleMinutes, int offsetMinutes) {
  const day = 24 * 60;
  return (((scheduleMinutes - offsetMinutes) % day) + day) % day;
}
