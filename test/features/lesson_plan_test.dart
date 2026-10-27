import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:kids_english/content/content_repository.dart';
import 'package:kids_english/content/models.dart';
import 'package:kids_english/features/lesson/lesson_plan.dart';

import '../helpers.dart';

void main() {
  final fruits = unit('fruits', [
    'apple',
    'banana',
    'grapes',
    'orange',
    'lemon',
    'pear',
    'kiwi',
    'plum',
  ]);
  final lessons = ContentRepository.lessonsFor(fruits);

  LessonPlan plan(Lesson l, [AgeLevel level = AgeLevel.little]) =>
      LessonPlan(l, level: level, random: Random(1));

  test(
    'learn lesson: flashcards for the new words first, then one quiz per word',
    () {
      final p = plan(lessons[0]);
      expect(p.length, 8);
      for (var i = 0; i < 4; i++) {
        expect(p.current.kind, StepKind.flashcard);
        expect(p.current.word, lessons[0].words[i]);
        p.complete();
      }
      expect(p.current.kind, StepKind.listenChoose);
    },
  );

  test('review lesson: quizzes only', () {
    final p = plan(lessons[2]);
    expect(p.length, fruits.words.length);
    expect(p.current.kind, StepKind.listenChoose);
  });

  test('quiz options: right count, include the answer, no duplicates', () {
    for (final level in AgeLevel.values) {
      final p = plan(lessons[2], level);
      final step = p.current;
      expect(step.options.length, level.choiceCount);
      expect(step.options, contains(step.word));
      expect(step.options.toSet().length, step.options.length);
    }
  });

  test(
    'a missed word comes back once at the end, and mistakes are counted',
    () {
      final p = plan(lessons[2]);
      final missed = p.current.word;
      p.complete(wrongTries: 2);
      expect(p.length, fruits.words.length + 1);
      while (p.index < p.length - 1) {
        p.complete();
      }
      expect(p.current.word, missed);
      p.complete(wrongTries: 1); // missed again: not re-added a second time
      expect(p.isFinished, isTrue);
      expect(p.mistakes, 3);
      expect(p.wrongByWord[missed.id], 3);
    },
  );
}
