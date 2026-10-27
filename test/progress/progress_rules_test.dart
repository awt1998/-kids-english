import 'package:flutter_test/flutter_test.dart';
import 'package:kids_english/content/content_repository.dart';
import 'package:kids_english/content/models.dart';
import 'package:kids_english/progress/child_profile.dart';
import 'package:kids_english/progress/progress_rules.dart';

import '../helpers.dart';

void main() {
  final a = unit('a', ['1', '2', '3', '4', '5', '6', '7', '8']);
  final b = unit('b', ['9', '10', '11', '12']);
  final soon = unit('soon', []);
  final units = [a, b, soon];
  ChildProfile child() =>
      ChildProfile(id: 'x', avatar: 'cat', level: AgeLevel.little);

  test('stars: never fewer than one, three for a perfect round', () {
    expect(starsFor(mistakes: 0), 3);
    expect(starsFor(mistakes: 1), 2);
    expect(starsFor(mistakes: 2), 2);
    expect(starsFor(mistakes: 9), 1);
  });

  test('only the first lesson of the first unit is open at the start', () {
    final c = child();
    final lessons = ContentRepository.lessonsFor(a);
    expect(isLessonOpen(c, units, lessons[0]), isTrue);
    expect(isLessonOpen(c, units, lessons[1]), isFalse);
    expect(isUnitOpen(c, units, b), isFalse);
    expect(nextLesson(c, units)!.key, 'a:0');
  });

  test('finishing a lesson opens the next one', () {
    final c = child()..lessonStars['a:0'] = 1;
    expect(isLessonOpen(c, units, ContentRepository.lessonsFor(a)[1]), isTrue);
    expect(nextLesson(c, units)!.key, 'a:1');
  });

  test('finishing every lesson of a unit opens the next unit', () {
    final c = child();
    for (final l in ContentRepository.lessonsFor(a)) {
      c.lessonStars[l.key] = 2;
    }
    expect(isUnitOpen(c, units, b), isTrue);
    expect(nextLesson(c, units)!.key, 'b:0');
  });

  test('units without content stay closed', () {
    final c = child();
    for (final l in [
      ...ContentRepository.lessonsFor(a),
      ...ContentRepository.lessonsFor(b),
    ]) {
      c.lessonStars[l.key] = 3;
    }
    expect(isUnitOpen(c, units, soon), isFalse);
    expect(nextLesson(c, units), isNull);
  });

  test('profile survives a JSON round trip', () {
    final c = child()
      ..lessonStars['a:0'] = 3
      ..words['1'] = const WordStats(correct: 2, wrong: 1);
    final back = ChildProfile.fromJson(c.toJson());
    expect(back.level, AgeLevel.little);
    expect(back.lessonStars, {'a:0': 3});
    expect(back.words['1']!.wrong, 1);
    expect(back.totalStars, 3);
  });
}
