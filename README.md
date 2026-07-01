# Habitt

A privacy-first, local-first habit tracker for iOS and Android — built with Flutter.

All habit data lives on-device. No analytics, no server-side data collection, no accounts required. Optional encrypted backup to your own Google Drive or iCloud, or a manual local backup file.

---

## Available on

iOS (App Store): https://apps.apple.com/ba/app/habitt-your-habit-tracker/id6745617462
Android (Google Play): https://play.google.com/store/apps/details?id=com.shellz.habitt&hl=en

---

## Features

**Habit tracking**
- Track habits by completion count (amount) or time spent (duration)
- Flexible schedules: daily, weekly, monthly, specific days of the week/month, or custom intervals
- Organize habits into time-of-day categories: Morning, Afternoon, Evening, or Any Time
- Optional time windows — set a start/end hour range for each habit (not available in new design yet)
- Streaks, longest-streak and many other stat tracking per habit, also for the whole database of habits
- Optional habits that don't affect your perfect-day streak, good when adding new habits while unsure you're gonna complete them every time
- Pause a habit — temporarily excludes it from tracking, scheduling and streaks without deleting it (useful for injury, sickness, travel, etc.)
- Import habits (and their full completion history) from HabitKit's export file, with overwrite or merge-by-name options

**Insights & stats**
- Habit strength score with personalized coaching messages
- Recommendations to increase or adjust targets as you build consistency
- Calendar heatmap view for historical completion
- Progress charts powered by fl_chart
- Animated streak celebration dialog when you hit a new perfect-day streak milestone

**Premade templates**
Quick-start habits: wake up early, go to bed early, brush teeth, skin care, shower, drink water, gym, running, walking, nutrition, medications, studying, reading, work, research and productivity sessions.

**Reminders**
- Per-habit push notifications with configurable times and personalized texts
- Morning, Mid-day, Wrap up notifications, schedulable per day of the week
- Selectable notification sounds — global default plus per-habit override

**Appearance**
- Dark and light mode

**Backup**
- Optional cloud backup via Google Drive or iCloud — data stays on your own account, never on our servers
- Manual local backup — export/import a backup file directly on-device, no account needed
- Client-side AES-256-GCM encryption (PBKDF2-HMAC-SHA256, 200 000 iterations), with optional PIN protection on the encryption key
- Automatic 15-second debounce sync after any change; manual "Sync Now" available
- Field-level conflict resolution when syncing across devices

**Localization**
English, German, Spanish, Italian, Bosnian

**Future features**

Habit goals:
- Add habit amount/duration goal, improvement sheets will show until goal is reached and no more

Show habit next day if missed
- For weekly, monthly and custom habit intervals, add toggle option: if habit is missed show it the next day and the next day until the next schedule. Why? You may want to eat omega 3 food every 3 days but you miss it once, instead of waiting 3 days again, just do it tomorrow

Daily planner:
- Adjust time range for habits, this existed before new design, logic is there but it just needs to be added to new design

More notification personalizations:
- Personalize day period notifications based on habit period completion progress, personalize premade habit template notifications more than they are now

Premade habit benefits:
- Add new UI elements to match premade habits better: such as importing glasses when adding amount of water drank to Drink water habit. Also customizable button presets user can make to add +10 or +50 / +10m or +1h by one press

Habits from onboarding:
- Upgrade onboarding to ask you questions and add premade habits based on your answers

Other features:
- Time counter telling you how long you're working on this habit, maybe show a strength graph over time as well
- Urgent habits (like medicine) get an alarm option for notification
- Widgets
- Live notifications like duolingo before habits reset if not all are completed
- Complete and add progress through notifications
- Previously deleted habits list - deletes after 30 days

---

## Tech stack

| Layer | Technology |
|---|---|
| Framework | Flutter / Dart 3.7+ |
| State management | Provider (ChangeNotifier) |
| Local storage | Hive CE |
| Notifications | Awesome Notifications |
| Charts | fl_chart |
| Backup storage | Google Drive API, iCloud (`icloud_storage`) |
| Auth (backup only) | Firebase Auth + Google Sign-In |
| Subscriptions | RevenueCat |
| Encryption | `cryptography` package (AES-256-GCM) |
| Secure storage | flutter_secure_storage (platform keychain) |

---

## Getting started

### Prerequisites

- Flutter SDK (see [flutter.dev](https://flutter.dev/docs/get-started/install))
- Dart SDK ^3.7.0
- For iOS: Xcode + CocoaPods
- For Android: Android Studio or the Android SDK command-line tools
- Firebase project configured (for backup feature) — `lib/firebase_options.dart` must be present

### Install and run

```bash
flutter pub get
flutter run
```

### Code generation

After modifying any Hive model (`@HiveType` / `@HiveField`), localization files (`.arb`), or asset lists, regenerate the derived files:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

Watch mode during active development:

```bash
flutter pub run build_runner watch
```

---

## Project structure

```
lib/
├── models/          # Hive data models (Habit, Day, Category, …)
├── providers/       # ChangeNotifier state providers
├── services/        # Business logic (backup, billing, notifications, colors)
├── pages/           # Screens
│   ├── main_pages/  # Home, Habits, Calendar, Profile, Settings
│   ├── onboarding/  # First-run flow
│   └── other_pages/ # Add/edit habit, backup, notifications, paywall, …
├── widgets/         # UI components organized by feature
├── util/            # Helpers and utilities
├── l10n/            # ARB localization files
└── generated/       # Auto-generated assets and l10n — do not edit
```

### Provider dependency order

```
StatsProvider
    └── HabitProvider ◄──► HabitStatsProvider
            └── CategoryProvider
                    └── BackupProvider
```

---

## Common commands

```bash
# Analyze / lint
flutter analyze

# Run tests
flutter test

# Run a single test file
flutter test test/services/habit_strength_insight_text_service_test.dart

# Build
flutter build apk --release   # Android
flutter build ios --release    # iOS
flutter build web              # Web
```

---

## Platform notes

| Platform | Details |
|---|---|
| Android | Min SDK 21, Target SDK 35, Compile SDK 36, Kotlin 2.3.0, Gradle 8.9.1 |
| iOS | Deployment target iOS 15.6+, CocoaPods |
| Web | Supported; splash screen disabled |

Android release builds require a keystore referenced in `android/app/build.gradle.kts`.

---

## Auto-generated files

Do not edit these directly — they are overwritten by `build_runner`:

- `lib/hive/hive_adapters.g.dart`
- `lib/hive/hive_registrar.g.dart`
- `lib/generated/` (entire directory)
- Any `*.g.dart` file

---

## AI usage

This project has been in active development since 2024 — long before AI-assisted coding became mainstream. The architecture, design decisions, and core logic are the product of hands-on engineering, not generated from scratch by an AI. This is not a vibecoded app.

AI tools (primarily Claude) are used selectively throughout this project as a development aid. The focus areas are:

- **Repetitive, boilerplate tasks** — generating adapter code, localization entries, or other mechanical patterns that follow a clear template
- **Quick bug fixes** — diagnosing and patching straightforward issues faster than doing it manually
- **Time-consuming but simple tasks** — things that are tedious rather than complex, where AI can compress hours into minutes
- **Feature planning** — talking through design decisions, tradeoffs, and implementation approaches before writing any code

All AI-generated code is reviewed and tested by me before it lands in the codebase. Nothing ships on AI output alone.

---

## License

This project is licensed under the **[Business Source License 1.1](LICENSE)** (BSL 1.1).

- **Non-production use** (personal projects, study, experimentation) is freely permitted.
- **Production use** requires a commercial license from the licensor.
- On **2030-05-26** the license automatically converts to the **MIT License**, at which point the code becomes fully open source.

---

## Legal

| Document | Link |
|---|---|
| Privacy Policy | [ashellz.github.io/habitt_v2/privacy](https://ashellz.github.io/habitt_v2/privacy) |
| Terms of Service | [ashellz.github.io/habitt_v2/tos](https://ashellz.github.io/habitt_v2/tos) |

**Privacy at a glance:** Habitt does not collect your habit data. Everything stays on your device. If you enable Google Drive sync, data is encrypted on-device before transfer — we cannot read it. No analytics, no ads. See the full [Privacy Policy](https://ashellz.github.io/habitt_v2/privacy) for details.

**Terms at a glance:** You own your data; we own the app code. Subscriptions are voluntary support payments and currently do not unlock additional features. The app is provided "as is" — always maintain your own backups. See the full [Terms of Service](https://ashellz.github.io/habitt_v2/tos) for details.

For inquiries: [ibrsboy32@proton.me](mailto:ibrsboy32@proton.me)
