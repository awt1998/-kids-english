import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../audio/audio_service.dart';
import '../../content/content_repository.dart';
import '../../content/models.dart';
import '../../core/strings_ar.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/kid_button.dart';
import '../../progress/child_profile.dart';
import '../../progress/profiles_store.dart';
import '../../progress/srs.dart';
import '../games/game_common.dart';

/// One child's progress for a parent: what they learned, how long they
/// played, which words need practice. Also where the age group is changed
/// and the child can be removed.
class ChildReportScreen extends StatefulWidget {
  const ChildReportScreen({super.key, required this.child});

  final ChildProfile child;

  @override
  State<ChildReportScreen> createState() => _ChildReportScreenState();
}

class _ChildReportScreenState extends State<ChildReportScreen> {
  bool _confirmDelete = false;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ProfilesStore>();
    final content = context.read<ContentRepository>();
    final child = widget.child;
    final today = dayNumber(store.now());
    final byId = {
      for (final w in content.units.expand((u) => u.words)) w.id: w,
    };
    final hard = [for (final id in child.hardWordIds()) ?byId[id]];

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Row(
              children: [
                KidButton(
                  key: const ValueKey('report-back'),
                  icon: Icons.arrow_back_rounded,
                  color: AppColors.sky,
                  width: 72,
                  height: 64,
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: AppSpacing.md),
                SvgPicture.asset(child.avatarPath, width: 48, height: 48),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    child.name.isEmpty ? child.level.ageLabel : child.name,
                    style: AppText.title,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _Stat(
                  value: child.wordsLearned,
                  label: Ar.wordsLearned,
                  color: AppColors.mint,
                ),
                _Stat(
                  value: child.wordsMastered,
                  label: Ar.wordsMastered,
                  color: AppColors.leaf,
                ),
                _Stat(
                  value: child.totalStars,
                  label: Ar.stars,
                  color: AppColors.sun,
                ),
                _Stat(
                  value: child.playDays.length,
                  label: Ar.daysPlayed,
                  color: AppColors.grape,
                ),
                _Stat(
                  value: child.secondsOn(today) ~/ 60,
                  label: '${Ar.minutes} ${Ar.today}',
                  color: AppColors.sky,
                ),
                _Stat(
                  value: child.secondsThisWeek(today) ~/ 60,
                  label: '${Ar.minutes} · ${Ar.thisWeek}',
                  color: AppColors.coral,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(Ar.hardWords, style: AppText.title),
            const SizedBox(height: AppSpacing.sm),
            if (hard.isEmpty)
              Text(Ar.noHardWords, style: AppText.caption)
            else
              for (final w in hard)
                _HardWord(word: w, stats: child.words[w.id]!),
            const SizedBox(height: AppSpacing.xl),
            Text(Ar.ageGroup, style: AppText.title),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                for (final level in AgeLevel.values)
                  ChoiceChip(
                    key: ValueKey('report-level-${level.name}'),
                    label: Text(
                      '${level.ageLabel} ${Ar.years}',
                      style: AppText.body,
                    ),
                    selected: child.level == level,
                    onSelected: (_) => store.updateChild(child, level: level),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            if (_confirmDelete)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Text(Ar.deleteConfirm, style: AppText.caption),
              ),
            OutlinedButton.icon(
              key: const ValueKey('report-delete'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(64),
                foregroundColor: AppColors.inkSoft,
              ),
              icon: const Icon(Icons.delete_outline_rounded),
              label: Text(Ar.deleteChild, style: AppText.body),
              onPressed: () async {
                if (!_confirmDelete) {
                  setState(() => _confirmDelete = true);
                  return;
                }
                await store.removeChild(child);
                if (context.mounted) Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, required this.color});

  final int value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$value', style: AppText.display.copyWith(fontSize: 32)),
          Text(label, style: AppText.caption),
        ],
      ),
    );
  }
}

class _HardWord extends StatelessWidget {
  const _HardWord({required this.word, required this.stats});

  final Word word;
  final WordStats stats;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      minTileHeight: 64,
      leading: SvgPicture.asset(word.imagePath, width: 40, height: 40),
      title: EnglishText(
        word.en,
        style: AppText.body,
        textAlign: TextAlign.start,
      ),
      subtitle: Text(word.ar, style: AppText.caption),
      trailing: IconButton(
        iconSize: 32,
        constraints: const BoxConstraints(minWidth: 64, minHeight: 64),
        icon: const Icon(Icons.volume_up_rounded, color: AppColors.sky),
        onPressed: () => context.read<AudioService>().playWord(word.audioPath),
      ),
    );
  }
}
