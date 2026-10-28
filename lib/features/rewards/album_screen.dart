import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../audio/audio_service.dart';
import '../../content/content_repository.dart';
import '../../core/strings_ar.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/kid_button.dart';
import '../../progress/profiles_store.dart';
import 'sticker.dart';

/// Every word the child has learned, collected as a sticker. Tapping one says the word.
class AlbumScreen extends StatelessWidget {
  const AlbumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final child = context.watch<ProfilesStore>().current!;
    final units = context.read<ContentRepository>().unitsFor(child.level);
    final total = units.fold(0, (a, u) => a + u.words.length);
    final have = units.fold(
      0,
      (a, u) => a + u.words.where((w) => child.stickers.contains(w.id)).length,
    );
    final isWide = MediaQuery.sizeOf(context).width >= tabletBreakpoint;
    final size = isWide ? 104.0 : 84.0;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  KidButton(
                    key: const ValueKey('album-back'),
                    icon: Icons.arrow_back_rounded,
                    color: AppColors.sky,
                    width: 80,
                    height: 64,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: Text(Ar.album, style: AppText.title)),
                  Text('$have ${Ar.outOf} $total', style: AppText.title),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  0,
                  AppSpacing.md,
                  AppSpacing.xxl,
                ),
                children: [
                  for (final unit in units)
                    Container(
                      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: unit.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              SvgPicture.asset(unit.iconPath, width: 40),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(unit.titleAr, style: AppText.title),
                              ),
                              Text(
                                '${unit.words.where((w) => child.stickers.contains(w.id)).length} ${Ar.outOf} ${unit.words.length}',
                                style: AppText.caption,
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.sm,
                            children: [
                              for (final (i, w) in unit.words.indexed)
                                GestureDetector(
                                  key: ValueKey('sticker-${w.id}'),
                                  onTap: child.stickers.contains(w.id)
                                      ? () => context
                                            .read<AudioService>()
                                            .playWord(w.audioPath)
                                      : null,
                                  child: Sticker(
                                    imagePath: w.imagePath,
                                    size: size,
                                    collected: child.stickers.contains(w.id),
                                    tilt: math.sin(i * 1.7) * 0.12,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
