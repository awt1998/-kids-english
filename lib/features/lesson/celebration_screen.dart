import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../audio/audio_service.dart';
import '../../core/strings_ar.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/confetti.dart';
import '../../core/widgets/kid_button.dart';
import '../../core/widgets/mascot.dart';
import '../../progress/profiles_store.dart';
import '../rewards/garden_screen.dart';
import '../rewards/sticker.dart';

/// End of a lesson: confetti, Labeeb dances and the stars pop in one by one.
class CelebrationScreen extends StatefulWidget {
  const CelebrationScreen({
    super.key,
    required this.stars,
    this.reward = const LessonReward(),
  });

  final int stars;
  final LessonReward reward;

  @override
  State<CelebrationScreen> createState() => _CelebrationScreenState();
}

class _CelebrationScreenState extends State<CelebrationScreen> {
  int _shown = 0;
  final _timers = <Timer>[];

  @override
  void initState() {
    super.initState();
    final audio = context.read<AudioService>();
    audio.playSfx(Sfx.celebrate);
    audio.playPrompt(Prompt.wellDone);
    for (var i = 0; i < widget.stars; i++) {
      _timers.add(
        Timer(Duration(milliseconds: 900 + i * 450), () {
          if (!mounted) return;
          audio.playSfx(Sfx.star);
          setState(() => _shown = i + 1);
        }),
      );
    }
    // Spoken news after the stars: new stickers, then today's flower.
    var nextPromptMs = 1500 + widget.stars * 450;
    if (widget.reward.newStickers.isNotEmpty) {
      _timers.add(
        Timer(
          Duration(milliseconds: nextPromptMs),
          () => audio.playPrompt(Prompt.newSticker),
        ),
      );
      nextPromptMs += 3600;
    }
    if (widget.reward.newFlower) {
      _timers.add(
        Timer(
          Duration(milliseconds: nextPromptMs),
          () => audio.playPrompt(Prompt.gardenFlower),
        ),
      );
    }
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  children: [
                    Text(Ar.wellDone, style: AppText.display),
                    const Mascot(pose: MascotPose.cheer, size: 240),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var i = 0; i < 3; i++)
                          AnimatedScale(
                            scale: i < _shown ? 1 : 0.6,
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.elasticOut,
                            child: Opacity(
                              opacity: i < _shown ? 1 : 0.2,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.xs,
                                ),
                                child: SvgPicture.asset(
                                  'assets/images/ui/star.svg',
                                  width: i == 1 ? 96 : 76,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (widget.reward.newStickers.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.lg),
                      Text(Ar.newStickers, style: AppText.title),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          for (final id in widget.reward.newStickers)
                            Sticker(
                              imagePath: 'assets/images/words/$id.svg',
                              size: 76,
                            ),
                        ],
                      ),
                    ],
                    if (widget.reward.newFlower) ...[
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SvgPicture.asset(flowerFor(0), width: 44),
                          const SizedBox(width: AppSpacing.sm),
                          Flexible(
                            child: Text(Ar.newFlower, style: AppText.body),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                    KidButton(
                      key: const ValueKey('continue'),
                      label: Ar.continueLabel,
                      icon: Icons.arrow_forward_rounded,
                      width: 260,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Positioned.fill(child: Confetti()),
        ],
      ),
    );
  }
}
