import 'package:audioplayers/audioplayers.dart';
import 'package:habitt/services/notification_sounds.dart';

/// Plays stock notification sounds in-app for previewing in the picker.
///
/// The notification channels cannot be previewed on demand, so this plays the
/// bundled asset directly. Only one preview plays at a time.
class SoundPreviewPlayer {
  SoundPreviewPlayer._();
  static final SoundPreviewPlayer instance = SoundPreviewPlayer._();

  final AudioPlayer _player = AudioPlayer(playerId: 'sound_preview');

  /// Plays the sound for [key], stopping any sound already previewing.
  Future<void> preview(String key) async {
    if (!NotificationSounds.isValidKey(key)) return;
    await _player.stop();
    await _player.play(AssetSource(NotificationSounds.assetSourcePath(key)));
  }

  Future<void> stop() => _player.stop();

  Future<void> dispose() => _player.dispose();
}
