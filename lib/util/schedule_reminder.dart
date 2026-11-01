/// How long before the schedule time the reminder should fire, in minutes.
/// Offered by the dialog shown after an exact time / time range is set.
const List<int> scheduleReminderOffsets = [0, 5, 10, 15, 30];

/// Reminder time (minutes of day) for a schedule starting at
/// [scheduleMinutes] (the start time for a range), [offsetMinutes] earlier.
///
/// Clamped to 00:00 instead of wrapping into the previous day: reminders fire
/// on the days of the habit schedule (or their own weekdays), so 23:55 would
/// ring a day before the habit is due.
int reminderMinutesFor(int scheduleMinutes, int offsetMinutes) {
  return (scheduleMinutes - offsetMinutes).clamp(0, (24 * 60) - 1);
}
