import 'dart:math';

import '../../content/models.dart';

enum StepKind { flashcard, listenChoose }

class LessonStep {
  const LessonStep(this.kind, this.word, {this.options = const []});

  final StepKind kind;
  final Word word;

  /// Pictures offered in a listen-and-choose round (includes [word]).
  final List<Word> options;
}

/// Builds and runs the sequence of steps in one lesson, and keeps score.
///
/// Learn lessons show each new word as a flashcard, then quiz every word once.
/// Any word the child missed is quizzed one more time at the end, so the
/// round finishes on a success.
class LessonPlan {
  LessonPlan(this.lesson, {required this.level, Random? random})
    : _random = random ?? Random() {
    if (lesson.kind == LessonKind.learn) {
      for (final w in lesson.words) {
        _steps.add(LessonStep(StepKind.flashcard, w));
      }
    }
    final quizOrder = [...lesson.words]..shuffle(_random);
    for (final w in quizOrder) {
      _steps.add(_quiz(w));
    }
  }

  final Lesson lesson;
  final AgeLevel level;
  final Random _random;
  final _steps = <LessonStep>[];
  final _retried = <String>{};
  int _index = 0;

  final correctByWord = <String, int>{};
  final wrongByWord = <String, int>{};

  int get mistakes => wrongByWord.values.fold(0, (a, b) => a + b);
  int get length => _steps.length;
  int get index => _index;
  bool get isFinished => _index >= _steps.length;
  LessonStep get current => _steps[_index];
  double get progress => _steps.isEmpty ? 1 : _index / _steps.length;

  LessonStep _quiz(Word target) {
    final pool = lesson.unit.words.where((w) => w != target).toList()
      ..shuffle(_random);
    final options = [target, ...pool.take(level.choiceCount - 1)]
      ..shuffle(_random);
    return LessonStep(StepKind.listenChoose, target, options: options);
  }

  /// Finishes the current step. [wrongTries] counts wrong taps before the right one.
  void complete({int wrongTries = 0}) {
    final step = current;
    if (step.kind == StepKind.listenChoose) {
      final id = step.word.id;
      if (wrongTries > 0) {
        wrongByWord[id] = (wrongByWord[id] ?? 0) + wrongTries;
        if (_retried.add(id)) _steps.add(_quiz(step.word));
      } else {
        correctByWord[id] = (correctByWord[id] ?? 0) + 1;
      }
    }
    _index++;
  }
}
