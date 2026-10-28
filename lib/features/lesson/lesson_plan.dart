import 'dart:math';

import '../../content/models.dart';
import '../games/game_common.dart';

enum StepKind {
  flashcard,
  listenChoose,
  bubblePop,
  memory,
  match,
  missingLetter,
  spell,
  trace,
  orderSentence,
}

class LessonStep {
  const LessonStep(
    this.kind, {
    this.word,
    this.options = const [],
    this.words = const [],
    this.sentence,
  });

  final StepKind kind;

  /// The word being asked about (single-target games).
  final Word? word;

  /// Pictures/bubbles offered, including [word].
  final List<Word> options;

  /// All words of a many-word game (memory, match).
  final List<Word> words;
  final Sentence? sentence;
}

/// Builds the sequence of games in one lesson for a child's age group, and
/// keeps score.
///
/// A learn lesson shows each new word on a flashcard, then practises the
/// words with games that suit the age, plus up to two earlier words that
/// spaced repetition says are due. A word answered wrongly comes back once
/// more at the end, so the lesson finishes on a success.
class LessonPlan {
  LessonPlan(
    this.lesson, {
    required this.level,
    this.reviewWords = const [],
    Random? random,
  }) : _random = random ?? Random() {
    _build();
  }

  final Lesson lesson;
  final AgeLevel level;

  /// Earlier words due for review (from spaced repetition), practised too.
  final List<Word> reviewWords;
  final Random _random;
  final _steps = <LessonStep>[];
  final _retried = <String>{};
  int _index = 0;

  /// Every tested word and its wrong taps (0 = right first time).
  final mistakesByWord = <String, int>{};
  int _extraMistakes = 0;

  int get mistakes =>
      mistakesByWord.values.fold(_extraMistakes, (a, b) => a + b);
  int get length => _steps.length;
  int get index => _index;
  bool get isFinished => _index >= _steps.length;
  LessonStep get current => _steps[_index];
  List<LessonStep> get steps => List.unmodifiable(_steps);
  double get progress => _steps.isEmpty ? 1 : _index / _steps.length;

  bool get _letters => lesson.unit.id == 'alphabet';
  List<Word> get _unitWords => lesson.unit.words;

  List<Word> _pick(List<Word> from, int n) =>
      ([...from]..shuffle(_random)).take(n).toList();

  LessonStep _choose(
    Word target, {
    StepKind kind = StepKind.listenChoose,
    int? count,
  }) {
    final n =
        count ??
        (kind == StepKind.bubblePop
            ? level.choiceCount + 1
            : level.choiceCount);
    final pool = _unitWords.where((w) => w != target).toList()
      ..shuffle(_random);
    final options = [target, ...pool.take(n - 1)]..shuffle(_random);
    return LessonStep(kind, word: target, options: options);
  }

  void _build() {
    final words = lesson.kind == LessonKind.learn ? lesson.words : _reviewSet();
    if (lesson.kind == LessonKind.learn) {
      for (final w in words) {
        _steps.add(LessonStep(StepKind.flashcard, word: w));
      }
    }
    _steps.addAll(_letters ? _letterGames(words) : _wordGames(words));
    if (lesson.kind == LessonKind.review) {
      // Reviews also listen to words the games above did not ask about.
      final asked = _steps.map((s) => s.word).toSet();
      _steps.addAll([
        for (final w in words.where((w) => !asked.contains(w)).take(3))
          _choose(w),
      ]);
    }
    for (final w in reviewWords.where((w) => !words.contains(w))) {
      _steps.add(_choose(w));
    }
  }

  /// Review lessons practise the whole unit, but never more than eight words.
  List<Word> _reviewSet() => lesson.words.take(8).toList();

  List<LessonStep> _wordGames(List<Word> words) {
    final spellable = words.where(isSpellable).toList();
    final sentences =
        lesson.unit.sentences
            .where((s) => s.wordIds.any((id) => words.any((w) => w.id == id)))
            .toList()
          ..shuffle(_random);
    final memoryWords = words.length >= 3 ? words.take(4).toList() : <Word>[];
    final steps = <LessonStep>[];

    switch (level) {
      case AgeLevel.little:
        // Listening and pictures only.
        steps.addAll([for (final w in _pick(words, 4)) _choose(w)]);
        steps.addAll([
          for (final w in _pick(words, 2)) _choose(w, kind: StepKind.bubblePop),
        ]);
        if (memoryWords.isNotEmpty) {
          steps.add(LessonStep(StepKind.memory, words: memoryWords));
        }
      case AgeLevel.middle:
        steps.addAll([for (final w in _pick(words, 2)) _choose(w)]);
        steps.addAll([
          for (final w in _pick(spellable, 2))
            LessonStep(StepKind.missingLetter, word: w),
        ]);
        if (words.length >= 3) {
          steps.add(LessonStep(StepKind.match, words: words.take(4).toList()));
        }
        steps.add(_choose(_pick(words, 1).first, kind: StepKind.bubblePop));
        if (memoryWords.isNotEmpty) {
          steps.add(LessonStep(StepKind.memory, words: memoryWords));
        }
      case AgeLevel.big:
        steps.add(_choose(_pick(words, 1).first));
        if (words.length >= 3) {
          steps.add(LessonStep(StepKind.match, words: words.take(4).toList()));
        }
        final spell = _pick(
          spellable.where((w) => w.en.length <= 8).toList(),
          2,
        );
        steps.addAll([
          for (final w in spell) LessonStep(StepKind.spell, word: w),
        ]);
        steps.addAll([
          for (final w in _pick(
            spellable.where((w) => !spell.contains(w)).toList(),
            1,
          ))
            LessonStep(StepKind.missingLetter, word: w),
        ]);
        steps.addAll([
          for (final s in sentences.take(2))
            LessonStep(StepKind.orderSentence, sentence: s),
        ]);
    }
    return steps;
  }

  List<LessonStep> _letterGames(List<Word> letters) {
    final traceCount = switch (level) {
      AgeLevel.little => 2,
      AgeLevel.middle => 2,
      AgeLevel.big => 1,
    };
    return [
      for (final w in _pick(letters, 3)) _choose(w),
      for (final w in _pick(letters, 2)) _choose(w, kind: StepKind.bubblePop),
      for (final w in _pick(letters, traceCount))
        LessonStep(StepKind.trace, word: w),
    ];
  }

  /// Finishes the current step with what the game reported.
  void complete(GameResult result) {
    for (final MapEntry(key: id, value: wrong)
        in result.mistakesByWord.entries) {
      mistakesByWord[id] = (mistakesByWord[id] ?? 0) + wrong;
      if (wrong > 0 && _retried.add(id)) {
        final word = [
          ..._unitWords,
          ...reviewWords,
        ].firstWhere((w) => w.id == id);
        _steps.add(_choose(word));
      }
    }
    _extraMistakes += result.extraMistakes;
    _index++;
  }
}
