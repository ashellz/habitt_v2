/// Single source of truth for the app's stock notification sounds.
///
/// Each sound has a STABLE key (e.g. `sound_05`) that drives three things and
/// must never change once shipped:
///   1. the bundled asset path  -> `assets/sound/<key>.mp3`  (used for in-app preview)
///   2. the Android raw resource -> `resource://raw/<key>`    (used by the channel)
///   3. the notification channel -> `habit_<key>`            (Android binds sound to channel)
///
/// The user-facing DISPLAY NAME is a separate localized string (see ARB keys
/// `notificationSound_<key>`) and can be changed freely without touching the
/// key, channel, or any persisted `soundKey` on a habit.
///
/// To add a new sound, see docs/notification_sounds.md.
class NotificationSounds {
  NotificationSounds._();

  /// Stable keys for every stock sound, in display order.
  static const List<String> keys = [
    'sound_01',
    'sound_02',
    'sound_03',
    'sound_04',
    'sound_05',
    'sound_06',
    'sound_07',
    'sound_08',
    'sound_09',
    'sound_10',
  ];

  // app default
  static const String defaultKey = 'sound_05';

  // system
  static const String systemKey = 'system';

  // per habit override
  static const String inheritKey = '__inherit__';

  /// Order the picker presents options in: App Default first, then System
  /// Default, then the remaining stock sounds (the App Default sound is not
  /// repeated in the numbered list).
  static List<String> get pickerOrder => [
    defaultKey,
    systemKey,
    ...numberedKeys,
  ];

  /// The stock sounds shown as the numbered list ("Sound 1", "Sound 2", …):
  /// every sound except the App Default. Their displayed number is their
  /// POSITION here (1-based), not their filename — so the list stays contiguous
  /// no matter which file is the App Default.
  static List<String> get numberedKeys =>
      keys.where((k) => k != defaultKey).toList();

  /// 1-based position of a numbered sound, or null if it isn't one.
  static int? numberFor(String key) {
    final index = numberedKeys.indexOf(key);
    return index < 0 ? null : index + 1;
  }

  static bool isValidKey(String? key) =>
      key != null && (keys.contains(key) || key == systemKey);

  /// Whether a key refers to a bundled asset that can be previewed in-app.
  /// (System Default and the inherit sentinel have no asset to preview.)
  static bool isPreviewable(String? key) => key != null && keys.contains(key);

  /// Normalizes any stored value to a concrete, valid sound key.
  static String resolveOrDefault(String? key) =>
      isValidKey(key) ? key! : defaultKey;

  /// Asset path used by the in-app preview player.
  static String assetPath(String key) => 'assets/sound/$key.mp3';

  /// Asset path as required by `audioplayers` AssetSource (no `assets/` prefix).
  static String assetSourcePath(String key) => 'sound/$key.mp3';

  /// Android raw resource URI consumed by the notification channel.
  static String resource(String key) => 'resource://raw/$key';

  /// Channel key for a given sound. One channel per sound (Android binds sound
  /// to the channel, not the individual notification). "System Default" routes
  /// to the always-present `basic_channel`, which has no custom sound and so
  /// plays the OS default — this avoids depending on a separate channel being
  /// created on existing installs.
  static const String systemChannelKey = 'basic_channel';
  static String channelKey(String key) =>
      key == systemKey ? systemChannelKey : 'habit_$key';

  /// Channel key for the effective sound, with null/invalid falling back to default.
  static String channelForKeyOrDefault(String? key) =>
      channelKey(resolveOrDefault(key));
}
