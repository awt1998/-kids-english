import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

enum Sfx { tap, flip, correct, tryAgain, star, celebrate }

/// Arabic spoken instructions, recorded in `assets/audio/ar/<snake_case>.mp3`
/// (texts in `assets/content/prompts_ar.json`). A missing recording is a
/// silent no-op, so the app works before every recording exists.
enum Prompt {
  welcome,
  whoIsPlaying,
  pickAvatar,
  pickLesson,
  locked,
  tapToFlip,
  listenAndChoose,
  tryAgain,
  correct,
  wellDone,
  newSticker,
  popBubbles,
  memoryGame,
  matchWord,
  spellWord,
  traceLetter,
  orderSentence,
  missingLetter,
  timeUp,
  comeBack,
  gardenFlower,
  askParent,
}

/// Asset path of a prompt's recording, e.g. `audio/ar/who_is_playing.mp3`.
String promptAsset(Prompt p) =>
    'audio/ar/${p.name.replaceAllMapped(RegExp('[A-Z]'), (m) => '_${m[0]!.toLowerCase()}')}.mp3';

/// Plays all app sound: word pronunciation, Arabic prompts and effects.
abstract class AudioService {
  Future<void> playWord(String assetPath);
  Future<void> playPrompt(Prompt prompt);

  /// Plays a prompt and completes when it has finished (or could not play),
  /// so the next sound does not cut it off.
  Future<void> playPromptAndWait(Prompt prompt);
  Future<void> playSfx(Sfx sfx);
  Future<void> stopVoice();

  /// Quiet background loop for menus and the map. Never plays during a game.
  Future<void> setMusicPlaying(bool playing);
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

  static const _musicVolume = 0.18;

  final _voice = AudioPlayer();
  final _music = AudioPlayer()..setReleaseMode(ReleaseMode.loop);
  bool _musicOn = false;
  final _sfx = {
    for (final s in Sfx.values)
      s: AudioPlayer()..setPlayerMode(PlayerMode.lowLatency),
  };

  static String _sfxFile(Sfx s) => switch (s) {
    Sfx.tryAgain => 'audio/sfx/try_again.mp3',
    _ => 'audio/sfx/${s.name}.mp3',
  };

  static String _promptFile(Prompt p) => promptAsset(p);

  @override
  Future<void> playWord(String assetPath) => _play(_voice, assetPath);

  @override
  Future<void> playPrompt(Prompt prompt) => _play(_voice, _promptFile(prompt));

  @override
  Future<void> playPromptAndWait(Prompt prompt) async {
    final finished = _voice.onPlayerComplete.first;
    if (!await _play(_voice, _promptFile(prompt))) return;
    // Never hang a game on audio: no prompt is longer than a few seconds.
    await finished.timeout(const Duration(seconds: 8), onTimeout: () {});
  }

  @override
  Future<void> playSfx(Sfx sfx) => _play(_sfx[sfx]!, _sfxFile(sfx));

  @override
  Future<void> stopVoice() => _voice.stop();

  @override
  Future<void> setMusicPlaying(bool playing) async {
    if (playing == _musicOn) return;
    _musicOn = playing;
    try {
      if (playing) {
        await _music.setVolume(_musicVolume);
        await _music.play(AssetSource('audio/music/calm_loop.wav'));
      } else {
        await _music.pause();
      }
    } catch (e) {
      debugPrint('audio: music failed: $e');
    }
  }

  /// True when the sound started. Missing or failing sound never breaks a game.
  Future<bool> _play(AudioPlayer player, String path) async {
    try {
      await player.stop();
      await player.play(AssetSource(path));
      return true;
    } catch (e) {
      debugPrint('audio: could not play $path: $e');
      return false;
    }
  }

  @override
  void dispose() {
    _voice.dispose();
    _music.dispose();
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
  Future<void> playPromptAndWait(Prompt prompt) => playPrompt(prompt);
  @override
  Future<void> playSfx(Sfx sfx) async => played.add('sfx:${sfx.name}');
  @override
  Future<void> stopVoice() async {}

  bool musicPlaying = false;
  @override
  Future<void> setMusicPlaying(bool playing) async => musicPlaying = playing;
  @override
  void dispose() {}
}
