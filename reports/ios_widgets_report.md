# iOS home screen widgets: report

Branch `claude/sweet-goldberg-f7ropv`. All four widgets (Streak, Streak week,
Today ring, Up next) are built as a SwiftUI WidgetKit extension and tested in
the iOS Simulator. Screenshots are in [`shots/`](shots/) as `ios_*` JPEGs.

## Toolchain

| | |
|---|---|
| Flutter | 3.44.5 stable (Dart 3.12.2), macOS (Darwin 27) |
| Xcode | 27.0 (27A266a), iOS 27.0 SDK |
| CocoaPods | 1.16.2 |
| Simulator | iPhone 17, iOS 27.0 (runtimes 18.5, 26.5 and 27.0 installed) |
| Libraries | `home_widget` 0.10.0 |
| Deployment target | iOS 15.6 (app and extension; everything newer is behind `#available`) |

`flutter pub get` with this Flutter rewrites `pubspec.lock`; that churn is
not committed. `ios/Podfile.lock` gains the `home_widget` pod, which was
missing (committed).

## Built

New, `ios/HabittWidgets/` (the extension):

- `HabittWidgetsBundle.swift`: the `WidgetBundle` with the four kinds
  `HabittStreakWidget`, `HabittStreakWeekWidget`, `HabittTodayRingWidget`
  (`.systemSmall`), `HabittUpNextWidget` (`.systemMedium`).
- `WidgetProvider.swift`: one `TimelineProvider`, the App Group store, the
  placeholder from the extension's strings, a log line per timeline.
- `WidgetStyle.swift`, `WidgetPieces.swift`: colours (light, dark, tinted),
  ember moods, Satoshi fonts, shared pieces.
- `StreakWidget.swift`, `StreakWeekWidget.swift`, `TodayRingWidget.swift`, `UpNextWidget.swift`.
- `Info.plist` (widgetkit extension point, `UIAppFonts`), `HabittWidgets.entitlements`
  (App Group), `HabittWidgets.xcconfig` (only `Flutter/Generated.xcconfig`, for the version).
- `Assets.xcassets` (generated): `art_*` from the five app SVGs, `icon_*` templates.
- `<en|bs|de|es|fr|it|pt|tr>.lproj/Localizable.strings` (generated).

New, `ios/HabittWidgetsCore/`: a Swift package with `WidgetSnapshot.swift`
(the snapshot model, decoding, block/part-of-day choice, timeline dates, tap
URLs, placeholder) and its tests. The extension compiles that file directly;
the package exists so `swift test` can run it on the Mac.

New tools: `tool/gen_ios_widget_strings.dart`, `tool/gen_ios_widget_art.dart`.

Changed:

- `ios/Runner.xcodeproj/project.pbxproj`: `HabittWidgets` target (bundle id
  `com.shellz.habitt.HabittWidgets`, team `CGYK83WV76`, automatic signing,
  Debug/Release/Profile), Runner depends on it and embeds it in an "Embed
  Foundation Extensions" phase placed before "Thin Binary", new
  `knownRegions` (bs, de, es, fr, it, pt, tr). The target was added with the
  `xcodeproj` gem; no Flutter, pod or package is linked into the extension.
- `ios/Runner/Runner.entitlements`: App Group `group.com.shellz.habitt`.
- `docs/home_widgets.md`: iOS section (files, drawing, generated resources,
  Xcode 27 build note), iOS timeline description.
- No Dart changes. `AppDelegate.swift` unchanged: home_widget 0.10 registers
  as application and scene delegate itself and the taps arrive on cold and
  warm start (checked below).

## Tests

| | Command | Result |
|---|---|---|
| Dart analyzer | `flutter analyze` | 0 errors, 149 infos/warnings (same as the baseline) |
| Dart tests | `flutter test` | 759 passed (same as the baseline) |
| Swift tests | `cd ios/HabittWidgetsCore && swift test` | 14 / 14 passed |
| Extension alone | `xcodebuild -project ios/Runner.xcodeproj -target HabittWidgets -sdk iphonesimulator` | OK, no warnings in our files |
| App | `FLUTTER_XCODE_ARCHS=arm64 flutter build ios --simulator --debug` | OK (see Bugs 1 for why not plain `flutter build ios --simulator`) |

Swift tests: full decode, 16-digit ids exact (and in the tap URL), missing /
other-version / malformed snapshot, older snapshot fallbacks (no `day`/`days`,
`noHabits`, bad accent, unknown state), today/tomorrow at 23:59:59, 00:00 and
the next day, parts of day at 03:59, 04:00, 11:59, 12:00, 18:59, 19:00,
00:00, Up next section by clock, ring tap target (first not done, perfect,
empty), plain ring progress, timeline entry dates (morning, late evening
after a past `nextDayStartsAt`, a 03:00 day start, a DST change), placeholder.

## Checklist (section 3)

| # | Check | Result | Shots |
|---|---|---|---|
| 1 | analyze, test, Swift tests | **Passed** | – |
| 2 | Build | **Passed** with one architecture (Bugs 1) | – |
| 2 | Placeholder before the first snapshot (installed, never opened) | **Passed**: empty box + "You haven’t added any habits yet", 0 "days streak" + start-a-streak line, light and dark | `ios_01_*` |
| 2 | Onboarding, no habits, real snapshot | **Passed**: same look from the app's `hasHabits: false` snapshot | `ios_02_no_habits_light` |
| 2 | 5 habits: Drink water (amount, Any time), Shower (duration, Morning), Brush teeth (checkbox, Evening), Mindfulness (duration, Evening, optional), a very long checkbox habit (Any time) | **Passed** | `ios_03_habits_light` |
| 3 | All 4 widgets added through the real widget gallery (search "Habitt", swipe to each, Add Widget) | **Passed** | `ios_01_*` |
| 3 | Light and dark | **Passed**: follows the system without the app | `ios_01_*`, `ios_04_*`, `ios_05_*`, `ios_15_*` |
| 4 | Complete a habit | **Passed**, within ~2 s: tinted done row with check, ring segment, 1/4 | `ios_04_*` |
| 4 | Partly log one (3 / 10 dl) | **Passed**: pie, "3 / 10 dl", partial segment, week arc | `ios_04_*` |
| 4 | Complete everything | **Passed**: Day complete, accent check in the ring, streak 0 → 1 "day streak" with badge, today's ember in the week; home card "1 day streak" | `ios_05_*` |
| 4 | Theme Violet | **Passed**: ring, checks, Day complete check | `ios_06_violet_light` |
| 4 | Language Bosnian | **Passed**: "dan streak", "Dan završen …", "Veče", weekday letters Č P S N P U S | `ios_07_*` |
| 5 | Taps, app terminated | **Passed**: Today ring → Log progress for the first habit not done (Drink water); Up next row → Log progress for that habit | `ios_11_tap_ring_cold_log`, `ios_13_tap_row_cold_log` |
| 5 | Taps, app backgrounded | **Passed**: Up next row → Log progress; Streak (app left on a Habit details page) → home | `ios_10_tap_row_background_log`, `ios_12_tap_streak_background_home` |
| 5 | Celebration waits for Log progress on a new day's first open | **Not run on iOS**: the simulator's clock is the Mac's and I did not change the Mac's time. This is shared Dart (`NotificationActionHandler.tapOpening`) with no iOS-specific code, and it passed on Android |
| 6 | Day boundary without the app | **Checked by unit tests and the timeline log**, not by moving the clock (same reason). On the device the extension logged, e.g. at 16:24: entries 16:24 today/afternoon, 19:00 today/evening, 00:00 **tomorrow**/evening, 04:00 tomorrow/morning, 12:00 tomorrow/afternoon (`log show --predicate 'subsystem == "com.shellz.habitt.widgets"'`) |
| 7 | No habits | **Passed** | `ios_02_no_habits_light` |
| 7 | More than 8 habits | **Passed**: 9 habits → one plain ring, 3/9, no emojis | `ios_08_nine_habits` |
| 7 | Fresh install before the first snapshot | **Passed** | `ios_01_*` |
| 7 | Very long habit name | **Passed**: one line with "…", other rows unaffected | `ios_03_habits_light` |
| 7 | Dynamic Type at AX5 | **Passed**: text grows up to `.xxLarge`, nothing overflows or clips | `ios_09_dynamic_type_ax5` |
| – | Streak moods fading and critical, light and dark | **Passed** (crafted snapshots written to the App Group, see note) | `ios_15_*` |
| – | iOS 18+ tinted home screen (optional) | **Done**: tinted colours, white accent parts, desaturated art | `ios_14_tinted` |

Note on moods: the test habits never had a fading or critical streak, so I
wrote copies of the real snapshot with `health` fading (44) and critical
(43) into the App Group plist and reinstalled the app (which reloads the
timelines without starting it), then restored the real snapshot.

## Bugs found and fixed

1. **`flutter build ios --simulator` fails with Xcode 27** (toolchain, not
   this change). Xcode 27's `lipo -verify_arch` accepts only one
   architecture, so Flutter's `debug_unpack_ios` reports that a fat
   `x86_64 arm64` Flutter.framework "does not contain architectures arm64
   x86_64". It fails before any project code is built. Workaround:
   `FLUTTER_XCODE_ARCHS=arm64 flutter build ios --simulator` (also noted in
   the docs). `flutter run` and device builds are single-architecture and
   not affected.
2. **Up next's streak tile was 121 pt instead of 104** (mine, fixed in
   `iOS widgets: keep the ember glow and art out of layout`). The tile's
   130 pt glow took part in layout, so the tile spilled over the 10 pt gap to
   the rows and most of the right padding; the Streak card's flame was
   shifted the same way. The glow and art are an overlay now. Shots
   `ios_03`–`ios_09`, `ios_10`–`ios_14` were taken before the fix (the tile
   touches the rows there); `ios_15_*` and `ios_16_upnext_tile_padding_fixed*`
   show the fixed layout.

## Deviations

- **Snapshot model in a Swift package** (`ios/HabittWidgetsCore`) that the
  extension compiles as a source file rather than linking, so it can be
  tested with `swift test` without a test target in the Flutter project.
- **Timeline**: no 00:00 entry unless it is `nextDayStartsAt` (nothing
  changes at midnight otherwise; Android redraws then anyway). Entries cover
  the next 24 hours, then `.atEnd`.
- **Design over Android where they differ**: Up next's tile uses the
  desaturated flame for fading (the canvas), not `streak-fade` (Android); the
  Streak week header flame is muted for fading and icy for critical, and
  critical's perfect-day flames are dimmed (the canvas; Android draws them
  plain).
- **No picker preview images**: the gallery shows the live widgets with the
  user's data (or the placeholder before the first snapshot).
- **Dynamic Type** is capped at `.xxLarge` inside the widgets, with longer
  text scaling down, so the fixed card layouts never overflow.
- **Tinted mode**: emojis become silhouettes on a tinted home screen; that
  is the system's rendering of text there.

## What you must do by hand

1. **Apple Developer portal** (or let Xcode do it with automatic signing,
   signed in with team `CGYK83WV76`, by building to a device once):
   - register the App Group `group.com.shellz.habitt`;
   - enable App Groups on the App ID `com.shellz.habitt` and add the group;
   - register the App ID `com.shellz.habitt.HabittWidgets` with App Groups
     and the same group.
2. **Provisioning for CI / Codemagic**: an App Store profile for
   `com.shellz.habitt.HabittWidgets` next to the app's, and regenerate the
   app's profile (its entitlements gained the App Group). If Codemagic
   fetches profiles automatically, make sure it fetches both bundle ids.
3. **TestFlight**: one build to check the widgets on a real device (taps,
   gallery, tinted mode).

## Open questions

1. The first screenshot commit (`1a55f76b`) added 32 MB of PNGs, replaced
   by 1.9 MB of JPEGs in the next commit. The PNGs stay in the branch
   history unless the branch is squashed or rewritten. Want me to do that
   (needs a force push)?
2. The gallery shows live data, which is the empty placeholder for a new
   user. Do you want sample-data previews instead (`context.isPreview`)?
   They would need sample habit names in all 8 languages.
3. Dynamic Type stops at `.xxLarge` in the widgets. Fine, or should the
   cards grow text further with fewer lines?
