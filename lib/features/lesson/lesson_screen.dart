import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../audio/audio_service.dart';
import '../../content/models.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/kid_button.dart';
import '../../progress/profiles_store.dart';
import '../../progress/progress_rules.dart';
import 'celebration_screen.dart';
import 'flashcard_game.dart';
import 'lesson_plan.dart';
import 'listen_choose_game.dart';

/// Runs one lesson: a few flashcards then listen-and-choose rounds.
class LessonScreen extends StatefulWidget {
  const LessonScreen({super.key, required this.lesson, this.plan});

  final Lesson lesson;

  /// Injected in tests for a deterministic order.
  final LessonPlan? plan;

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  late final LessonPlan _plan =
      widget.plan ??
      LessonPlan(
        widget.lesson,
        level: context.read<ProfilesStore>().current!.level,
      );

  Future<void> _next({int wrongTries = 0}) async {
    setState(() => _plan.complete(wrongTries: wrongTries));
    if (!_plan.isFinished) return;

    final stars = starsFor(mistakes: _plan.mistakes);
    await context.read<ProfilesStore>().recordLesson(
      lesson: widget.lesson,
      stars: stars,
      correctByWord: _plan.correctByWord,
      wrongByWord: _plan.wrongByWord,
    );
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => CelebrationScreen(stars: stars)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_plan.isFinished) return const Scaffold();
    final step = _plan.current;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              Row(
                children: [
                  KidButton(
                    key: const ValueKey('close-lesson'),
                    icon: Icons.close_rounded,
                    color: AppColors.coral,
                    width: 72,
                    height: 64,
                    onPressed: () {
                      context.read<AudioService>().stopVoice();
                      Navigator.of(context).pop();
                    },
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: _ProgressBar(value: _plan.progress)),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: switch (step.kind) {
                  StepKind.flashcard => FlashcardGame(
                    key: ValueKey('card-${_plan.index}'),
                    word: step.word,
                    onDone: _next,
                  ),
                  StepKind.listenChoose => ListenChooseGame(
                    key: ValueKey('quiz-${_plan.index}'),
                    target: step.word,
                    options: step.options,
                    onDone: (wrong) => _next(wrongTries: wrong),
                  ),
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: LayoutBuilder(
        builder: (context, box) => Align(
          alignment: AlignmentDirectional.centerStart,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutBack,
            width: (box.maxWidth * value).clamp(18.0, box.maxWidth),
            decoration: BoxDecoration(
              color: AppColors.leaf,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),
        ),
      ),
    );
  }
}
