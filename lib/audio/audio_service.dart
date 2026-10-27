import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

enum Sfx { tap, flip, correct, tryAgain, star, celebrate }

/// Arabic spoken instructions. Recordings arrive in phase 2 under
/// `assets/audio/ar/<name>.mp3`; until then playing one is a silent no-op.
enum Prompt { tapToFlip, listenAndChoose, wellDone, tryAgain }

/// Plays all app sound: word pronunciation, Arabic prompts and effects.
abstract class AudioService {
  Future<void> playWord(String assetPath);
  Future<void> playPrompt(Prompt prompt);
  Future<void> playSfx(Sfx sfx);
  Future<void> stopVoice();
  void dispose();
}

class AudioPlayersService implements AudioService {
  AudioPlayersService() {
    // Kids' parents often leave the silent switch on; a learning app must still speak.
    AudioPlayer.global.setAudioContext(
      AudioContextConfig(
        respectSilence: false,
        focus: AudioContextConfigFocus.mixWithOthers,
      ).build(),
    );
  }

  final _voice = AudioPlayer();
  final _sfx = {
    for (final s in Sfx.values)
      s: AudioPlayer()..setPlayerMode(PlayerMode.lowLatency),
  };

  static String _sfxFile(Sfx s) => switch (s) {
    Sfx.tryAgain => 'audio/sfx/try_again.mp3',
    _ => 'audio/sfx/${s.name}.mp3',
  };

  static String _promptFile(Prompt p) =>
      'audio/ar/${p.name.replaceAllMapped(RegExp('[A-Z]'), (m) => '_${m[0]!.toLowerCase()}')}.mp3';

  @override
  Future<void> playWord(String assetPath) => _play(_voice, assetPath);

  @override
  Future<void> playPrompt(Prompt prompt) => _play(_voice, _promptFile(prompt));

  @override
  Future<void> playSfx(Sfx sfx) => _play(_sfx[sfx]!, _sfxFile(sfx));

  @override
  Future<void> stopVoice() => _voice.stop();

  Future<void> _play(AudioPlayer player, String path) async {
    try {
      await player.stop();
      await player.play(AssetSource(path));
    } catch (e) {
      // Missing or failing sound must never break a game.
      debugPrint('audio: could not play $path: $e');
    }
  }

  @override
  void dispose() {
    _voice.dispose();
    for (final p in _sfx.values) {
      p.dispose();
    }
  }
}

/// Silent implementation for tests.
class SilentAudioService implements AudioService {
  final played = <String>[];

  @override
  Future<void> playWord(String assetPath) async => played.add(assetPath);
  @override
  Future<void> playPrompt(Prompt prompt) async =>
      played.add('prompt:${prompt.name}');
  @override
  Future<void> playSfx(Sfx sfx) async => played.add('sfx:${sfx.name}');
  @override
  Future<void> stopVoice() async {}
  @override
  void dispose() {}
}
