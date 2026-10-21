import 'package:audioplayers/audioplayers.dart';

/// Uses a ambient audio context so it mixes with whatever the
/// user is listening to (no audio-focus grab on Android) and respects the
/// iOS silent switch.
class CompletionSoundPlayer {
  CompletionSoundPlayer._();
  static final CompletionSoundPlayer instance = CompletionSoundPlayer._();

  static const String _habitAssetPath = 'sound/completion.mp3';
  static const String _allHabitsAssetPath = 'sound/completion_all.mp3';

  final AudioPlayer _player = AudioPlayer(playerId: 'completion_sound');
  bool _configured = false;

  // plays the sound
  // plays the big sound if allHabitsCompleted is true
  Future<void> play({bool allHabitsCompleted = false}) async {
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
      await _player.play(
        AssetSource(allHabitsCompleted ? _allHabitsAssetPath : _habitAssetPath),
      );
    } catch (_) {
      // A sound failure must never break completing a habit.
    }
  }
}
