import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/kid_button.dart';
import '../../core/widgets/mascot.dart';

/// Phase 0 screen: shows the design system and lets the owner compare the
/// mascot candidates. Replaced by the real home in phase 1.
class DesignPreviewScreen extends StatefulWidget {
  const DesignPreviewScreen({super.key});

  @override
  State<DesignPreviewScreen> createState() => _DesignPreviewScreenState();
}

class _DesignPreviewScreenState extends State<DesignPreviewScreen> {
  MascotKind _mascot = MascotKind.fenno;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= tabletBreakpoint;

    final hero = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('أهلاً يا بطل!', style: AppText.display),
        const SizedBox(height: AppSpacing.sm),
        Mascot(kind: _mascot, size: isWide ? 300 : 220),
        Text(_mascot.arabicName, style: AppText.title),
      ],
    );

    final controls = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KidButton(
          label: 'يلا نلعب',
          icon: Icons.play_arrow_rounded,
          onPressed: () {},
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: KidButton(
                icon: Icons.map_rounded,
                color: AppColors.sky,
                onPressed: () {},
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: KidButton(
                icon: Icons.star_rounded,
                color: AppColors.sun,
                onPressed: () {},
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: KidButton(
                icon: Icons.emoji_events_rounded,
                color: AppColors.grape,
                onPressed: () {},
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _WordCardSample(),
        const SizedBox(height: AppSpacing.lg),
        Text('اختر الشخصية:', style: AppText.body, textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final m in MascotKind.values)
              GestureDetector(
                onTap: () => setState(() => _mascot = m),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: m == _mascot ? AppColors.mint : AppColors.outline,
                      width: 4,
                    ),
                  ),
                  child: Mascot(kind: m, size: 72, animate: false),
                ),
              ),
          ],
        ),
      ],
    );

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: isWide
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(child: FittedBox(child: hero)),
                      const SizedBox(width: AppSpacing.xl),
                      Flexible(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 380),
                          child: controls,
                        ),
                      ),
                    ],
                  )
                : ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      children: [
                        hero,
                        const SizedBox(height: AppSpacing.lg),
                        controls,
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _WordCardSample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: const [
          BoxShadow(color: AppColors.outline, offset: Offset(0, 6)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: AppColors.coral,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              'A',
              style: AppText.wordSmall.copyWith(color: Colors.white),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text('Apple', style: AppText.wordSmall),
                ),
                Text('تفاحة', style: AppText.caption),
              ],
            ),
          ),
          const Icon(Icons.volume_up_rounded, size: 40, color: AppColors.sky),
        ],
      ),
    );
  }
}
