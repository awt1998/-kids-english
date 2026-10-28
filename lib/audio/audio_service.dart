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

  /// Plays a prompt and completes when it has finished, so the next sound
  /// (usually the word being asked) never cuts it off.
  ///
  /// Returns false if something else started speaking meanwhile (the child
  /// tapped a card, replayed the word…): the caller then skips what it
  /// planned to say next. A missing recording returns true at once.
  Future<bool> playPromptAndWait(Prompt prompt);
  Future<void> playSfx(Sfx sfx);
  Future<void> stopVoice();

  /// Quiet background loop for menus and the map. Never plays during a game.
  Future<void> setMusicPlaying(bool playing);

  /// Parent settings: sound effects and background music can be switched off.
  /// Words and spoken instructions always play.
  Future<void> applySettings({required bool soundEffects, required bool music});
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

  // Words and Arabic prompts each have their own player, so starting one
  // never depends on the state of the other; only one of them speaks at a time.
  final _voice = AudioPlayer();
  final _prompt = AudioPlayer();
  final _music = AudioPlayer()..setReleaseMode(ReleaseMode.loop);
  bool _musicOn = false;
  final _sfx = {
    for (final s in Sfx.values)
      s: AudioPlayer()..setPlayerMode(PlayerMode.lowLatency),
  };

  /// Increases with every new speech; a wait whose turn has passed was interrupted.
  int _speechTurn = 0;

  static String _sfxFile(Sfx s) => switch (s) {
    Sfx.tryAgain => 'audio/sfx/try_again.mp3',
    _ => 'audio/sfx/${s.name}.mp3',
  };

  @override
  Future<void> playWord(String assetPath) => _speak(_voice, assetPath);

  @override
  Future<void> playPrompt(Prompt prompt) =>
      _speak(_prompt, promptAsset(prompt));

  @override
  Future<bool> playPromptAndWait(Prompt prompt) =>
      _speak(_prompt, promptAsset(prompt), wait: true);

  @override
  Future<void> playSfx(Sfx sfx) async {
    if (!_soundEffects) return;
    final player = _sfx[sfx]!;
    try {
      await player.stop();
      await player.play(AssetSource(_sfxFile(sfx)));
    } catch (e) {
      debugPrint('audio: could not play $sfx: $e');
    }
  }

  @override
  Future<void> stopVoice() async {
    _speechTurn++;
    await Future.wait([_voice.stop(), _prompt.stop()]);
  }

  /// Speaks one clip after silencing any other speech. With [wait], completes
  /// when the clip has played to its end: its real length is read from the
  /// file, so a lost or late "completed" event can never hold up (or rush)
  /// the next sound. Returns false when interrupted by newer speech.
  Future<bool> _speak(
    AudioPlayer player,
    String path, {
    bool wait = false,
  }) async {
    final turn = ++_speechTurn;
    try {
      await Future.wait([_voice.stop(), _prompt.stop()]);
      await player.setSource(AssetSource(path));
      final length = await player.getDuration() ?? const Duration(seconds: 4);
      if (turn != _speechTurn) return false;
      await player.resume();
      if (!wait) return true;
      final clock = Stopwatch()..start();
      final limit = length + const Duration(milliseconds: 250);
      while (clock.elapsed < limit) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        if (turn != _speechTurn) return false;
        // The player says it finished, and enough time has passed for that to be true.
        if (player.state == PlayerState.completed &&
            clock.elapsed > length * 0.8) {
          break;
        }
      }
      return turn == _speechTurn;
    } catch (e) {
      // Missing or failing sound never breaks a game.
      debugPrint('audio: could not play $path: $e');
      return turn == _speechTurn;
    }
  }

  bool _soundEffects = true;
  bool _musicAllowed = true;
  bool _musicWanted = false;

  @override
  Future<void> applySettings({
    required bool soundEffects,
    required bool music,
  }) async {
    _soundEffects = soundEffects;
    _musicAllowed = music;
    await _updateMusic();
  }

  @override
  Future<void> setMusicPlaying(bool playing) async {
    _musicWanted = playing;
    await _updateMusic();
  }

  Future<void> _updateMusic() async {
    final playing = _musicWanted && _musicAllowed;
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

  @override
  void dispose() {
    _voice.dispose();
    _prompt.dispose();
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
  Future<bool> playPromptAndWait(Prompt prompt) async {
    await playPrompt(prompt);
    return !interruptNextWait;
  }

  /// Tests set this to simulate the child tapping while a prompt is spoken.
  bool interruptNextWait = false;
  @override
  Future<void> playSfx(Sfx sfx) async {
    if (soundEffects) played.add('sfx:${sfx.name}');
  }

  @override
  Future<void> stopVoice() async {}

  bool _musicWanted = false;
  bool _musicAllowed = true;
  bool soundEffects = true;
  bool get musicPlaying => _musicWanted && _musicAllowed;
  @override
  Future<void> setMusicPlaying(bool playing) async => _musicWanted = playing;
  @override
  Future<void> applySettings({
    required bool soundEffects,
    required bool music,
  }) async {
    this.soundEffects = soundEffects;
    _musicAllowed = music;
  }

  @override
  void dispose() {}
}
