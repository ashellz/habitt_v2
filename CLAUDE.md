# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Habitt v2** is a privacy-first, local-first habit tracking Flutter app (iOS, Android, web, desktop). All habit data is stored on-device via Hive; Google Drive backup is opt-in and client-side encrypted. No analytics or server-side data collection.

- **App ID:** `com.shellz.habitt`
- **Version:** 2.0.0+51
- **Dart SDK:** ^3.7.0

## Common Commands

```bash
# Install dependencies
flutter pub get

# Run the app
flutter run

# Code generation (Hive adapters, localization, assets) — run after model changes
flutter pub run build_runner build --delete-conflicting-outputs

# Watch mode for code generation during development
flutter pub run build_runner watch

# Analyze / lint
flutter analyze

# Run all tests
flutter test

# Run a single test file
flutter test test/services/habit_strength_insight_text_service_test.dart

# Build
flutter build apk --release      # Android
flutter build ios --release       # iOS
flutter build web                 # Web
```

## Architecture

### State Management — Provider

All global state lives in 13 `ChangeNotifier`-based providers in `lib/providers/`. They are wired up in `main.dart` using `ChangeNotifierProvider` and `ChangeNotifierProxyProvider`.

**Dependency order (top = no dependencies):**
```
StatsProvider
    └─> HabitProvider <──> HabitStatsProvider
            └─> CategoryProvider
                    └─> BackupProvider
```

Other providers (ThemeProvider, LanguageProvider, ColorProvider, CalendarProvider, PreferencesProvider, NotificationsProvider, ProfileImageProvider, StateProvider) are independent.

### Data Layer — Hive

Models in `lib/models/` are Hive objects. Generated adapters live in `lib/hive/hive_adapters.g.dart` and `lib/hive/hive_registrar.g.dart` — never edit these manually.

- **Box `habits`** — stores `Habit` objects
- **Box `days`** — stores `Day` objects

After modifying any `@HiveType` / `@HiveField` annotated model, regenerate with `build_runner build`.

### Key Directories

| Path | Purpose |
|------|---------|
| `lib/models/` | Hive data models (Habit, Day, Category, etc.) |
| `lib/providers/` | ChangeNotifier state providers |
| `lib/services/` | Business logic (backup, billing, notifications, colors) |
| `lib/pages/` | Screens/pages (home, main tabs, onboarding, other pages) |
| `lib/widgets/` | UI components, organized by feature |
| `lib/util/` | Utility functions and helpers |
| `lib/l10n/` | ARB localization files |
| `lib/generated/` | Auto-generated assets and l10n code — do not edit |
| `test/` | Unit tests with `test/fixtures/` for test data factories |

### Localization

Configured via `l10n.yaml`. ARB files are in `lib/l10n/`. Localized strings are accessed through the generated `AppLocalizations` class. After adding/modifying ARB entries, run `flutter gen-l10n` or `build_runner build`.

### Third-Party Integrations

- **RevenueCat** (`purchases_flutter`) — in-app purchases/subscriptions
- **Firebase Auth + Google Sign-In** — optional account for backup
- **Google Drive APIs** — optional encrypted backup/restore
- **Awesome Notifications** — local push notification scheduling

## Code Generation

The following files are auto-generated and must not be edited directly:
- `lib/hive/hive_adapters.g.dart`
- `lib/hive/hive_registrar.g.dart`
- `lib/generated/` (entire directory)
- Any `*.g.dart` file

## Platform Notes

- **Android:** Min SDK ~21, Target SDK 35, Compile SDK 36, Kotlin 2.3.0, Gradle 8.9.1
- **iOS:** Deployment target iOS 15.6+, CocoaPods for native deps
- Firebase configured per-platform in `lib/firebase_options.dart`
- Android signing keys are referenced in `android/app/build.gradle.kts` — keystore files must be present locally for release builds
