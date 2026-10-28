import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../audio/audio_service.dart';
import '../../content/models.dart';
import '../games/game_common.dart';
import '../../core/strings_ar.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/kid_button.dart';
import '../../core/widgets/mascot.dart';
import '../../core/widgets/shake.dart';

/// A big picture card. Tap it: it flips, shows the word and says it.
class FlashcardGame extends StatefulWidget {
  const FlashcardGame({
    super.key,
    this.introduce = true,
    required this.word,
    required this.onDone,
  });

  final Word word;
  final VoidCallback onDone;

  /// Say the game's instruction (the first time it appears in a lesson).
  final bool introduce;

  @override
  State<FlashcardGame> createState() => _FlashcardGameState();
}

class _FlashcardGameState extends State<FlashcardGame>
    with SingleTickerProviderStateMixin, GameVoice<FlashcardGame> {
  late final _flip = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );
  bool _flipped = false;

  @override
  void initState() {
    super.initState();
    if (widget.introduce) audio.playPrompt(Prompt.tapToFlip);
  }

  @override
  void dispose() {
    _flip.dispose();
    super.dispose();
  }

  Future<void> _onCardTap() async {
    final audio = context.read<AudioService>();
    if (!_flipped) {
      setState(() => _flipped = true);
      audio.playSfx(Sfx.flip);
      await _flip.forward();
    }
    audio.playWord(widget.word.audioPath);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final cardSize = math.min(size.shortestSide * 0.72, 420.0);

    return Column(
      children: [
        MascotSays(
          text: Ar.tapToFlip,
          pose: _flipped ? MascotPose.cheer : MascotPose.idle,
        ),
        Expanded(
          child: Center(
            child: GestureDetector(
              key: const ValueKey('flashcard'),
              onTap: _onCardTap,
              child: Pulse(
                active: !_flipped,
                amount: 0.03,
                child: AnimatedBuilder(
                  animation: _flip,
                  builder: (context, _) {
                    final angle = _flip.value * math.pi;
                    final showBack = angle > math.pi / 2;
                    return Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.0012)
                        ..rotateY(angle),
                      child: showBack
                          ? Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.rotationY(math.pi),
                              child: _back(cardSize),
                            )
                          : _front(cardSize),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        AnimatedOpacity(
          opacity: _flipped ? 1 : 0,
          duration: const Duration(milliseconds: 300),
          child: KidButton(
            key: const ValueKey('next'),
            icon: Icons.arrow_forward_rounded,
            width: 200,
            onPressed: _flipped ? widget.onDone : null,
          ),
        ),
      ],
    );
  }

  Widget _card(double size, Color color, Widget child) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      border: Border.all(color: Colors.white, width: 10),
      boxShadow: const [
        BoxShadow(color: AppColors.outline, offset: Offset(0, 10)),
      ],
    ),
    child: child,
  );

  Widget _front(double size) => _card(
    size,
    AppColors.surfaceSoft,
    Stack(
      children: [
        Center(
          child: SvgPicture.asset(widget.word.imagePath, width: size * 0.6),
        ),
        PositionedDirectional(
          bottom: AppSpacing.md,
          end: AppSpacing.md,
          child: Icon(
            Icons.touch_app_rounded,
            size: size * 0.16,
            color: AppColors.sky,
          ),
        ),
      ],
    ),
  );

  Widget _back(double size) => _card(
    size,
    AppColors.surface,
    Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SvgPicture.asset(widget.word.imagePath, width: size * 0.4),
        const SizedBox(height: AppSpacing.md),
        Directionality(
          textDirection: TextDirection.ltr,
          child: Text(widget.word.en, style: AppText.word),
        ),
        Text(
          widget.word.ar,
          style: AppText.body.copyWith(color: AppColors.inkSoft),
        ),
        const SizedBox(height: AppSpacing.sm),
        Icon(Icons.volume_up_rounded, size: size * 0.12, color: AppColors.sky),
      ],
    ),
  );
}
