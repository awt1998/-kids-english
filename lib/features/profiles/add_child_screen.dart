import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../audio/audio_service.dart';
import '../../content/models.dart';
import '../../core/strings_ar.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/kid_button.dart';
import '../../progress/profiles_store.dart';
import '../map/map_screen.dart';

const avatars = [
  'cat',
  'rabbit',
  'panda',
  'lion',
  'tiger',
  'koala',
  'frog',
  'chick',
];

/// Create a child profile: picture, age group and an optional name.
// TODO(phase 4): move behind the parental gate once the Parent Zone exists.
class AddChildScreen extends StatefulWidget {
  const AddChildScreen({super.key});

  @override
  State<AddChildScreen> createState() => _AddChildScreenState();
}

class _AddChildScreenState extends State<AddChildScreen> {
  String? _avatar;
  AgeLevel? _level;
  final _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final store = context.read<ProfilesStore>();
    await store.addChild(avatar: _avatar!, level: _level!, name: _name.text);
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const MapScreen()),
      (route) => route.isFirst,
    );
  }

  void _tap(VoidCallback change) {
    context.read<AudioService>().playSfx(Sfx.tap);
    setState(change);
  }

  @override
  Widget build(BuildContext context) {
    final canGoBack = Navigator.of(context).canPop();
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (canGoBack)
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: KidButton(
                        icon: Icons.arrow_back_rounded,
                        color: AppColors.sky,
                        width: 88,
                        height: 64,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  Text(
                    Ar.pickAvatar,
                    style: AppText.title,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.md,
                    children: [
                      for (final a in avatars)
                        GestureDetector(
                          key: ValueKey('avatar-$a'),
                          onTap: () => _tap(() => _avatar = a),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 104,
                            height: 104,
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _avatar == a
                                    ? AppColors.mint
                                    : AppColors.outline,
                                width: _avatar == a ? 7 : 4,
                              ),
                            ),
                            child: SvgPicture.asset(
                              'assets/images/avatars/$a.svg',
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    Ar.pickAge,
                    style: AppText.title,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      for (final level in AgeLevel.values) ...[
                        if (level != AgeLevel.values.first)
                          const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: GestureDetector(
                            key: ValueKey('level-${level.name}'),
                            onTap: () => _tap(() => _level = level),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              height: 110,
                              decoration: BoxDecoration(
                                color: _level == level
                                    ? AppColors.sun
                                    : AppColors.surface,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.md,
                                ),
                                border: Border.all(
                                  color: _level == level
                                      ? AppColors.edgeFor(AppColors.sun)
                                      : AppColors.outline,
                                  width: 4,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(level.ageLabel, style: AppText.title),
                                  Text(Ar.years, style: AppText.caption),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  TextField(
                    controller: _name,
                    maxLength: 20,
                    textAlign: TextAlign.center,
                    style: AppText.title,
                    decoration: InputDecoration(
                      hintText: Ar.nameOptional,
                      hintStyle: AppText.body.copyWith(
                        color: AppColors.inkSoft,
                      ),
                      counterText: '',
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  KidButton(
                    key: const ValueKey('save-child'),
                    label: Ar.start,
                    icon: Icons.play_arrow_rounded,
                    onPressed: _avatar != null && _level != null ? _save : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
