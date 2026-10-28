import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../audio/audio_service.dart';
import '../../content/models.dart';
import '../../core/strings_ar.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/mascot.dart';
import 'game_common.dart';

/// Pictures on one side, written words on the other: tap a picture, then its word.
class MatchGame extends StatefulWidget {
  const MatchGame({
    super.key,
    this.introduce = true,
    required this.words,
    required this.onDone,
    this.random,
  });

  final List<Word> words;
  final math.Random? random;
  final GameDone onDone;

  /// Say the game's instruction (the first time it appears in a lesson).
  final bool introduce;

  @override
  State<MatchGame> createState() => _MatchGameState();
}

class _MatchGameState extends State<MatchGame> with GameVoice<MatchGame> {
  late final List<Word> _pictures;
  late final List<Word> _labels;
  final _matched = <String>{};
  final _mistakes = <String, int>{};
  final _shakes = <String, int>{};
  Word? _picked;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    final rnd = widget.random ?? math.Random();
    _pictures = [...widget.words]..shuffle(rnd);
    _labels = [...widget.words]..shuffle(rnd);
    if (widget.introduce) audio.playPrompt(Prompt.matchWord);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _pickPicture(Word w) {
    if (_matched.contains(w.id)) return;
    context.read<AudioService>().playSfx(Sfx.tap);
    setState(() => _picked = w);
  }

  void _pickLabel(Word w) {
    final picked = _picked;
    if (_matched.contains(w.id)) return;
    final audio = context.read<AudioService>();
    if (picked == null) {
      // Word first: say it so readers and non-readers both get a clue.
      audio.playWord(w.audioPath);
      setState(
        () => _shakes['label-${w.id}'] = (_shakes['label-${w.id}'] ?? 0) + 1,
      );
      return;
    }
    if (picked == w) {
      audio.playSfx(Sfx.correct);
      _timer = Timer(
        const Duration(milliseconds: 300),
        () => audio.playWord(w.audioPath),
      );
      setState(() {
        _matched.add(w.id);
        _picked = null;
      });
      if (_matched.length == widget.words.length) {
        _timer = Timer(const Duration(milliseconds: 1400), () {
          widget.onDone(
            GameResult(
              mistakesByWord: {
                for (final w in widget.words) w.id: _mistakes[w.id] ?? 0,
              },
            ),
          );
        });
      }
    } else {
      audio.playSfx(Sfx.tryAgain);
      encourage();
      setState(() {
        _mistakes[picked.id] = (_mistakes[picked.id] ?? 0) + 1;
        _shakes['label-${w.id}'] = (_shakes['label-${w.id}'] ?? 0) + 1;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final done = _matched.length == widget.words.length;
    return Column(
      children: [
        MascotSays(
          text: Ar.matchWord,
          pose: done ? MascotPose.cheer : MascotPose.idle,
        ),
        const SizedBox(height: AppSpacing.md),
        Expanded(
          child: LayoutBuilder(
            builder: (context, box) {
              final n = widget.words.length;
              final colWidth = (box.maxWidth - AppSpacing.xl) / 2;
              final size = math
                  .min(colWidth, (box.maxHeight - (n - 1) * AppSpacing.sm) / n)
                  .clamp(64.0, 150.0);
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _column([
                    for (final w in _pictures)
                      AnswerCard(
                        key: ValueKey('pic-${w.id}'),
                        size: size,
                        word: w,
                        selected: _picked == w,
                        solved: _matched.contains(w.id),
                        hint: (_mistakes[w.id] ?? 0) > 0 && _picked == w,
                        onTap: () => _pickPicture(w),
                      ),
                  ]),
                  const SizedBox(width: AppSpacing.xl),
                  _column([
                    for (final w in _labels)
                      AnswerCard(
                        key: ValueKey('label-${w.id}'),
                        size: size,
                        width: math.min(colWidth, size * 1.8),
                        text: w.en,
                        shake: _shakes['label-${w.id}'] ?? 0,
                        solved: _matched.contains(w.id),
                        onTap: () => _pickLabel(w),
                      ),
                  ]),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _column(List<Widget> children) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      for (var i = 0; i < children.length; i++) ...[
        if (i > 0) const SizedBox(height: AppSpacing.sm),
        children[i],
      ],
    ],
  );
}
