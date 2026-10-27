import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kids_english/content/content_repository.dart';
import 'package:kids_english/content/models.dart';

/// Guards the content files: every word needs a picture and a pronunciation.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ContentRepository content;

  setUpAll(() async => content = await ContentRepository.load());

  test('at least one unit is playable', () {
    expect(content.units.where((u) => u.isAvailable), isNotEmpty);
  });

  test('every unit has an icon on disk', () {
    for (final unit in content.units) {
      expect(
        File(unit.iconPath).existsSync(),
        isTrue,
        reason: 'missing ${unit.iconPath}',
      );
    }
  });

  test('every word has an image and English audio', () {
    for (final word in content.units.expand((u) => u.words)) {
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

  test('word ids are unique across all units', () {
    final ids = content.units.expand((u) => u.words).map((w) => w.id).toList();
    expect(ids.toSet().length, ids.length);
  });

  test('every word has English and Arabic text', () {
    for (final word in content.units.expand((u) => u.words)) {
      expect(word.en.trim(), isNotEmpty);
      expect(word.ar.trim(), isNotEmpty);
    }
  });

  test('units have enough words for a 4-picture quiz', () {
    for (final unit in content.units.where((u) => u.isAvailable)) {
      expect(
        unit.words.length,
        greaterThanOrEqualTo(AgeLevel.big.choiceCount),
        reason: unit.id,
      );
    }
  });

  test('lessons: learn chunks of 4 then a review of the whole unit', () {
    final fruits = content.units.firstWhere((u) => u.id == 'fruits');
    final lessons = ContentRepository.lessonsFor(fruits);
    expect(lessons.map((l) => l.kind), [
      LessonKind.learn,
      LessonKind.learn,
      LessonKind.review,
    ]);
    expect(lessons.first.words.length, ContentRepository.wordsPerLesson);
    expect(lessons.last.words.length, fruits.words.length);
  });
}
