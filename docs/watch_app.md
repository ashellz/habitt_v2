# Habitt v2 — Watch Apps (Apple Watch, Wear OS)

## Overview

Two small native watch apps with the same scope:

- **Apple Watch**: a watchOS app (`ios/HabittWatch`, SwiftUI, watchOS 10+)
  embedded in the iOS app.
- **Wear OS**: a Wear OS app (`android/wear`, Kotlin, Compose for Wear OS
  Material 3, Wear OS 3+ / API 30+), a separate APK/AAB under the phone app's
  package (see [Wear OS](#wear-os)).

They show today's habits and let the user complete or un-complete them, and
log amount and duration habits. Health-linked and time-of-day habits are
read-only on the watch. There are no complications or tiles yet.

Design references: the canvases "Habitt Watch App"
(https://claude.ai/artifact/8sT9sXXmQAmTq8FPUPAXTt) and "Habitt Wear OS App"
(https://claude.ai/artifact/2fupC7jodFpxo4Yegahdo3). Behaviour contracts:
`openspec/changes/apple-watch-app/` and `openspec/changes/wear-os-app/`
(local only, `openspec/` is gitignored).

Everything below the Wear OS section describes the shared protocol and the
Apple Watch; the Wear OS section lists what differs on Android.

**The phone is the single source of truth.** The watch holds no habit,
schedule or streak logic: it draws the same JSON snapshot the home screen
widgets use (`docs/home_widgets.md`) and sends absolute "set state" actions
back. The phone applies them through the app's own `HabitProvider` code.
There is no Habitt server: the snapshot and actions only travel between the
user's phone and watch (see [Privacy](#privacy)).

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
| `android/habitt-core/` | Pure Kotlin (JVM tested): `WidgetSnapshot.kt` (shared with the Android widgets, with the watch fields), `watch/WatchState.kt` (`WatchAction`, `WatchOverlay`, `WatchDates`, the twin of `WatchState.swift`), `watch/ActionQueue.kt` (the phone queue's JSON logic). |
| `android/app/.../watch/WearBridge.kt` | Android phone side: the durable queue, the `habitt/watch` channel (registered in `MainActivity.configureFlutterEngine`), the snapshot Data Layer item. |
| `android/app/.../watch/WearActionListenerService.kt` | Receives Wear OS actions (requests and fallback items), also when the app isn't running. |
| `android/wear/` | The Wear OS app: `WatchStore` (Data Layer, persisted snapshot and outbox, sending), `MainActivity` (navigation), `ui/` (`TodayScreen`, `HabitRow`, `LogScreen`, `ReadOnlyScreen`, `StateScreens`, `HabitIndicator`, `WearTheme` with `WearText`). |
| `tool/gen_android_widget_strings.dart` | Also writes `android/wear/src/main/res/values[-xx]/wear_strings.xml`. |

## Snapshot fields the watch reads

On top of the widget snapshot (`v` 1, additive, widgets ignore them):

- per habit: `completed` and
  `log: { type: amount|duration|timeOfDay|null, target, value, unit, step, healthLinked, watchLoggable }`.
  `target` is today's goal (a lighter day's `dayGoal` when set, see
  [goal_check_in.md](goal_check_in.md)). Durations are in seconds, `step` is
  1 (amount) or 60 (duration). `unit` is
  the amount label for the target, already localized. `watchLoggable` is true
  only for amount/duration habits without Health sync.
- `strings`: `today`, `anyTime`, `morning`, `afternoon`, `evening`,
  `optional` (list labels) and the watch UI text (`watchShowHabits`,
  `watchHealthNote`, `watchLogOnIPhone`, `watchOfTarget`, `watchCompleteHabit`,
  `watchUncompleteHabit`, `watchLess`, `watchMore`, `watchUpdateNeeded`,
  `watchUpdateNeededBody`; `%@` marks the value), plus the Wear OS wording of
  the texts that name the iPhone or Apple Health (`wearHealthNote`,
  `wearLogOnPhone`, `wearUpdateNeededBody`), all in the **app's** language. The watch reads every string through `WatchStore.text(key)`: the
  snapshot's, else its own `.lproj` translation (before the first sync).
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

When Dart is running (also suspended, woken by `sendMessage`), the bridge
starts a background task before telling Dart, so the app stays awake while
`WatchSyncService` applies the actions and writes the snapshot right away
(`afterDrain` → `WidgetSnapshotService.flush`, which also reloads the widgets
and pushes to the watch). Dart ends it with `drainDone`; it also ends by
itself after 20 s. Without it iOS suspended the app before the 500 ms
debounce, so widgets only caught up on the next open.

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
   `watch_action_apply_test.dart`, the Swift tests and the Kotlin tests in
   `android/habitt-core`, both watch apps, and this document.

The Wear OS app installs separately from Play (it isn't embedded like the
watchOS app), so a phone and a watch on different versions can last longer on
Android. The rules above cover it.

## Wear OS

The same protocol, snapshot and Dart code (`WatchSyncService`,
`collapseWatchActions`, `applyWatchAction`, acks) as the Apple Watch.
`WatchChannel.isAvailable` is true on iOS and Android. What differs:

```
 Android phone (Flutter)                                        Wear OS watch
 ───────────────────────                                        ─────────────
 WidgetSnapshotService ── write ──▶ HomeWidgetSnapshotWriter
                                     ├─ home_widget (widgets)
                                     └─ habitt/watch#pushSnapshot ─▶ WearBridge ── DataItem /habitt/snapshot ─▶ WatchStore
                                                                    (urgent, latest wins)                      │
                                                                                                               ▼
                                                                                              snapshot + outbox overlay
                                                                                                      │  tap / rotary
 HabitProvider.applyWatchAction ◀─ WatchSyncService.drain ◀─ peekActions ◀─ queue ◀── WearActionListenerService ◀─┤
                                                             removeActions  (SharedPreferences)  request /habitt/action
                                                                                                 or DataItem /habitt/action/<id>
```

### Data Layer

The Data Layer only connects apps with the **same application id and signing
certificate**, so `:wear` uses `applicationId = "com.shellz.habitt"` and the
same `android/key.properties` signing configs as `:app` (debug and release).
Two debug builds signed with different keys silently don't see each other.

| Path | Direction | What |
|---|---|---|
| `/habitt/snapshot` (DataItem, key `snapshot`) | phone → watch | The snapshot JSON, put urgently by `WearBridge.pushSnapshot` on every write. Latest wins, persisted by the Data Layer, synced whenever the watch connects (the iOS application context). |
| `/habitt/action` (request) | watch → phone | One action message (`{"watchAction": {…}}`, UTF-8). The phone replies `{"queued": true}` once it is in the durable queue. |
| `/habitt/action/<id>` (DataItem, key `action`) | watch → phone | The fallback for an action the phone didn't confirm (the iOS `transferUserInfo`). |

Capabilities (`res/values/wear.xml`): the phone app declares `habitt_phone`,
the watch app `habitt_watch`.

Sending an action (`WatchStore.transmit`): find a reachable `habitt_phone`
node (nearby first), `MessageClient.sendRequest` with a 5 s timeout. No node,
an error, no reply or `queued: false` → put the fallback item (urgent). A
request that timed out may still have arrived, so an action can reach the
phone twice; the queue dedupes by id and the drain drops acked ids. The watch
remembers which actions got a fallback item and deletes those items once the
action leaves its outbox (acked or stale); the phone deletes each fallback
item after queueing it. Nothing else is ever resent.

On the phone, `WearActionListenerService` (exported, intent filters for
`REQUEST_RECEIVED` on `/habitt/action` and `DATA_CHANGED` on `/habitt/action/`)
calls `WearBridge.receive`, which appends to the queue (private
SharedPreferences file `habitt_watch`, key `habitt_watch_pending_actions`,
JSON array, deduped by id, max 500, committed under one lock) **before**
replying, then calls `actionsAvailable` on the main thread if a Flutter engine
registered the channel. Dart reads and removes only through `peekActions` /
`removeActions`, exactly like `WatchBridge`. `drainDone` is a no-op on Android.
`peekActions` first sweeps any `/habitt/action/` items still on the phone into
the queue (`WearBridge.receiveItem`, the same path as the listener): an item
that synced while the phone app was being installed or updated never gets a
change event.

`pushSnapshot` also keeps the last snapshot; if putting it failed (no Google
Play services or no Wear OS app yet), it is tried again on the next drain
(`peekActions`, which runs on every start and resume). Without Play services
everything else works as before.

### When actions are applied on Android (Phase A)

| Phone app | Watch action applied |
|---|---|
| Open, or in the background with its Flutter engine alive | Immediately: the listener service runs in the app's process, `actionsAvailable` drains, the snapshot is written and pushed back |
| Process not running (killed, rebooted) | On the next app open or resume. The watch shows the change straight away (overlay). |

Android doesn't suspend a backgrounded Dart isolate like iOS does. The cached
app freezer (Android 14+) can freeze the process again shortly after the
listener service returns; a missed drain waits for the next resume (the action
is durable). Phase B on Android would start a headless `FlutterEngine` from
the listener service when no engine is attached, with the same open points as
on iOS.

### The watch app

`WatchStore` mirrors the watchOS one: it persists the last understood
snapshot and the outbox (`SharedPreferences`), reads the current
`/habitt/snapshot` item on start (`getDataItems`), listens to the Data Layer
while the app is visible, shows "Update Habitt" for a newer `v` while keeping
the last understood snapshot, and `refreshClock` runs on start/resume, on
every snapshot and at `nextDayStartsAt`. The screen draws
`WatchOverlay.apply(snapshot.blockAt(now), shownDay, outbox)` from
`:habitt-core`.

UI (Compose for Wear OS Material 3, round screens): `AppScaffold` with
`TimeText`, `SwipeDismissableNavHost` (swipe right to go back), the list is a
`ScalingLazyColumn` (rotary scrolling built in). The log screen draws the
ring along the screen edge, the value in the middle and −/+ below; the crown
or bezel moves one step per detent (~40 px of rotary scroll, at least one
per bezel click) with a tick haptic, and one value is sent ~0.8 s after it
settles or when leaving. Completing plays the confirm haptic. Colours,
indicator geometry and animation timings are the watchOS app's.

Texts: `WearText` reads the snapshot's string for a key (the phone app's
language), else the watch's own resource (`wear_strings.xml`, generated from
the ARB files). Texts that say "iPhone" / "Apple Health" on the Apple Watch
are read from their `wear*` keys instead. Art: `wear_art_streak` (from
`streak.svg`) and the Health Connect logo (`wear_health_connect`).

## Privacy

Nothing goes to a Habitt server; the watch apps only exchange the snapshot
(today's habits, names, progress, streak) and the actions with the user's
own phone.

- **Apple Watch**: WatchConnectivity, Apple's own phone ↔ watch channel.
- **Wear OS**: the Wearable Data Layer of Google Play services. Over
  Bluetooth or the local Wi-Fi when the devices are close; when the watch is
  away from the phone on Wi-Fi or LTE, Google relays Data Layer traffic
  through its cloud for the user's account. That's the platform's channel
  (the one notifications use too) and can't be turned off by the app.

`privacy.md` (the published privacy policy) says the same; keep them in step.

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
  `dart run tool/gen_ios_widget_strings.dart` and
  `dart run tool/gen_android_widget_strings.dart`.

Wear OS (from `android/`; `flutter pub get` must have run once, the Flutter
Gradle plugin loader needs it):

- `./gradlew :wear:assembleDebug`, then
  `adb -s <watch> install -r ../build/wear/outputs/apk/debug/wear-debug.apk`
  (Flutter puts Gradle outputs in the root `build/`).
  Don't use `:wear:installDebug` while a phone is connected too: it installs
  on every device, and the watch APK replaces the phone app (same
  application id). `./gradlew :wear:bundleRelease` builds for Play (R8 on).
- `./gradlew :habitt-core:test` runs the Kotlin model, overlay and queue tests.
- `flutter build apk/appbundle` builds only the phone app (it includes
  `:habitt-core`).
- Versions come from `pubspec.yaml`: `versionName` is the same as the phone's,
  `versionCode` is `1_000_000 + build number` (Play needs a unique code per
  artifact under one package). The manifest requires
  `android.hardware.type.watch` and sets `com.google.android.wearable.standalone`
  to false.
- Codemagic and the Play Console's Wear OS form factor aren't set up yet.

Emulator testing: install a Wear OS system image (Android Studio's SDK
Manager, e.g. "Wear OS 5 ARM 64 v8a"), create a Wear OS Large Round AVD and
pair it with a phone AVD that has the Play Store, using Android Studio's
Wear OS pairing assistant (Device Manager → Pair Wearable; it installs the
Wear OS companion app on the phone). Then `flutter run` the phone app and
install the watch APK with `adb -s <watch>` as above, both signed with the
same debug key. If the two don't connect after an emulator restart, forward
the Wear port again: `adb -s <phone> forward tcp:5601 tcp:5601`.

On the phone emulator a debug build for all ABIs (~200 MB) may not fit;
`flutter build apk --debug --target-platform android-arm64` is much smaller.

## Store screenshots

The App Store (Apple Watch) and Play Store (Wear OS) screenshots are taken
from the real watch apps on simulators, with a fixed snapshot instead of a
paired phone, so every language shows the same habits:

1. `flutter test tool/store_screenshots/watch_fixtures_test.dart` writes
   `marketing/watch_screenshots/fixtures/<lang>/<shot>.json` through the real
   `WidgetSnapshotBuilder` (8 languages; shots `today`, `log_amount`,
   `log_duration`, `day_complete`). The snapshots are for today's date, so
   regenerate them on the day you capture.
2. Debug builds only, both apps take a snapshot and a habit to open at launch:
   - watchOS: environment `HABITT_SCREENSHOT_SNAPSHOT` (a file path) and
     `HABITT_SCREENSHOT_OPEN` (a habit id), read in `WatchStore.init` and
     `RootView`, behind `#if DEBUG`. The watch target's Debug configuration
     doesn't set `DEBUG`, so build with `SWIFT_ACTIVE_COMPILATION_CONDITIONS=DEBUG`.
     The WCSession isn't activated in this mode.
   - Wear OS: intent extras `screenshotSnapshot` (a file name in the app's
     files dir) and `screenshotOpen`, read in `MainActivity.screenshotSetup`
     only when the app is debuggable; `WatchStore.showScreenshot` then skips
     the Data Layer.
3. `tool/store_screenshots/capture_watchos.sh` (Apple Watch Ultra 3
   simulator, 422×514) and `tool/store_screenshots/capture_wear.sh` (Wear OS
   Large Round emulator, 454×454, `adb root` for the 9:41 clock) write
   `marketing/watch_screenshots/{watchos,wear_os}/<lang>/<n>_<shot>.png`.
   The scripts' headers list the build and install steps.

Play wants Wear OS screenshots square and unmasked (it rounds them itself),
with nothing added, so they are uploaded exactly as captured.
