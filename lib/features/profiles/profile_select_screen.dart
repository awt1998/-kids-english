import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../audio/audio_service.dart';
import '../../core/strings_ar.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/prompt_on_open.dart';
import '../../core/widgets/mascot.dart';
import '../../progress/child_profile.dart';
import '../../progress/profiles_store.dart';
import '../map/map_screen.dart';
import '../parents/parent_zone_screen.dart';
import '../parents/parental_gate.dart';
import 'add_child_screen.dart';

/// "Who is playing today?" — pick a child by their avatar picture.
class ProfileSelectScreen extends StatelessWidget {
  const ProfileSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ProfilesStore>();

    void open(ChildProfile child) {
      context.read<AudioService>().playSfx(Sfx.tap);
      store.select(child);
      Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (_) => const MapScreen()));
    }

    Future<void> add() async {
      context.read<AudioService>().playSfx(Sfx.tap);
      if (!await passParentalGate(context) || !context.mounted) return;
      Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => const AddChildScreen()));
    }

    Future<void> parents() async {
      if (!await passParentalGate(context) || !context.mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          settings: const RouteSettings(name: 'parents'),
          builder: (_) => const ParentZoneScreen(),
        ),
      );
    }

    return PromptOnOpen(
      prompts: const [Prompt.whoIsPlaying],
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      children: [
                        const Mascot(size: 160),
                        Text(
                          Ar.whoIsPlaying,
                          style: AppText.display,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: AppSpacing.lg,
                          runSpacing: AppSpacing.lg,
                          children: [
                            for (final child in store.children)
                              _AvatarTile(
                                key: ValueKey(child.id),
                                onTap: () => open(child),
                                label: child.name,
                                child: SvgPicture.asset(
                                  child.avatarPath,
                                  width: 100,
                                  height: 100,
                                ),
                              ),
                            if (store.canAddChild)
                              _AvatarTile(
                                key: const ValueKey('add'),
                                onTap: add,
                                label: Ar.addChild,
                                dashed: true,
                                child: const Icon(
                                  Icons.add_rounded,
                                  size: 72,
                                  color: AppColors.mint,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              PositionedDirectional(
                top: AppSpacing.sm,
                end: AppSpacing.sm,
                child: TextButton.icon(
                  key: const ValueKey('open-parents'),
                  style: TextButton.styleFrom(minimumSize: const Size(120, 64)),
                  icon: const Icon(
                    Icons.lock_rounded,
                    color: AppColors.inkSoft,
                  ),
                  label: Text(Ar.forParents, style: AppText.caption),
                  onPressed: parents,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvatarTile extends StatelessWidget {
  const _AvatarTile({
    super.key,
    required this.onTap,
    required this.child,
    this.label = '',
    this.dashed = false,
  });

  final VoidCallback onTap;
  final Widget child;
  final String label;
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 140,
            height: 140,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: dashed ? AppColors.surfaceSoft : AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(
                color: dashed ? AppColors.mint : AppColors.outline,
                width: 5,
              ),
            ),
            child: Center(child: child),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: AppText.body,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
