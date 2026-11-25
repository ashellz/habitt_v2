# Android home screen widgets: status report (in progress)

The usage limit cut this session short. The widgets are built, they compile, and they draw on a real home screen. Most of the emulator checklist has **not** been run yet.

## Toolchain
- Flutter 3.44.0 (Dart 3.12.0), JDK 21, Android SDK build-tools 35/36, emulator 37.3.10
- AVD `Habitt_API35` (Pixel 7, `system-images/android-35/google_apis/x86_64`, rootable)

## Built (commit 4198b978)
- `android/app/src/main/kotlin/com/shellz/habitt/widgets/`: `WidgetSnapshot.kt` (parser, today/tomorrow choice, part of day, next refresh time), `WidgetUi.kt` (colours, tap links, bitmaps for arcs and the ring), `HabittWidgets.kt` (4 Glance widgets and their receivers), `WidgetRefresh.kt` (inexact `setWindow` alarm at 04/12/19/day start, plus TIME_SET, TIMEZONE_CHANGED, LOCALE_CHANGED, BOOT and MY_PACKAGE_REPLACED)
- Manifest: 4 receivers, the refresh receiver, and the `home_widget` LAUNCH intent filter on MainActivity. Provider XMLs are in `res/xml/`.
- Drawables: per-mood backgrounds with `-night` variants, white masks tinted with day/night colours, and the artwork as VectorDrawables (`tool/svg_to_vector_drawable.dart`)
- Strings: `tool/gen_android_widget_strings.dart` generates `values*/widget_strings.xml` from the ARB files. New ARB key: `widgetOpenApp`.
- Dart: the snapshot `strings` gain `day`/`days`, with a test.
- Gradle: Glance 1.2.0, the Kotlin Compose plugin 2.3.0, JUnit and org.json for tests

## Tests
- `flutter test`: 756 passed at baseline; `test/services/` passed after the changes (the full suite has not been re-run)
- `flutter analyze`: 0 errors at baseline (not re-run)
- `./gradlew :app:testDebugUnitTest --tests "com.shellz.habitt.widgets.*"`: 12/12 passed
- `flutter build apk --debug`: OK

## Checklist
- Picker lists all 4 widgets with names and descriptions: **passed** (`shots/02_picker.png`)
- Streak and Streak week on the home screen, dormant and no-habit states: **passed** (seen live, not saved as screenshots)
- Everything else in section 3 (habits, live updates, theme, language, taps, day boundary, edge cases, dark mode): **not run**

## Known issues / to do
- Picker previews are placeholders (`drawable/widget_preview_*.xml`). Replace them with real captures.
- On Android 8–11 the glow can leak past the rounded corners (`cornerRadius` only clips on 12+)
- Pre-existing app bug: "RIGHT OVERFLOWED" on the Português chip in onboarding (`shots/01_launch.png`)
- `docs/home_widgets.md` is not yet updated for the native side
