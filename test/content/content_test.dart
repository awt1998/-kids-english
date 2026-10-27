import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kids_english/content/content_repository.dart';
import 'package:kids_english/content/models.dart';

/// Guards the content files: every word and sentence needs its picture and audio.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ContentRepository content;
  late List<Word> allWords;

  setUpAll(() async {
    content = await ContentRepository.load();
    allWords = content.units.expand((u) => u.words).toList();
  });

  test('every unit has content and an icon', () {
    for (final unit in content.units) {
      expect(unit.isAvailable, isTrue, reason: '${unit.id} has no words');
      expect(
        File(unit.iconPath).existsSync(),
        isTrue,
        reason: 'missing ${unit.iconPath}',
      );
    }
  });

  test('there are at least 400 words', () {
    expect(allWords.length, greaterThanOrEqualTo(400));
  });

  test('every word has an image and English audio', () {
    for (final word in allWords) {
      expect(
        File(word.imagePath).existsSync(),
        isTrue,
        reason: 'missing image for "${word.id}"',
      );
      expect(
        File('assets/${word.audioPath}').existsSync(),
        isTrue,
        reason: 'missing audio for "${word.id}"',
      );
    }
  });

  test('every sentence has audio and points at words of its own unit', () {
    for (final unit in content.units) {
      final ids = unit.words.map((w) => w.id).toSet();
      for (final s in unit.sentences) {
        expect(
          File('assets/${s.audioPath}').existsSync(),
          isTrue,
          reason: 'missing audio for sentence "${s.id}"',
        );
        expect(
          ids.containsAll(s.wordIds),
          isTrue,
          reason: 'sentence ${s.id} links unknown words ${s.wordIds}',
        );
        expect(s.en.trim(), isNotEmpty);
        expect(s.ar.trim(), isNotEmpty);
      }
    }
  });

  test('word and sentence ids are unique across all units', () {
    final ids = allWords.map((w) => w.id).toList();
    expect(ids.toSet().length, ids.length);
    final sentenceIds = content.units
        .expand((u) => u.sentences)
        .map((s) => s.id)
        .toList();
    expect(sentenceIds.toSet().length, sentenceIds.length);
  });

  test('every word has English and Arabic text', () {
    for (final word in allWords) {
      expect(word.en.trim(), isNotEmpty);
      expect(word.ar.trim(), isNotEmpty);
    }
  });

  test('units have enough words for a 4-picture quiz', () {
    for (final unit in content.units) {
      expect(
        unit.words.length,
        greaterThanOrEqualTo(AgeLevel.big.choiceCount),
        reason: unit.id,
      );
    }
  });

  test('pictures are not repeated inside a unit (quiz answers must look different)', () {
    for (final unit in content.units) {
      final bytes = unit.words
          .map((w) => File(w.imagePath).readAsStringSync())
          .toList();
      expect(
        bytes.toSet().length,
        bytes.length,
        reason: '${unit.id} has two words with the same picture',
      );
    }
  });

  test('days and months are only for children who can read', () {
    for (final id in ['days', 'months']) {
      final unit = content.units.firstWhere((u) => u.id == id);
      expect(unit.levels.contains(AgeLevel.little), isFalse);
    }
    expect(content.unitsFor(AgeLevel.little).length, content.units.length - 2);
  });

  test('lessons: learn chunks of 4 then a review of the whole unit', () {
    final fruits = content.units.firstWhere((u) => u.id == 'fruits');
    final lessons = ContentRepository.lessonsFor(fruits);
    expect(lessons.last.kind, LessonKind.review);
    expect(lessons.first.words.length, ContentRepository.wordsPerLesson);
    expect(lessons.last.words.length, fruits.words.length);
  });
}
