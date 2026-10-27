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

/// End of a lesson: confetti, Labeeb dances and the stars pop in one by one.
class CelebrationScreen extends StatefulWidget {
  const CelebrationScreen({super.key, required this.stars});

  final int stars;

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
