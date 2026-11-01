# Schedule → reminder prompt

Reminders (`Habit.notificationTimes`, `HabitNotificationTime`) are a separate
setting from the day schedule. So that an exact time / time range doesn't leave
the reminder somewhere else, the schedule flow offers to move it.

## Flow (`day_schedule_flow.dart`)

After **Done** on the specific-time picker or on the time range dialog,
`_offerReminder` shows `ScheduleReminderDialog` (a `NewDefaultDialog`):

- At the exact time (start time for a range), 5 / 10 / 15 / 30 minutes before
  (`scheduleReminderOffsets` in `lib/util/schedule_reminder.dart`).
- **Change reminder** pops the offset; **Keep my reminder** / dismiss changes
  nothing.

Choosing calls `StateProvider.replaceHabitNotificationTimes(...)`: it **replaces**
all reminders with one (`days` empty = follows the habit schedule) and turns
reminders on, so the dialog is shown even when reminders are off (its copy says
so). Existing reminders are replaced; the copy states that.

## Rules

- Editor state only, like every field in the habit sheet: closing the sheet
  discards it. Existing habits are never touched retroactively.
- No link is stored between schedule and reminder; the reminder is a plain copy
  of the chosen time (no model / Hive / backup change).
- Not shown for categories (any time / morning / afternoon / evening), when the
  flow is dismissed, or when the picked time equals what the sheet already held.
- Not shown for the inline start/end edits on the sheet (`editScheduleTime`).
- `reminderMinutesFor` **clamps to 00:00** instead of wrapping: a reminder's
  weekday (`days`, or the habit's schedule days when empty) is fixed, so 23:55
  would ring the day before the habit is due. Schedule 00:10 + 15 min before →
  00:00.
- The alarm flag and sound choice are untouched (they live on the habit, not on
  the slots); reminder text doesn't depend on the slot's time.
