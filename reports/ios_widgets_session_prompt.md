You are working in my local clone of Habitt v2 (Flutter habit tracker, bundle id `com.shellz.habitt`) on a Mac with Xcode. Your job: build the **iOS** side of the read-only home screen widgets (SwiftUI + WidgetKit), test everything yourself in the iOS Simulator, and report back. The Android side is done and is your reference for behaviour. Work on your own; stop to ask me only if you are truly blocked, for example on signing, the Apple Developer portal or a missing simulator runtime.

## 0. Setup

1. Run `git fetch origin && git checkout claude/sweet-goldberg-f7ropv && git pull`. All your work goes on this branch. Commit in small steps and push. Do not touch `main` and do not open a PR.
2. Read `CLAUDE.md`, then **`docs/home_widgets.md`** in full: the snapshot schema, rules, taps and native names. Its maintenance rule applies: any change to the widgets also updates that doc. `docs/home_widgets.md` mentions `openspec/changes/home-widgets-readonly/`. That folder is gitignored and not on this machine, so the doc is your contract.
3. Read `reports/android_widgets_report.md` (with `reports/shots/`). It shows every state on Android, the bugs found there and the open decisions. Read the Kotlin in `android/app/src/main/kotlin/com/shellz/habitt/widgets/` too. It is the reference implementation of what to draw from the snapshot.
4. If `lib/config/app_secrets.dart` is missing, copy `lib/config/app_secrets.example.dart` to it. It is gitignored: never commit it.
5. Check the toolchain: `flutter doctor -v`, Xcode, CocoaPods, and an iPhone simulator on iOS 17 or later (the deployment target is iOS 15.6, so the widgets must still build for 15.6). Note the versions in your report.
6. Baseline: `flutter pub get`, then `cd ios && pod install`, `flutter analyze` (expect 0 errors and about 149 existing infos/warnings that are not yours) and `flutter test` (expect all 759 to pass). If anything fails before you change code, report it and continue.
7. `flutter pub get` with a different Flutter version may rewrite `pubspec.lock`, `analysis_options.yaml` and generated plugin files. Do not commit that churn.

## 1. What already exists (do not redo)

- **Dart side, done and tested:**
  - `WidgetSnapshotBuilder` / `WidgetSnapshotService` write one JSON string, the snapshot (key `habitt_snapshot`, schema `v` 1), through `home_widget` into the App Group `group.com.shellz.habitt` UserDefaults. They then call `HomeWidget.updateWidget(iOSName: kind)` for each kind in `HomeWidgetKinds.ios`.
  - `WidgetLaunchHandler` handles `habitt://widget/home` and `habitt://widget/log?habit=<id>` on cold and warm starts.
  - The `habitt` URL scheme is already in `ios/Runner/Info.plist`.
- **Android widgets, done:** Jetpack Glance, all four widgets, tested on an emulator.
- **Not done on iOS:**
  - There is no widget extension yet.
  - The App Group is not in `ios/Runner/Runner.entitlements` yet; it only has iCloud.

## 2. Build the iOS widgets

Kinds must be exactly these (the Dart side already reloads them):

| Widget | `kind` | Family |
|---|---|---|
| Streak | `HabittStreakWidget` | `.systemSmall` |
| Streak week | `HabittStreakWeekWidget` | `.systemSmall` |
| Today ring | `HabittTodayRingWidget` | `.systemSmall` |
| Up next | `HabittUpNextWidget` | `.systemMedium` |

### Extension, App Group and signing

1. Add a Widget Extension target (for example `HabittWidgets`) in `ios/Runner.xcworkspace` with a `WidgetBundle` of the four widgets. The deployment target is 15.6, so gate any iOS 17-only API (`containerBackground`, `.contentMarginsDisabled`, interactive bits) with `if #available`.
2. Add the App Group `group.com.shellz.habitt` to both Runner and the extension (entitlements files plus the Signing & Capabilities tab). If the team or the portal needs me, for example to register the group or the extension's bundle id `com.shellz.habitt.HabittWidgets`, stop and tell me exactly what to click.
3. Make sure `pod install` and `flutter build ios --simulator` still work. Watch for the common Flutter pitfalls: the extension must not link Flutter pods, and keep the Podfile's target list in mind.

### Reading the snapshot

One shared reader in Swift:
- Read `UserDefaults(suiteName: "group.com.shellz.habitt")?.string(forKey: "habitt_snapshot")` and decode it with `Codable`. Check `v == 1`.
- **Ids are 16-digit numbers (microsecond timestamps): decode them as `Int64`** (Android first shipped them as 32-bit and broke taps).
- Choose `tomorrow` once now ≥ `nextDayStartsAt`, else `today`.
- Choose the Up next section by part of day: Morning 04:00–12:00, Afternoon 12:00–19:00, Evening 19:00–04:00.
- `hasHabits` false means the app has no habits at all.
- Optional fields may be missing in older snapshots. Fall back the way `WidgetSnapshot.kt` does.

**No snapshot yet** (installed, never opened) is a real state. Show the placeholder the way Android does: no habits (empty-box art plus "You haven't added any habits yet") and a 0 streak with the start-a-streak line, using localized strings in the extension (see Localization).

### Timeline

The `TimelineProvider` returns entries for now and for each upcoming boundary: 04:00, 12:00, 19:00 and `nextDayStartsAt`. After the last one use `.atEnd`, or a policy that reloads at the next boundary. The app's `updateWidget` calls `reloadTimelines` whenever the snapshot changes.

### Taps

Use `widgetURL` and, for Up next rows, `Link`. **Append `homeWidget` to every URL's query** so home_widget recognises the launch: `habitt://widget/home?homeWidget` and `habitt://widget/log?habit=<id>&homeWidget`. `WidgetLaunchHandler` ignores the extra parameter. Targets:
- Streak and Streak week open home.
- Up next rows open log for that habit; the rest of the widget opens home.
- Today ring opens log for the first id in `ring` that is not done, or home when the day is `perfect` or empty.

Check `ios/Runner/AppDelegate.swift`: home_widget needs the URL to reach Flutter on cold start and warm start.

### Localization

The picker name and description come from the `widget*Name` / `widget*Description` ARB keys in `lib/l10n/app_*.arb`. Placeholder text comes from `youHaventAddedAnyHabitsYet`, `dayStreakLabel`, `daysStreakLabel`, `day`, `days` and `widgetStartStreak`.

Android generates its strings with `tool/gen_android_widget_strings.dart`. Do the same for iOS:
- Write a small `tool/` script that writes the extension's `Localizable.strings` (or a String Catalog) for en, bs, de, es, fr, it, pt and tr from the ARB files.
- The ARB files stay the source of truth.
- Everything else the widgets show comes already localized in the snapshot (`strings.*`, labels, lines).

### Look

Match the app and the design canvas at https://claude.ai/artifact/CGWtP9vUgopBYWrwkH9T9Z (iOS sizes: small 170×170, medium 364×170). Its `Flame`, `Ring` (beads) and `NextList` boards have the exact colours. Read `WidgetUi.kt` for the same values in code.

**General:**
- Follow system light/dark.
- The accent comes from `theme.light/dark.accent`.
- Corner radius 24 is the system's; use `containerBackground` on iOS 17.
- Bundle the Satoshi font from `assets/new-fonts` into the extension if it is easy; otherwise use the system font.
- Art: use `assets/images/new-svg/streak.svg`, `streak-fade.svg`, `ice-left.svg`, `ice-over.svg` and `empty-box.svg` as vector assets (SVG or PDF in an asset catalog).

**Streak:** an ember card.
- Big count, "day streak"/"days streak" (lower case, from `strings`), then `streak.line`.
- Gradient plus glow plus flame per `streak.health`: healthy, fading, critical (flame plus ice).
- `perfectToday` adds a small white badge with an orange check.
- **Dormant** shows 0, the label and the invite line, with the healthy look.

**Streak week:**
- Plain card with a soft mood glow, a small flame, the count and `strings.days`, then the line.
- Then 7 columns of `week[].label` over a marker:
  - perfect: mini flame
  - partial or today: Habitt-green progress arc (`p`)
  - miss: grey dot
  - none: empty

**Today ring ("Beads"):**
- One segment per id in `ring` (4° gaps, butt caps, stroke 26 on a 170 card), filled to each habit's progress in the accent over a light grey track.
- The emoji sits centred on its segment, with `done/total` or an accent check in the centre.
- **More than 8 habits: one plain ring filled to the day's progress, no emojis.**
- No habits at all: empty-box art plus text.
- Habits but none today: `strings.nothingToday`.

**Up next:**
- Header with the part label and icon (sun, moon, clock for Any time), then up to 3 rows.
- Rows: emoji disc, name, `progressText` (skip it when empty and centre the name), and the indicator:
  - todo: grey check-circle
  - partial: accent pie with a 20 % ring
  - done: filled accent check, plus a 10 % accent row tint and a 20 % border
- A 104 pt streak tile on the right.
- Section null with habits: "Day complete" (`strings.dayComplete` / `dayCompleteBody`).
- No habits: empty box plus text.

**Optional:** iOS 18 tinted/accented rendering (the canvas has an "iOS tinted" row). Do it if it is cheap, otherwise note it.

## 3. Test it all yourself

Use the Simulator (`xcrun simctl`) and save screenshots (`xcrun simctl io booted screenshot shots/<name>.png`) for the report.

1. Run `flutter analyze` (0 errors) and `flutter test` (all pass). If you factor the snapshot decoding into a small Swift package or test target, add unit tests for it: decoding with Int64 ids, today/tomorrow by clock, 03:59/04:00/12:00/19:00 sections, and timeline entry dates.
2. `flutter build ios --simulator` must succeed. Run the app, finish onboarding and check the placeholder **before** creating habits. Then create about 5 habits across Morning, Any time and Evening (amount, duration, checkbox, one optional).
3. Add all 4 widgets through the real widget gallery. Screenshot each in light and dark (`xcrun simctl ui booted appearance dark|light`).
4. Each of these must reach the widgets within a few seconds; screenshot each:
   - complete a habit
   - partly log one
   - complete everything (Day complete, check in the ring, streak +1 with badge, home card "1 day streak" on a first perfect day)
   - switch the theme to Violet
   - switch the app language to Bosnian
5. Taps with the app terminated and with it backgrounded:
   - an Up next row must open Log progress for that habit
   - the ring and Streak must also open the right place
   - when a tap is the first open of a new day, the streak celebration must wait until Log progress is closed (already handled in Dart; just verify it)
6. Day boundary without the app: change the simulator's clock if you can, or check that the timeline entries are generated with the right dates and blocks (log them or unit test them). Say which you did.
7. Edge cases:
   - no habits
   - more than 8 habits (plain ring)
   - fresh install before the first snapshot
   - a very long habit name
   - Dynamic Type at a large size

Fix whatever you find. If a fix needs a Dart change, add or adjust tests in `test/services/widget_*_test.dart`. Update `docs/home_widgets.md` with an iOS section like the Android one (files, how things are drawn, generated resources).

## 4. Report back

Write `reports/ios_widgets_report.md` and commit it with its screenshots under `reports/shots/ios_*`. Then give me a short summary in chat:
- **Toolchain:** Flutter, Xcode and simulator versions.
- **Built:** files added or changed, including Xcode project and entitlement changes.
- **Tests:** commands and results.
- **Checklist:** each check from section 3 as passed, failed or not run, with the reason and a screenshot link.
- **Bugs:** what you found and fixed.
- **Deviations** from this prompt or `docs/home_widgets.md`, and why.
- **What I must do by hand:** App Group and bundle id in the Apple Developer portal, provisioning, TestFlight.
- **Open questions** for me.

Out of scope: interactive widgets (completing habits from the widget), lock screen and StandBy widgets, Live Activities, Android.
