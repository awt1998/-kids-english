import 'package:flutter/material.dart';

import '../../audio/audio_service.dart';
import '../../core/strings_ar.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/kid_button.dart';
import '../../core/widgets/mascot.dart';
import '../../core/widgets/prompt_on_open.dart';
import 'parent_zone_screen.dart';
import 'parental_gate.dart';

/// Shown instead of a new lesson once today's play time is used up.
/// Gentle: Labeeb is sleepy, nothing is lost. A parent can change the limit.
class TimeUpScreen extends StatelessWidget {
  const TimeUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PromptOnOpen(
      prompts: const [Prompt.timeUp],
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  const Mascot(pose: MascotPose.sleep, size: 240),
                  Text(
                    Ar.timeUpTitle,
                    style: AppText.display,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    Ar.timeUpBody,
                    style: AppText.title,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  KidButton(
                    key: const ValueKey('time-up-ok'),
                    icon: Icons.bedtime_rounded,
                    color: AppColors.grape,
                    width: 160,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextButton(
                    key: const ValueKey('time-up-parents'),
                    onPressed: () async {
                      if (await passParentalGate(context) && context.mounted) {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute<void>(
                            settings: const RouteSettings(name: 'parents'),
                            builder: (_) => const ParentZoneScreen(),
                          ),
                        );
                      }
                    },
                    style: TextButton.styleFrom(
                      minimumSize: const Size(140, 64),
                    ),
                    child: Text(Ar.forParents, style: AppText.caption),
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
