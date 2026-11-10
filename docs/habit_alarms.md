# Habit Alarms

Urgent habits (e.g. medicine) can be switched from a normal notification to an
alarm-style reminder with the **Alarm** checkbox in the habit sheet's
notifications section. It only shows while the Notifications toggle is on, and
it doesn't change that toggle: it just turns the habit's reminders into alarms.
Checking it replaces the per-habit sound picker (alarms always use the system
alarm ringtone).

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

## Ringing in silent mode (Android)

A notification channel's sound plays as a *notification*, which silent and
vibrate mode mute, even with `DefaultRingtoneType.Alarm`. So on Android the
sound is played natively on the **alarm audio stream** (`USAGE_ALARM`), which
the ringer mode doesn't touch:

- `_scheduleHabitNotifications` asks `AlarmRingService.canRing()` (Android with
  the exact alarm permission). When true, the awesome notification goes on
  `habit_alarm_silent_channel` (no sound, no vibration, registered in
  `main.dart`) with `preciseAlarm: true`, and `AlarmRingService.schedule` sets
  a native alarm with the same id and time. Otherwise it falls back to the
  sounding `habit_alarm_channel` as before. `NotificationService.isAlarmChannel`
  accepts both keys (action handler, `MainActivity`).
- Native side (`android/app/src/main/kotlin/.../`, method channel
  `habitt/alarm_ring`):
  - `HabitAlarmScheduler`: `AlarmManager.setAlarmClock` (exact, survives Doze;
    Android shows the alarm icon / "next alarm" for it). Scheduled alarms are
    stored in the `habit_alarm_ring` prefs so `cancelAll` and restoring work.
  - `HabitAlarmReceiver`: on fire, starts the ring service (allowed from the
    background because an exact alarm started it). On `BOOT_COMPLETED`,
    `MY_PACKAGE_REPLACED` and the exact-alarm permission being granted it
    re-schedules the stored alarms.
  - `HabitAlarmRingService`: foreground service (type `mediaPlayback`) that
    loops the default alarm ringtone with `MediaPlayer` on `USAGE_ALARM`,
    takes transient audio focus and vibrates with alarm usage. It watches the
    app's active notifications every second and stops once the alarm's
    notification is gone (Dismiss, Complete, the alarm page, a cancelled
    reminder), when it never shows up within 60 s, or after 10 minutes. Its
    own foreground notification is low-importance with a **Silence** button
    (labels `alarmRingingChannelName` / `alarmSilenceAction`, pushed from Dart
    via `configure` since the service runs without Flutter).
- `HabitAlarmPage._close` also calls `AlarmRingService.stopRinging()` so the
  sound stops at once instead of on the next watch tick.
- Cancelling reminders (`cancelHabitNotifications`, removed slots, per day,
  `cancelAllHabitNotifications`) cancels the native alarm too.

### Do Not Disturb

Alarm-stream sound already gets through DND (alarms are allowed in DND by
default), so no DND access is needed. Whether alarms *should* ring during DND
is a user setting: `NotificationsProvider.alarmRingDuringDnd` (pref
`notifications_alarm_ring_during_dnd`, default `false`), pushed to native with
`AlarmRingService.setRingDuringDnd` on app start and on change (the native side
keeps its own copy because it reads it when the alarm fires, without Flutter).
When it's off and DND is on
(`currentInterruptionFilter != ALL`) the receiver doesn't start the sound;
the alarm notification still shows. Ringer silent / vibrate mode always rings.
DND "Total silence", or alarms turned off in the user's DND settings, mute the
alarm stream regardless.

UI (Android only, `AlarmDndSetting` in `lib/widgets/notification/`): an
**Off / Alarms** selector ("Alarms" makes clear regular reminders still stay
quiet) with a short explanation. It shows in two places:

- Notification settings, "Alarms" section under the sound section. Part of the
  page's draft, saved with Save like the rest.
- `maybeShowAlarmDndDialog` (`alarm_dnd_dialog.dart`): the first time the user
  checks Alarm on any habit, before the alarm permission requests, a dialog
  with the same selector and a tip that it can be changed in Notification
  settings. Asked once (`notifications_alarm_dnd_asked`), however the dialog
  is closed; closing it keeps whatever the selector shows.

## Replaced / removed reminder slots

Each reminder is scheduled per slot × day (7 days ahead, non-repeating) with an
id derived from `habitId × slotId × day`. Cancelling by id only reaches the
habit's *current* slots, so a slot that was replaced or removed (new id from the
schedule → reminder prompt, or the slot deleted in the sheet) would keep its
pending notifications/alarms and ring at the old time for up to 7 days (a habit
moved from 00:00 to 20:00 rang at both). Two guards:

- `HabitProvider.updateHabit` diffs the slots before/after
  (`HabitNotificationTime.removedSlots`) and calls
  `NotificationService.cancelRemovedSlotNotifications` for the removed ones, so
  an edit takes effect immediately. Slots that only changed time keep their id
  and are simply overwritten.
- `scheduleAllHabitNotifications` (full sync: app start at most once a day,
  forced syncs, toggles) first calls `cancelAllHabitNotifications`, which lists
  every pending habit-typed notification and cancels it, catching anything the
  id-based paths can't reach (e.g. slots changed by a backup / device-sync
  merge). An earlier optimisation replaced this with per-id cancels and let
  orphans pile up.

## Full-screen alarm page (Android)

awesome_notifications uses the same intent for a tap and for the full-screen
intent: it opens `MainActivity` with action `SELECT_NOTIFICATION` and the
notification in the `notificationJson` extra. So:

- `MainActivity.kt` checks that extra for the alarm channel key and only then
  calls `setShowWhenLocked(true)` / `setTurnScreenOn(true)`, so the app shows
  over the lock screen for alarms and never otherwise.
- `NotificationActionHandler` sends actions on the alarm channel (tap /
  full-screen, not the buttons) to `_openAlarm`, which pushes
  `HabitAlarmPage` (`lib/pages/other_pages/habit_alarm_page.dart`, widgets in
  `lib/widgets/habit_alarm/`) instead of the habit details / log dialog. A
  cold start stores it in `_pendingAlarm` until the navigator is ready.
- The page mirrors the stock Android Clock ringing screen: the large time,
  the notification title (habit emoji + name) and two pill buttons side by
  side, **Complete** on the left (hidden for Health-linked habits, same as the
  notification button; goes through `PendingCompletionQueue`) and **Dismiss**
  on the right. Both dismiss the notification, which is what stops the sound.
  Back is blocked.
- On close it calls `AlarmScreenService.setShowOverLockScreen(false)`
  (method channel `habitt/alarm_screen`), so the keyguard covers the app again.

Android itself decides between full screen and heads-up: the page opens by
itself only when the screen is off or locked. While the phone is in use the
alarm is a heads-up notification (same as the Clock app); tapping it opens
the page.

## Permissions

`NotificationService.requestAlarmPermissions()` runs when the checkbox is checked
and asks only for the permissions that are still missing
(`checkPermissionList` first, since awesome_notifications opens a Settings page
for each special permission it requests). Denial is not fatal; the reminder
degrades to a high-priority notification.

- **Android:** asks for FullScreenIntent and PreciseAlarms. Manifest declares
  `USE_FULL_SCREEN_INTENT` and `SCHEDULE_EXACT_ALARM` (user-revocable; without
  it alarms fall back to the sounding channel, which silent mode mutes), plus
  `FOREGROUND_SERVICE` / `FOREGROUND_SERVICE_MEDIA_PLAYBACK` for the ring
  service (needs the foreground service declaration in the Play Console).
  `USE_EXACT_ALARM` is deliberately not used: Google Play restricts it to
  alarm-clock/calendar apps.
  - CriticalAlert / OverrideDnD are **not** requested on Android:
    awesome_notifications maps them to the Do Not Disturb access page, which
    needs `ACCESS_NOTIFICATION_POLICY` and so could never be granted; every
    check of the Alarm box sent the user to Settings. Alarm-category
    notifications already ring through DND (alarms are allowed by default),
    and so does the native alarm-stream sound (see above).
  - Android 14+ turns full-screen intents off for apps that aren't clock or
    phone apps, and awesome_notifications can't see that (it only checks the
    manifest permission, which always reads granted). `AlarmScreenService`
    asks `NotificationManager.canUseFullScreenIntent()` and, when it's off,
    opens the system "Full screen notifications" toggle for Habitt.
- **iOS 26+:** alarm habits use **AlarmKit** (rings through silent mode and
  Focus, lock-screen Stop button) instead of a notification. Bridge:
  `HabitAlarmKitBridge` in `ios/Runner/AppDelegate.swift` (method channel
  `habitt/alarmkit`) + `lib/services/alarm_kit_service.dart`. Needs
  `NSAlarmKitUsageDescription` in `Info.plist`; permission is requested when the
  Alarm checkbox is checked. Alarm ids = the habit notification ids (mapped to a
  deterministic UUID), cancelled alongside them. If AlarmKit is unavailable or
  denied, scheduling falls back to the notification path below. Only a Stop
  button is shown (no Complete/Open from the alarm; no countdown, so no widget
  extension is needed).
- **iOS < 26 / fallback:** the Critical Alerts entitlement
  (`com.apple.developer.usernotifications.critical-alerts`) must be requested
  from Apple and added to the app; without it the alarm is a normal
  notification, and iOS cannot loop a sound until dismissed either way.

## Notifications turned off

Saving a habit with notifications on never changes the habit's own setting
(`_checkNotificationPermissions` in `habit_sheet.dart`). If reminders can't
fire, the user is told instead, in this order:

1. a dialog when Habitt's own notification toggles are off (turn on);
2. a dialog with an **Open settings** button when notifications are denied in
   the OS and can't be asked again
   (`showSystemNotificationsDisabledDialog`).

The habit starts working once notifications are allowed. The same OS dialog is
shown by `NotificationService.requestPermissions` (settings page, toggles,
onboarding) instead of requesting again.

The notification settings page also shows `SystemNotificationsBanner` at the top
while notifications are turned off in the OS: not dismissible, re-checked when
the app resumes, with an **Open settings** button.

iOS 18+ notes: awesome_notifications opens the Settings app with the
deprecated `openURL:`, which iOS ignores, so `openSystemNotificationSettings`
(`lib/util/`) uses permission_handler's `openAppSettings` on iOS. For a denied
user its permission request also waits forever for them to come back from
Settings, so iOS asks the OS status first (`habitt/notification_status` channel,
`HabitNotificationStatusBridge` in `AppDelegate.swift`) and only requests when
the prompt can still be shown.

## Not verified

Written without a Flutter toolchain, Xcode or device (the Swift AlarmKit code is uncompiled and may need signature tweaks against the iOS 26 SDK): the Hive adapter and l10n
generated files were edited by hand (regenerate with
`flutter pub run build_runner build --delete-conflicting-outputs` and
`flutter gen-l10n`) and on-device ringing behaviour needs manual testing.

The native Android ringing (silent mode, DND gating, reboot restore, the
watch-based stop) compiles in a debug APK but hasn't been tested on a device.

The Android full-screen alarm page, the `MainActivity` lock-screen flags and
the full-screen-intent permission check compile (debug APK) but haven't been
tested on a device yet.
