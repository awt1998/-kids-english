import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../core/strings_ar.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/kid_button.dart';
import '../../progress/app_settings.dart';
import '../../progress/child_profile.dart';
import '../../progress/profiles_store.dart';
import '../../progress/srs.dart';
import '../profiles/add_child_screen.dart';
import 'child_report_screen.dart';

/// Settings and reports for parents. Only reachable through the parental gate.
class ParentZoneScreen extends StatelessWidget {
  const ParentZoneScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ProfilesStore>();
    final settings = context.watch<AppSettings>();
    final today = dayNumber(store.now());

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Row(
              children: [
                KidButton(
                  key: const ValueKey('parents-close'),
                  icon: Icons.close_rounded,
                  color: AppColors.coral,
                  width: 72,
                  height: 64,
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: AppSpacing.md),
                Text(Ar.parentZone, style: AppText.title),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _Section(
              title: Ar.children,
              children: [
                for (final child in store.children)
                  _ChildRow(
                    child: child,
                    minutesToday: child.secondsOn(today) ~/ 60,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ChildReportScreen(child: child),
                      ),
                    ),
                  ),
                if (store.canAddChild)
                  ListTile(
                    key: const ValueKey('parents-add-child'),
                    minTileHeight: 64,
                    leading: const Icon(
                      Icons.add_circle_rounded,
                      color: AppColors.mint,
                      size: 40,
                    ),
                    title: Text(Ar.addChild, style: AppText.body),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const AddChildScreen(),
                      ),
                    ),
                  ),
              ],
            ),
            _Section(
              title: Ar.settings,
              children: [
                SwitchListTile(
                  key: const ValueKey('setting-sfx'),
                  title: Text(Ar.soundEffects, style: AppText.body),
                  value: settings.soundEffects,
                  onChanged: settings.setSoundEffects,
                ),
                SwitchListTile(
                  key: const ValueKey('setting-music'),
                  title: Text(Ar.backgroundMusic, style: AppText.body),
                  value: settings.music,
                  onChanged: settings.setMusic,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(Ar.dailyLimit, style: AppText.body),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          for (final m in AppSettings.limitChoices)
                            ChoiceChip(
                              key: ValueKey('limit-$m'),
                              label: Text(
                                m == 0 ? Ar.noLimit : '$m ${Ar.minutes}',
                                style: AppText.body,
                              ),
                              selected: settings.dailyLimitMinutes == m,
                              onSelected: (_) =>
                                  settings.setDailyLimitMinutes(m),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            _Section(
              title: Ar.privacy,
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Text(
                    Ar.privacyText,
                    style: AppText.caption.copyWith(height: 1.6),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(
              start: AppSpacing.sm,
              bottom: AppSpacing.sm,
            ),
            child: Text(title, style: AppText.caption),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            clipBehavior: Clip.antiAlias,
            child: Material(
              type: MaterialType.transparency,
              child: Column(children: children),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChildRow extends StatelessWidget {
  const _ChildRow({
    required this.child,
    required this.minutesToday,
    required this.onTap,
  });

  final ChildProfile child;
  final int minutesToday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: ValueKey('parents-child-${child.id}'),
      minTileHeight: 72,
      leading: SvgPicture.asset(child.avatarPath, width: 48, height: 48),
      title: Text(
        child.name.isEmpty ? child.level.ageLabel : child.name,
        style: AppText.body,
      ),
      subtitle: Text(
        '${child.wordsLearned} ${Ar.wordsLearned} · ${Ar.today} $minutesToday ${Ar.minutes}',
        style: AppText.caption,
      ),
      trailing: const Icon(
        Icons.chevron_left_rounded,
        color: AppColors.inkSoft,
      ),
      onTap: onTap,
    );
  }
}
