import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../audio/audio_service.dart';
import '../../content/content_repository.dart';
import '../../content/models.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/kid_button.dart';
import '../../progress/profiles_store.dart';
import '../../progress/progress_rules.dart';
import '../../progress/srs.dart';
import '../games/bubble_pop_game.dart';
import '../games/game_common.dart';
import '../games/letter_games.dart';
import '../games/match_game.dart';
import '../games/memory_game.dart';
import '../games/order_sentence_game.dart';
import '../games/trace_game.dart';
import 'celebration_screen.dart';
import 'flashcard_game.dart';
import 'lesson_plan.dart';
import 'listen_choose_game.dart';

/// Runs one lesson: the games chosen by [LessonPlan], then the celebration.
class LessonScreen extends StatefulWidget {
  const LessonScreen({super.key, required this.lesson, this.plan});

  final Lesson lesson;

  /// Injected in tests for a deterministic order.
  final LessonPlan? plan;

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  late final LessonPlan _plan = widget.plan ?? _makePlan();

  LessonPlan _makePlan() {
    final store = context.read<ProfilesStore>();
    final child = store.current!;
    final today = dayNumber(store.now());
    final content = context.read<ContentRepository>();
    final lesson = widget.lesson.kind == LessonKind.review
        // Reviews start with the words spaced repetition says are due or weakest.
        ? Lesson(
            unit: widget.lesson.unit,
            index: widget.lesson.index,
            kind: LessonKind.review,
            words: Srs.reviewOrder(child, widget.lesson.words, today: today),
          )
        : widget.lesson;
    final earlier = content
        .unitsFor(child.level)
        .expand((u) => u.words)
        .where(
          (w) => !lesson.words.contains(w) && child.words.containsKey(w.id),
        );
    return LessonPlan(
      lesson,
      level: child.level,
      reviewWords: lesson.kind == LessonKind.learn
          ? Srs.dueWords(child, earlier, today: today)
          : const [],
    );
  }

  Future<void> _next(GameResult result) async {
    setState(() => _plan.complete(result));
    if (!_plan.isFinished) return;

    final stars = starsFor(mistakes: _plan.mistakes);
    final reward = await context.read<ProfilesStore>().recordLesson(
      lesson: widget.lesson,
      stars: stars,
      mistakesByWord: _plan.mistakesByWord,
    );
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: 'celebration'),
        builder: (_) => CelebrationScreen(stars: stars, reward: reward),
      ),
    );
  }

  Widget _game(LessonStep step) {
    final key = ValueKey('step-${_plan.index}');
    final level = _plan.level;
    return switch (step.kind) {
      StepKind.flashcard => FlashcardGame(
        key: key,
        word: step.word!,
        onDone: () => _next(const GameResult()),
      ),
      StepKind.listenChoose => ListenChooseGame(
        key: key,
        target: step.word!,
        options: step.options,
        onDone: (wrong) =>
            _next(GameResult(mistakesByWord: {step.word!.id: wrong})),
      ),
      StepKind.bubblePop => BubblePopGame(
        key: key,
        target: step.word!,
        options: step.options,
        showText:
            level != AgeLevel.little && widget.lesson.unit.id != 'alphabet',
        onDone: _next,
      ),
      StepKind.memory => MemoryGame(
        key: key,
        words: step.words,
        withText: level != AgeLevel.little,
        onDone: _next,
      ),
      StepKind.match => MatchGame(key: key, words: step.words, onDone: _next),
      StepKind.missingLetter => MissingLetterGame(
        key: key,
        word: step.word!,
        onDone: _next,
      ),
      StepKind.spell => SpellGame(key: key, word: step.word!, onDone: _next),
      StepKind.trace => TraceGame(
        key: key,
        letterWord: step.word!,
        lowercase: level != AgeLevel.little,
        onDone: _next,
      ),
      StepKind.orderSentence => OrderSentenceGame(
        key: key,
        sentence: step.sentence!,
        onDone: _next,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_plan.isFinished) return const Scaffold();

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
              Expanded(child: _game(_plan.current)),
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
