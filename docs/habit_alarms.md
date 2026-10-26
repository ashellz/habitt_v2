# Habit Alarms

Urgent habits (e.g. medicine) can be switched from a normal notification to an
alarm-style reminder with the **Alarm** toggle in the habit sheet's
notifications section. The alarm toggle replaces the per-habit sound picker
(alarms always use the system alarm ringtone).

## Data

`Habit.isAlarm` (Hive field 54, default `false`). Synced/merged like other
definition fields (see `docs/backup_system.md`). Draft state lives in
`StateProvider.habitIsAlarm`.

## Scheduling (`NotificationService._scheduleHabitNotifications`)

When `habit.isAlarm`:
- channel `habit_alarm_channel` (registered in `main.dart`): importance Max,
  `DefaultRingtoneType.Alarm`, `criticalAlerts`, locked, vibration;
- `NotificationCategory.Alarm` (awesome_notifications loops the sound for the
  Alarm category), `fullScreenIntent: true`, `autoDismissible: false`,
  `locked: true`;
- action buttons: **Dismiss** (`DismissAction`) plus the usual **Complete**.

## Permissions

`NotificationService.requestAlarmPermissions()` runs when the toggle is turned
on and asks for FullScreenIntent, PreciseAlarms, CriticalAlert and OverrideDnD.
Denial is not fatal; the reminder degrades to a high-priority notification.

- **Android:** manifest declares `USE_FULL_SCREEN_INTENT` and
  `SCHEDULE_EXACT_ALARM` (user-revocable). `USE_EXACT_ALARM` is deliberately
  not used: Google Play restricts it to alarm-clock/calendar apps.
- **iOS:** the Critical Alerts entitlement
  (`com.apple.developer.usernotifications.critical-alerts`) must be requested
  from Apple and added to the app; without it the alarm is a normal
  notification, and iOS cannot loop a sound until dismissed either way.

## Not verified

Written without a Flutter toolchain or device: the Hive adapter and l10n
generated files were edited by hand (regenerate with
`flutter pub run build_runner build --delete-conflicting-outputs` and
`flutter gen-l10n`) and on-device ringing behaviour needs manual testing.
