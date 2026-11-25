# Habitt v2 — Apple Watch App

## Overview

A small watchOS app (`ios/HabittWatch`, SwiftUI, watchOS 10+) embedded in the
iOS app. It shows today's habits and lets the user complete or un-complete
them, and log amount and duration habits. Health-linked and time-of-day
habits are read-only on the watch. There are no complications yet.

Design reference: the canvas "Habitt Watch App"
(https://claude.ai/artifact/8sT9sXXmQAmTq8FPUPAXTt). Behaviour contract:
`openspec/changes/apple-watch-app/` (local only, `openspec/` is gitignored).

**The phone is the single source of truth.** The watch holds no habit,
schedule or streak logic: it draws the same JSON snapshot the home screen
widgets use (`docs/home_widgets.md`) and sends absolute "set state" actions
back. The phone applies them through the app's own `HabitProvider` code.
Everything stays on the user's devices (WatchConnectivity, no server).

```
 iPhone (Flutter)                                         Apple Watch
 ───────────────                                          ───────────
 WidgetSnapshotService ── write ──▶ HomeWidgetSnapshotWriter
                                     ├─ home_widget (widgets)
                                     └─ habitt/watch#pushSnapshot ─▶ WatchBridge ── applicationContext ─▶ WatchStore
                                                                    (+ sendMessage if reachable)          │
                                                                                                          ▼
                                                                                         snapshot + outbox overlay
                                                                                                 │  tap / crown
 HabitProvider.applyWatchAction ◀─ WatchSyncService.drain ◀─ peekActions ◀─ queue ◀── sendMessage / transferUserInfo
        │                           (collapse, ack)          removeActions   (UserDefaults)
        └─ notifies ─▶ snapshot rewritten with watchAcks ─▶ watch drops confirmed actions
```

## Code

| File | Role |
|---|---|
| `ios/HabittWatch/` | The watch app: `WatchStore` (WCSession, persisted snapshot and outbox), `TodayView` (list, day complete, messages), `HabitDetailView` (log / read-only), `HabitIndicator` (the phone's check, pie and ring). |
| `ios/HabittWidgetsCore/Sources/.../WatchState.swift` | `WatchAction`, `WatchOverlay` (apply/prune), dates. Foundation only, unit tested with `swift test`, compiled into the watch target. |
| `ios/HabittWidgetsCore/Sources/.../WidgetSnapshot.swift` | The snapshot model, shared with the widgets (also compiled into the watch target). |
| `ios/Runner/WatchBridge.swift` | iPhone side: WCSession delegate, the durable action queue and the `habitt/watch` channel. Activated in `AppDelegate.didFinishLaunching`, channel registered with the implicit engine. |
| `lib/services/watch_action_queue.dart` | `WatchAction` (Dart), `collapseWatchActions`, the channel queue store. |
| `lib/services/watch_sync_service.dart` | Drains and applies the queue, keeps the last 50 acks, pushes the snapshot. Started in `main.dart` after the first frame; drains on start and resume. |
| `HabitProvider.applyWatchAction` | Applies one action on its day: `completeHabit` (complete / un-check), `updateHabitAmountCompleted`, `updateHabitDurationCompleted`, without sound. |
| `tool/gen_ios_widget_strings.dart` | Also writes `ios/HabittWatch/<lang>.lproj/Localizable.strings` (keys `watch*`, `today`). |

## Snapshot fields the watch reads

On top of the widget snapshot (`v` 1, additive, widgets ignore them):

- per habit: `completed` and
  `log: { type: amount|duration|timeOfDay|null, target, value, unit, step, healthLinked, watchLoggable }`.
  Durations are in seconds, `step` is 1 (amount) or 60 (duration). `unit` is
  the amount label for the target, already localized. `watchLoggable` is true
  only for amount/duration habits without Health sync.
- `strings`: `today`, `anyTime`, `morning`, `afternoon`, `evening`,
  `optional` (list labels in the app's language).
- top level `watchAcks`: ids of the last 50 watch actions the phone applied
  or dropped, oldest first.

## Actions (watch → phone)

```jsonc
{ "watchAction": {
  "v": 1, "id": "UUID", "type": "complete" | "uncomplete" | "setAmount" | "setDuration",
  "habitId": 1795574050137094, "day": "2026-11-25",
  "value": 8,                       // setAmount: count, setDuration: seconds
  "at": "2026-11-25T08:31:02.000"   // watch local time, orders the actions
} }
```

- Values are absolute, so a duplicate is harmless. The log view sends one
  value ~0.8 s after the crown or buttons settle.
- Sent with `sendMessage` when the iPhone is reachable (this wakes the iPhone
  app in the background), otherwise or on failure with `transferUserInfo`
  (delivered once the devices reconnect). Actions created before the session
  activated are sent on activation. Nothing else is ever resent.

On the phone, `WatchBridge` appends each action to the queue
(`UserDefaults.standard`, key `habitt_watch_pending_actions`, JSON array,
deduped by id, max 500) **before** anything else, then calls
`actionsAvailable` if Dart is listening. Only the bridge touches the queue;
Dart reads it with `peekActions` and removes with `removeActions(ids)`, so a
removal can't race an append.

`WatchSyncService.drain`:

1. Removes actions whose id is already in the acks (a redelivery must not run
   again: the user may have changed the habit on the phone since).
2. `collapseWatchActions`: dedupes, keeps unsupported versions in the queue,
   keeps the newest action (by `at`) per habit and day; older ones are
   "superseded" (removed and acked, not applied).
3. Applies through `HabitProvider.applyWatchAction` with the navigator's
   context (same guards as the notification "Complete" drain: navigator ready,
   habits loaded, otherwise the queue is kept).
4. Removes the ids, adds them to the acks (`watch_recent_acks` in
   SharedPreferences, newest 50) and marks the snapshot dirty, so the watch
   gets them back in `watchAcks`.

`applyWatchAction` drops (and acks) actions for unknown, deleted or paused
habits, Health-linked and time-of-day habits, a type that doesn't match the
habit's tracking type, and no-ops (completing a done habit, the same value).
Un-completing mirrors the habit card: progress goes back to 0.

## Watch state

`WatchStore` keeps the last snapshot it understood and an outbox of
unconfirmed actions (both in the watch's `UserDefaults`). The screen draws
`WatchOverlay.apply(snapshot.block(at: now), outbox)`: the newest action per
habit sets its completed flag, value, progress, state and progress text, and
the day's done/total/perfect are recounted. An action leaves the outbox when
its id is in `watchAcks`, or when its day is no longer the shown day.
`refreshClock` runs on launch, when the app becomes active, on every new
snapshot and at `nextDayStartsAt` (a timer), so the day rolls over without the
phone.

Progress always animates: the row pie tweens 1250 ms ease-in-out like the
phone's, the check/pie swap scales in 300 ms, the log ring 350 ms.

## When actions are applied (Phase A)

| iPhone app | Watch action applied |
|---|---|
| Foreground, or suspended in memory | Immediately (`sendMessage` wakes it, `actionsAvailable` drains) |
| Not running | On the next app open or resume. The watch shows the change straight away (overlay); the streak, widgets and phone catch up when the app opens. |

Same limitation as the notification "Complete" button. Phase B (a later
change) would apply while the app isn't running: on a background launch for a
WCSession message no UIScene connects, so the implicit engine may not start;
`WatchBridge` would run a small headless `FlutterEngine` with its own Dart
entrypoint that opens Hive, drains with the same code and exits. Open points:
`completeHabit` needs a `BuildContext` today, Hive's single writer if the UI
engine starts meanwhile, and the ~30 s background budget. The queue, ids,
acks and `applyWatchAction` stay as they are.

## Versioning

- Snapshot `v` and action `v` change **only** for breaking changes. Adding a
  field never bumps them, and both sides ignore fields they don't know.
- A snapshot with `v` higher than the watch supports: the watch keeps the last
  one it understood and shows "Update Habitt" (`WidgetSnapshot.peekVersion`).
- The phone accepts every action version in `WatchAction.supportedVersions`
  (never remove one). An action with an unknown, higher `v` stays in the queue
  unapplied until an app update can apply it.

Changing the protocol:

1. Prefer an additive field with a safe default on both sides.
2. If it must break: bump the version, keep reading the old one, add the new
   one to `supportedVersions` / the watch's check, and handle both
   directions (new phone + old watch, new watch + old phone).
3. Update `widget_snapshot_builder_test.dart`, `watch_action_queue_test.dart`,
   `watch_action_apply_test.dart` and the Swift tests, and this document.

## Building

- The watch target is `HabittWatch` in `Runner.xcodeproj`, bundle id
  `com.shellz.habitt.watchkitapp`, automatic signing, versions from
  `Flutter/Generated.xcconfig` (via `HabittWatch.xcconfig`), so they always
  match the iPhone app. Runner depends on it and embeds it ("Embed Watch
  Content" → `Runner.app/Watch/`).
- `flutter build ios` / `flutter run` detect the companion app. A simulator
  build needs a device id (`-d`).
- Watch-only build check:
  `xcodebuild -project ios/Runner.xcodeproj -target HabittWatch -sdk watchsimulator CODE_SIGNING_ALLOWED=NO build`.
- Codemagic is not set up for the watch target yet.
- After changing watch strings in the ARB files run
  `dart run tool/gen_ios_widget_strings.dart`.
