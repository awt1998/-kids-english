import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../audio/audio_service.dart';
import '../../content/models.dart';
import '../../core/strings_ar.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/mascot.dart';
import '../../core/widgets/shake.dart';
import 'game_common.dart';

const _alphabet = 'abcdefghijklmnopqrstuvwxyz';

/// A letter box used by the spelling games: empty slot, filled slot or tile.
class _LetterBox extends StatelessWidget {
  const _LetterBox({
    required this.size,
    this.letter,
    this.filled = false,
    this.hint = false,
    this.shake = 0,
    this.onTap,
    super.key,
  });

  final double size;
  final String? letter;
  final bool filled;
  final bool hint;
  final int shake;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isSlot = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: Shake(
        trigger: shake,
        child: Pulse(
          active: hint,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: size,
            height: size * 1.15,
            decoration: BoxDecoration(
              color: isSlot
                  ? (filled ? AppColors.success : AppColors.surfaceSoft)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(
                color: hint
                    ? AppColors.hint
                    : (isSlot ? AppColors.outline : AppColors.sky),
                width: hint ? 5 : 3,
              ),
              boxShadow: isSlot
                  ? null
                  : const [
                      BoxShadow(color: AppColors.outline, offset: Offset(0, 5)),
                    ],
            ),
            alignment: Alignment.center,
            child: letter == null
                ? null
                : EnglishText(
                    letter!,
                    style: AppText.wordSmall.copyWith(
                      fontSize: size * 0.6,
                      color: isSlot && filled ? Colors.white : AppColors.ink,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

double _boxSize(double width, int count) => math
    .min((width - (count - 1) * AppSpacing.sm) / count, 72.0)
    .clamp(36.0, 72.0);

/// Picture + the word with one letter missing; pick the letter from three.
class MissingLetterGame extends StatefulWidget {
  const MissingLetterGame({
    super.key,
    required this.word,
    required this.onDone,
    this.random,
  });

  final Word word;
  final math.Random? random;
  final GameDone onDone;

  @override
  State<MissingLetterGame> createState() => _MissingLetterGameState();
}

class _MissingLetterGameState extends State<MissingLetterGame> {
  late final int _gap;
  late final List<String> _choices;
  final _shakes = <String, int>{};
  var _wrong = 0;
  var _solved = false;
  Timer? _timer;

  String get _answer => widget.word.en[_gap];

  @override
  void initState() {
    super.initState();
    final rnd = widget.random ?? math.Random();
    final w = widget.word.en;
    _gap = w.length <= 3
        ? rnd.nextInt(w.length)
        : 1 + rnd.nextInt(w.length - 1);
    final others =
        _alphabet
            .split('')
            .where((c) => c != _answer && !w.contains(c))
            .toList()
          ..shuffle(rnd);
    _choices = [_answer, ...others.take(2)]..shuffle(rnd);
    final audio = context.read<AudioService>();
    audio.playPrompt(Prompt.missingLetter);
    _timer = Timer(
      const Duration(milliseconds: 1400),
      () => audio.playWord(widget.word.audioPath),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _pick(String c) {
    if (_solved) return;
    final audio = context.read<AudioService>();
    if (c == _answer) {
      audio.playSfx(Sfx.correct);
      setState(() => _solved = true);
      _timer?.cancel();
      _timer = Timer(
        const Duration(milliseconds: 400),
        () => audio.playWord(widget.word.audioPath),
      );
      Timer(const Duration(milliseconds: 1700), () {
        if (mounted) {
          widget.onDone(GameResult(mistakesByWord: {widget.word.id: _wrong}));
        }
      });
    } else {
      audio.playSfx(Sfx.tryAgain);
      setState(() {
        _wrong++;
        _shakes[c] = (_shakes[c] ?? 0) + 1;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.word.en;
    return Column(
      children: [
        MascotSays(
          text: Ar.missingLetter,
          pose: _solved ? MascotPose.cheer : MascotPose.idle,
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, box) {
              final size = _boxSize(box.maxWidth, w.length);
              return Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: () => context.read<AudioService>().playWord(
                      widget.word.audioPath,
                    ),
                    child: SvgPicture.asset(
                      widget.word.imagePath,
                      height: math.min(box.maxHeight * 0.32, 200),
                    ),
                  ),
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < w.length; i++) ...[
                          if (i > 0) const SizedBox(width: AppSpacing.xs),
                          _LetterBox(
                            size: size,
                            letter: i != _gap || _solved ? w[i] : null,
                            filled: i == _gap && _solved,
                          ),
                        ],
                      ],
                    ),
                  ),
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (final c in _choices) ...[
                          const SizedBox(width: AppSpacing.md),
                          _LetterBox(
                            key: ValueKey('letter-$c'),
                            size: 88,
                            letter: c,
                            shake: _shakes[c] ?? 0,
                            hint: _wrong > 0 && c == _answer && !_solved,
                            onTap: () => _pick(c),
                          ),
                        ],
                        const SizedBox(width: AppSpacing.md),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Spell the whole word: tap the letter tiles in order.
class SpellGame extends StatefulWidget {
  const SpellGame({
    super.key,
    required this.word,
    required this.onDone,
    this.random,
  });

  final Word word;
  final math.Random? random;
  final GameDone onDone;

  @override
  State<SpellGame> createState() => _SpellGameState();
}

class _SpellGameState extends State<SpellGame> {
  /// Tile letters in their shuffled order; null once used.
  late final List<String?> _tiles;
  final _shakes = <int, int>{};
  var _next = 0;
  var _wrong = 0;
  var _wrongHere = 0;
  Timer? _timer;

  String get _w => widget.word.en;
  bool get _done => _next >= _w.length;

  @override
  void initState() {
    super.initState();
    final rnd = widget.random ?? math.Random();
    final letters = _w.split('');
    do {
      letters.shuffle(rnd);
    } while (letters.length > 1 && letters.join() == _w);
    _tiles = List<String?>.of(letters);
    final audio = context.read<AudioService>();
    audio.playPrompt(Prompt.spellWord);
    _timer = Timer(
      const Duration(milliseconds: 1400),
      () => audio.playWord(widget.word.audioPath),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _tap(int i) {
    final c = _tiles[i];
    if (c == null || _done) return;
    final audio = context.read<AudioService>();
    if (c == _w[_next]) {
      audio.playSfx(Sfx.tap);
      setState(() {
        _tiles[i] = null;
        _next++;
        _wrongHere = 0;
      });
      if (_done) {
        audio.playSfx(Sfx.correct);
        _timer?.cancel();
        _timer = Timer(
          const Duration(milliseconds: 500),
          () => audio.playWord(widget.word.audioPath),
        );
        Timer(const Duration(milliseconds: 1800), () {
          if (mounted) {
            widget.onDone(GameResult(mistakesByWord: {widget.word.id: _wrong}));
          }
        });
      }
    } else {
      audio.playSfx(Sfx.tryAgain);
      setState(() {
        _wrong++;
        _wrongHere++;
        _shakes[i] = (_shakes[i] ?? 0) + 1;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // After a mistake, the next correct tile glows.
    final hintIndex = _wrongHere > 0 && !_done ? _tiles.indexOf(_w[_next]) : -1;
    return Column(
      children: [
        MascotSays(
          text: Ar.spellWord,
          pose: _done ? MascotPose.cheer : MascotPose.idle,
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, box) {
              final size = _boxSize(box.maxWidth, _w.length);
              final tile = math.min(size * 1.15, 80.0);
              return Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: () => context.read<AudioService>().playWord(
                      widget.word.audioPath,
                    ),
                    child: SvgPicture.asset(
                      widget.word.imagePath,
                      height: math.min(box.maxHeight * 0.3, 190),
                    ),
                  ),
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < _w.length; i++) ...[
                          if (i > 0) const SizedBox(width: AppSpacing.xs),
                          _LetterBox(
                            size: size,
                            letter: i < _next ? _w[i] : null,
                            filled: i < _next,
                          ),
                        ],
                      ],
                    ),
                  ),
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        for (var i = 0; i < _tiles.length; i++)
                          AnimatedOpacity(
                            duration: const Duration(milliseconds: 200),
                            opacity: _tiles[i] == null ? 0 : 1,
                            child: _LetterBox(
                              key: ValueKey('tile-$i'),
                              size: tile,
                              letter: _tiles[i] ?? ' ',
                              shake: _shakes[i] ?? 0,
                              hint: i == hintIndex,
                              onTap: () => _tap(i),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
