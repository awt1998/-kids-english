import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kids_english/content/content_repository.dart';
import 'package:kids_english/content/models.dart';
import 'package:kids_english/features/games/game_common.dart';
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
  final letters = Unit(
    id: 'alphabet',
    titleAr: 'a',
    titleEn: 'a',
    icon: 'x',
    color: Colors.red,
    words: [
      for (final c in 'abcdefgh'.split(''))
        Word(id: 'letter_$c', en: c.toUpperCase(), ar: c),
    ],
  );

  LessonPlan plan(Lesson l, AgeLevel level, {List<Word> review = const []}) =>
      LessonPlan(l, level: level, reviewWords: review, random: Random(1));

  Set<StepKind> kinds(LessonPlan p) => p.steps.map((s) => s.kind).toSet();

  test('every learn lesson starts with a flashcard for each new word', () {
    for (final level in AgeLevel.values) {
      final p = plan(lessons[0], level);
      expect(
        p.steps.take(4).map((s) => s.kind),
        everyElement(StepKind.flashcard),
      );
      expect(p.steps.take(4).map((s) => s.word), lessons[0].words);
    }
  });

  test('little children only get listening and picture games', () {
    expect(kinds(plan(lessons[0], AgeLevel.little)), {
      StepKind.flashcard,
      StepKind.listenChoose,
      StepKind.bubblePop,
      StepKind.memory,
    });
  });

  test('older children get reading and spelling games', () {
    expect(
      kinds(plan(lessons[0], AgeLevel.middle)),
      containsAll([StepKind.missingLetter, StepKind.match]),
    );
    expect(
      kinds(plan(lessons[0], AgeLevel.big)),
      containsAll([StepKind.spell, StepKind.match]),
    );
  });

  test('the alphabet unit uses letter games with tracing', () {
    final l = ContentRepository.lessonsFor(letters).first;
    final k = kinds(plan(l, AgeLevel.little));
    expect(k, contains(StepKind.trace));
    expect(k, isNot(contains(StepKind.spell)));
  });

  test('lessons stay short (3–5 minutes)', () {
    for (final level in AgeLevel.values) {
      for (final l in lessons) {
        expect(
          plan(l, level).length,
          inInclusiveRange(6, 14),
          reason: '$level ${l.key}',
        );
      }
    }
  });

  test('quiz options: right count, include the answer, no duplicates', () {
    for (final level in AgeLevel.values) {
      for (final s in plan(
        lessons.last,
        level,
      ).steps.where((s) => s.kind == StepKind.listenChoose)) {
        expect(s.options.length, level.choiceCount);
        expect(s.options, contains(s.word));
        expect(s.options.toSet().length, s.options.length);
      }
    }
  });

  test('due words from earlier lessons are practised too', () {
    final review = [word('apple'), word('pear')];
    final p = plan(
      lessons[1],
      AgeLevel.little,
      review: [Word(id: 'old', en: 'old', ar: 'old')],
    );
    expect(p.steps.last.word!.id, 'old');
    expect(review, isNotEmpty);
  });

  test(
    'a missed word comes back once at the end; mistakes are counted per word',
    () {
      final p = plan(lessons[2], AgeLevel.little);
      final before = p.length;
      final first = p.current;
      p.complete(GameResult(mistakesByWord: {first.word!.id: 2}));
      expect(p.length, before + 1);
      while (p.index < p.length - 1) {
        p.complete(const GameResult());
      }
      expect(p.current.word, first.word);
      p.complete(GameResult(mistakesByWord: {first.word!.id: 1}));
      expect(p.isFinished, isTrue);
      expect(p.mistakes, 3);
      expect(p.mistakesByWord[first.word!.id], 3);
    },
  );
}
