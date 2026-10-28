import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../audio/audio_service.dart';
import '../../content/models.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/shake.dart';

/// What a game reports when it ends.
class GameResult {
  const GameResult({this.mistakesByWord = const {}, this.extraMistakes = 0});

  /// Words that were tested and how many wrong taps each needed (0 = right
  /// first time). Feeds stars and spaced repetition. Pure practice games
  /// (memory, tracing) leave it empty.
  final Map<String, int> mistakesByWord;

  /// Mistakes not tied to one word (e.g. ordering a sentence). Counts toward stars only.
  final int extraMistakes;

  int get mistakes =>
      mistakesByWord.values.fold(extraMistakes, (a, b) => a + b);
}

typedef GameDone = void Function(GameResult result);

/// English text, always laid out left-to-right inside the Arabic interface.
class EnglishText extends StatelessWidget {
  const EnglishText(
    this.text, {
    super.key,
    this.style,
    this.textAlign = TextAlign.center,
  });

  final String text;
  final TextStyle? style;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.ltr,
    child: Text(text, style: style ?? AppText.wordSmall, textAlign: textAlign),
  );
}

/// A white rounded card holding a word's picture (or its text), with the
/// three feedback looks every game shares: hint glow, solved, and dimmed.
class AnswerCard extends StatelessWidget {
  const AnswerCard({
    super.key,
    required this.size,
    this.width,
    this.word,
    this.text,
    this.onTap,
    this.shake = 0,
    this.hint = false,
    this.solved = false,
    this.selected = false,
    this.dimmed = false,
  }) : assert(word != null || text != null);

  final double size;

  /// Wider than tall for written words; defaults to a square.
  final double? width;
  final Word? word;
  final String? text;
  final VoidCallback? onTap;
  final int shake;
  final bool hint;
  final bool solved;
  final bool selected;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final border = solved
        ? AppColors.success
        : selected
        ? AppColors.sky
        : hint
        ? AppColors.hint
        : Colors.white;
    return GestureDetector(
      onTap: onTap,
      child: Shake(
        trigger: shake,
        child: Pulse(
          active: hint || solved,
          amount: solved ? 0.08 : 0.05,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 250),
            opacity: dimmed ? 0.45 : 1,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: width ?? size,
              height: size,
              padding: EdgeInsets.all(size * 0.12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: border, width: 7),
                boxShadow: const [
                  BoxShadow(color: AppColors.outline, offset: Offset(0, 7)),
                ],
              ),
              alignment: Alignment.center,
              child: text != null
                  ? FittedBox(child: EnglishText(text!, style: AppText.word))
                  : SvgPicture.asset(
                      word!.imagePath,
                      width: double.infinity,
                      height: double.infinity,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Picks a card size so [count] cards fit the available box.
double fitCardSize(
  BoxConstraints box,
  int count, {
  double min = 90,
  double max = 240,
}) {
  var best = min;
  for (var cols = 1; cols <= count; cols++) {
    final rows = (count / cols).ceil();
    final w = (box.maxWidth - (cols - 1) * AppSpacing.md) / cols;
    final h = (box.maxHeight - (rows - 1) * AppSpacing.md) / rows;
    final s = w < h ? w : h;
    if (s > best) best = s;
  }
  return best.clamp(min, max);
}

/// True for single English words made of letters only (games that work letter by letter).
bool isSpellable(Word w) => RegExp(r'^[a-z]+$').hasMatch(w.en);

/// Spoken guidance shared by all games: the instruction the first time a
/// game appears in a lesson, "close! try again" after the first mistake, and
/// a "well done" when the child gets it right after that mistake.
mixin GameVoice<T extends StatefulWidget> on State<T> {
  bool _encouraged = false;

  AudioService get audio => context.read<AudioService>();

  /// Plays [prompt] if [introduce] and, once it has finished, runs [then]
  /// (usually saying the word being asked). If the child already acted while
  /// the prompt played, [then] is skipped.
  Future<void> intro(
    Prompt prompt, {
    required bool introduce,
    VoidCallback? then,
  }) async {
    if (introduce && !await audio.playPromptAndWait(prompt)) return;
    if (mounted) then?.call();
  }

  /// After a wrong answer: encourage once per round, then run [then].
  Future<void> encourage({VoidCallback? then}) async {
    if (!_encouraged) {
      _encouraged = true;
      if (!await audio.playPromptAndWait(Prompt.tryAgain)) return;
    }
    if (mounted) then?.call();
  }

  /// Whether a "well done" will be said, so callers can wait for it.
  bool get recovered => _encouraged;

  void praiseIfRecovered() {
    if (_encouraged) audio.playPrompt(Prompt.correct);
  }
}
