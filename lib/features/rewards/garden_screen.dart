import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../core/strings_ar.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/kid_button.dart';
import '../../core/widgets/mascot.dart';
import '../../progress/profiles_store.dart';

const _flowers = [
  'tulip',
  'sunflower',
  'blossom',
  'hibiscus',
  'rose',
  'cherry_blossom',
  'lotus',
];

/// The flower that grows for the [n]th day of play.
String flowerFor(int n) =>
    'assets/images/garden/${_flowers[n % _flowers.length]}.svg';

/// One flower for every day the child played. Missed days leave no gap and
/// nothing ever wilts: the garden only grows.
class GardenScreen extends StatelessWidget {
  const GardenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final days = (context.watch<ProfilesStore>().current!.playDays.toList()
      ..sort());

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  KidButton(
                    key: const ValueKey('garden-back'),
                    icon: Icons.arrow_back_rounded,
                    color: AppColors.sky,
                    width: 80,
                    height: 64,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: Text(Ar.garden, style: AppText.title)),
                  SvgPicture.asset(flowerFor(0), width: 36),
                  const SizedBox(width: AppSpacing.xs),
                  Text('${days.length}', style: AppText.title),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: MascotSays(
                text: days.isEmpty ? Ar.gardenEmpty : Ar.gardenHint,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.leaf.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppColors.leaf, width: 4),
                ),
                child: days.isEmpty
                    ? Center(
                        child: SvgPicture.asset(
                          'assets/images/garden/seedling.svg',
                          width: 96,
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          spacing: AppSpacing.md,
                          runSpacing: AppSpacing.lg,
                          children: [
                            for (var i = 0; i < days.length; i++)
                              Transform.translate(
                                offset: Offset(0, math.sin(i * 2.3) * 6),
                                child: SvgPicture.asset(
                                  flowerFor(i),
                                  width: 64 + (i % 3) * 8.0,
                                ),
                              ),
                          ],
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
