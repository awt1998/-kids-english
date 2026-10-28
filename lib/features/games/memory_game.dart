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
import 'game_common.dart';

class _MemoryCard {
  _MemoryCard(this.word, {required this.showText});
  final Word word;
  final bool showText;
  bool faceUp = false;
  bool matched = false;
}

/// Classic pairs game. Little children match picture with picture; readers
/// match a picture with its written word. Pure practice: no mistakes counted.
class MemoryGame extends StatefulWidget {
  const MemoryGame({
    super.key,
    required this.words,
    required this.onDone,
    this.withText = false,
    this.random,
  });

  final List<Word> words;
  final bool withText;
  final math.Random? random;
  final GameDone onDone;

  @override
  State<MemoryGame> createState() => _MemoryGameState();
}

class _MemoryGameState extends State<MemoryGame> {
  late final List<_MemoryCard> _cards;
  final _open = <_MemoryCard>[];
  bool _busy = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _cards = [
      for (final w in widget.words) ...[
        _MemoryCard(w, showText: false),
        _MemoryCard(w, showText: widget.withText),
      ],
    ]..shuffle(widget.random ?? math.Random());
    context.read<AudioService>().playPrompt(Prompt.memoryGame);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _tap(_MemoryCard c) {
    if (_busy || c.faceUp || c.matched) return;
    final audio = context.read<AudioService>();
    audio.playSfx(Sfx.flip);
    setState(() {
      c.faceUp = true;
      _open.add(c);
    });
    if (_open.length < 2) return;

    final [a, b] = _open;
    _open.clear();
    if (a.word == b.word) {
      audio.playSfx(Sfx.correct);
      _timer = Timer(
        const Duration(milliseconds: 350),
        () => audio.playWord(a.word.audioPath),
      );
      setState(() => a.matched = b.matched = true);
      if (_cards.every((c) => c.matched)) {
        _timer = Timer(
          const Duration(milliseconds: 1500),
          () => widget.onDone(const GameResult()),
        );
      }
    } else {
      _busy = true;
      _timer = Timer(const Duration(milliseconds: 1000), () {
        if (!mounted) return;
        setState(() => a.faceUp = b.faceUp = false);
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final done = _cards.every((c) => c.matched);
    return Column(
      children: [
        MascotSays(
          text: Ar.memoryGame,
          pose: done ? MascotPose.cheer : MascotPose.idle,
        ),
        const SizedBox(height: AppSpacing.md),
        Expanded(
          child: LayoutBuilder(
            builder: (context, box) {
              final size = fitCardSize(box, _cards.length, max: 200);
              return Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.md,
                  children: [
                    for (var i = 0; i < _cards.length; i++) _card(i, size),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _card(int i, double size) {
    final c = _cards[i];
    final up = c.faceUp || c.matched;
    return GestureDetector(
      key: ValueKey('memory-$i'),
      onTap: () => _tap(c),
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: up ? 1 : 0),
        duration: const Duration(milliseconds: 300),
        builder: (context, t, _) {
          final showFace = t > 0.5;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0015)
              ..rotateY(math.pi * t),
            child: Transform(
              alignment: Alignment.center,
              transform: showFace
                  ? Matrix4.rotationY(math.pi)
                  : Matrix4.identity(),
              child: Container(
                width: size,
                height: size,
                padding: EdgeInsets.all(size * 0.14),
                decoration: BoxDecoration(
                  color: showFace ? AppColors.surface : AppColors.grape,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: c.matched ? AppColors.success : Colors.white,
                    width: 6,
                  ),
                  boxShadow: const [
                    BoxShadow(color: AppColors.outline, offset: Offset(0, 6)),
                  ],
                ),
                alignment: Alignment.center,
                child: !showFace
                    ? Icon(
                        Icons.star_rounded,
                        color: Colors.white.withValues(alpha: 0.7),
                        size: size * 0.45,
                      )
                    : c.showText
                    ? FittedBox(
                        child: EnglishText(c.word.en, style: AppText.wordSmall),
                      )
                    : SvgPicture.asset(c.word.imagePath),
              ),
            ),
          );
        },
      ),
    );
  }
}
