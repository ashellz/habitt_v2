import 'package:audioplayers/audioplayers.dart';

/// Plays the short "habit completed" sound.
///
/// Uses a sonification/ambient audio context so it mixes with whatever the
/// user is listening to (no audio-focus grab on Android) and respects the
/// iOS silent switch.
class CompletionSoundPlayer {
  CompletionSoundPlayer._();
  static final CompletionSoundPlayer instance = CompletionSoundPlayer._();

  // Placeholder: reuses a stock notification tone until a dedicated
  // completion sound asset is added.
  static const String _assetSourcePath = 'sound/sound_02.mp3';

  final AudioPlayer _player = AudioPlayer(playerId: 'completion_sound');
  bool _configured = false;

  Future<void> play() async {
    try {
      if (!_configured) {
        await _player.setAudioContext(
          AudioContext(
            android: const AudioContextAndroid(
              contentType: AndroidContentType.sonification,
              usageType: AndroidUsageType.assistanceSonification,
              audioFocus: AndroidAudioFocus.none,
            ),
            iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient),
          ),
        );
        await _player.setReleaseMode(ReleaseMode.stop);
        _configured = true;
      }
      await _player.stop();
      await _player.play(AssetSource(_assetSourcePath));
    } catch (_) {
      // A sound failure must never break completing a habit.
    }
  }
}
