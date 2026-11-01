/// How long before the schedule time the reminder should fire, in minutes.
/// Offered by the dialog shown after an exact time / time range is set.
const List<int> scheduleReminderOffsets = [0, 5, 10, 15, 30];

/// Offsets that stay on the same day as a schedule starting at
/// [scheduleMinutes]. An offset that would cross midnight is not offered: a
/// reminder's weekdays follow the habit's schedule (weekly / monthly / every N
/// days too), so it can't be moved to "the day before".
/// 00:10 → 0, 5, 10; 00:01 → 0 only.
List<int> availableReminderOffsets(int scheduleMinutes) =>
    scheduleReminderOffsets.where((o) => o <= scheduleMinutes).toList();

/// Reminder time (minutes of day), [offsetMinutes] before [scheduleMinutes].
/// Never goes below 00:00 (offsets from [availableReminderOffsets] don't).
int reminderMinutesFor(int scheduleMinutes, int offsetMinutes) =>
    (scheduleMinutes - offsetMinutes).clamp(0, (24 * 60) - 1);
