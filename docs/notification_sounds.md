# Notification Sounds

How custom notification sounds work in Habitt, and how to add a new one.

## How it works

Android binds a notification's sound to its **channel**, and a channel's sound
is immutable once the channel is created on a device. So "different sounds" =
"different channels": we register **one channel per stock sound** at startup.

Each sound has a **stable key** (e.g. `sound_05`) that drives three things and
must never change once shipped:

| Thing | Derived from key | Example |
|-------|------------------|---------|
| Bundled asset (in-app preview) | `assets/sound/<key>.mp3` | `assets/sound/sound_05.mp3` |
| Android raw resource (channel) | `resource://raw/<key>` | `resource://raw/sound_05` |
| Notification channel | `habit_<key>` | `habit_sound_05` |

The **display name** shown to users is a separate localized string
(`soundName01`..`soundName10` in the ARB files) and can be changed freely
without touching the key, the channel, or any habit's stored `soundKey`.

Resolution at schedule time: a habit uses `habit.soundKey` if set, otherwise the
global default (`NotificationsProvider.globalSoundKey`). See
`NotificationService.globalSoundKey` and `effectiveSoundKey`.

### Picker options

The picker shows, in order (`NotificationSounds.pickerOrder`):
1. **App Default** — the `defaultKey` sound (`sound_05`), labelled "App Default"
   rather than "Sound 5" and not repeated in the numbered list.
2. **System Default** — the `systemKey` (`'system'`) sentinel. Routes to the
   existing `basic_channel` (no `soundSource`), so it plays the OS default
   notification sound without needing a separate channel that may not exist on
   older installs. Not previewable in-app (`isPreviewable` is false for it).
3. The remaining stock sounds (Sound 1–N, excluding the App Default).

The per-habit picker prepends a "Use global default" option (stored as
`soundKey == null`).

### Key files
- `lib/services/notification_sounds.dart` — the catalog (keys, asset/resource/channel mapping, default).
- `lib/main.dart` — registers one channel per catalog key at init.
- `lib/services/notification_service.dart` — resolves the channel per notification.
- `lib/services/sound_preview_player.dart` — in-app preview (audioplayers).
- `lib/widgets/notification/sound_picker_sheet.dart` — picker + display-name resolver.

## Adding a new sound

1. **Pick a short, license-clear file** (mono, ~1–2s, free for commercial use —
   e.g. Material sounds, Pixabay, Mixkit, or CC0 from freesound.org).

2. **Name it with a stable, resource-safe key.** Android `res/raw` rejects
   uppercase, spaces, and leading digits. Use the next `sound_NN`:
   `sound_11.mp3`.

3. **Drop the file in all three required places:**
   - `assets/sound/sound_11.mp3` (already covered by the `assets/sound/` entry in
     `pubspec.yaml`; used for in-app preview, mp3 is fine here).
   - `android/app/src/main/res/raw/sound_11.mp3` (lowercase filename; Android
     plays mp3 from `res/raw`).
   - The **iOS bundle**, as an `.aiff` file. ⚠️ awesome_notifications 0.10.1
     hardcodes the `.aiff` extension on iOS (`AudioUtils.getSoundFromResource`
     does `Bundle.main.url(forResource: name, withExtension: "aiff")`), so `.caf`,
     `.wav`, and `.mp3` are silently ignored and iOS falls back to the default
     system sound. Convert with the built-in macOS tool:
     `afconvert -f AIFF -d BEI16 assets/sound/sound_11.mp3 ios/sounds/sound_11.aiff`
     then drag `ios/sounds/sound_11.aiff` into Xcode → Runner target → Build
     Phases → Copy Bundle Resources. Keep the **same base name** as the key
     (`sound_11.aiff`) — awesome_notifications resolves `resource://raw/sound_11`
     to the bundled `sound_11.aiff`. This step is manual (Xcode only). If the
     package is upgraded, re-check the hardcoded extension in `AudioUtils`.

4. **Add the key to the catalog** in `lib/services/notification_sounds.dart`:
   append `'sound_11'` to `keys`.

5. **No display name needed.** Numbered sounds are labelled by their *position*
   in the list (`NotificationSounds.numberFor` → `loc.soundNumbered(n)`), not by
   filename, so a new key automatically shows up as the next "Sound N". The only
   localized strings are the shared `soundNumbered` ("Sound {number}") and the
   `notificationSound{App,System}Default` labels — none of which change when you
   add a sound. No ARB edit and no `switch` case are required.

6. The channel is registered automatically — `main.dart` loops over
   `NotificationSounds.keys`. No channel code change needed.

> ⚠️ Never reuse or rename an existing key. Renaming a key orphans every habit
> whose `soundKey` points at the old value. The displayed number follows list
> position, so users never see the raw key — to change wording, edit the
> `soundNumbered` / default-label strings in the ARB files.

## Changing the global default

The default is `NotificationSounds.defaultKey`. Changing it only affects new
installs / users who never picked a sound; existing users keep their stored
`globalSoundKey`.
