import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../audio/audio_service.dart';
import '../../content/models.dart';
import '../../core/strings_ar.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/kid_button.dart';
import '../../core/widgets/mascot.dart';
import '../../core/widgets/shake.dart';
import 'game_common.dart';

/// Hear a short sentence and build it by tapping the words in order.
class OrderSentenceGame extends StatefulWidget {
  const OrderSentenceGame({
    super.key,
    required this.sentence,
    required this.onDone,
    this.random,
  });

  final Sentence sentence;
  final math.Random? random;
  final GameDone onDone;

  @override
  State<OrderSentenceGame> createState() => _OrderSentenceGameState();
}

class _OrderSentenceGameState extends State<OrderSentenceGame> {
  late final List<String> _words;
  late final String _ending;
  late final List<String?> _tiles;
  final _shakes = <int, int>{};
  var _next = 0;
  var _wrong = 0;
  var _wrongHere = 0;
  Timer? _timer;

  bool get _done => _next >= _words.length;

  @override
  void initState() {
    super.initState();
    final text = widget.sentence.en.trim();
    _ending = RegExp(r'[.!?]$').hasMatch(text) ? text[text.length - 1] : '';
    _words = text
        .substring(0, text.length - _ending.length)
        .split(RegExp(r'\s+'));
    final rnd = widget.random ?? math.Random();
    final shuffled = [..._words];
    do {
      shuffled.shuffle(rnd);
    } while (shuffled.length > 1 && shuffled.join(' ') == _words.join(' '));
    _tiles = List<String?>.of(shuffled);
    final audio = context.read<AudioService>();
    audio.playPrompt(Prompt.orderSentence);
    _timer = Timer(const Duration(milliseconds: 1500), _say);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _say() =>
      context.read<AudioService>().playWord(widget.sentence.audioPath);

  void _tap(int i) {
    final w = _tiles[i];
    if (w == null || _done) return;
    final audio = context.read<AudioService>();
    // Equal words are interchangeable, so a repeated word can come from either tile.
    if (w == _words[_next]) {
      audio.playSfx(Sfx.tap);
      setState(() {
        _tiles[i] = null;
        _next++;
        _wrongHere = 0;
      });
      if (_done) {
        audio.playSfx(Sfx.correct);
        _timer?.cancel();
        _timer = Timer(const Duration(milliseconds: 500), _say);
        Timer(const Duration(milliseconds: 3000), () {
          if (mounted) widget.onDone(GameResult(extraMistakes: _wrong));
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
    final hint = _wrongHere > 0 && !_done ? _tiles.indexOf(_words[_next]) : -1;
    final built = _words.take(_next).join(' ') + (_done ? _ending : '');
    return Column(
      children: [
        MascotSays(
          text: Ar.orderSentence,
          pose: _done ? MascotPose.cheer : MascotPose.idle,
        ),
        const SizedBox(height: AppSpacing.sm),
        KidButton(
          key: const ValueKey('replay'),
          icon: Icons.volume_up_rounded,
          color: AppColors.sky,
          width: 140,
          height: 80,
          onPressed: _say,
        ),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 96),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: _done ? AppColors.success : AppColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.outline, width: 3),
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    EnglishText(
                      built.isEmpty ? ' ' : built,
                      style: AppText.wordSmall.copyWith(
                        color: _done ? Colors.white : AppColors.ink,
                      ),
                    ),
                    if (_done)
                      Text(
                        widget.sentence.ar,
                        style: AppText.body.copyWith(color: Colors.white),
                      ),
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
                        child: GestureDetector(
                          key: ValueKey('wordtile-$i'),
                          onTap: () => _tap(i),
                          child: Shake(
                            trigger: _shakes[i] ?? 0,
                            child: Pulse(
                              active: i == hint,
                              child: Container(
                                constraints: const BoxConstraints(
                                  minWidth: 80,
                                  minHeight: 64,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.sm,
                                  ),
                                  border: Border.all(
                                    color: i == hint
                                        ? AppColors.hint
                                        : AppColors.sky,
                                    width: 3,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: AppColors.outline,
                                      offset: Offset(0, 5),
                                    ),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: EnglishText(
                                  _tiles[i] ?? '',
                                  style: AppText.wordSmall,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
