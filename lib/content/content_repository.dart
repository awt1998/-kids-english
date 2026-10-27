import 'dart:convert';

import 'package:flutter/services.dart';

import 'models.dart';

/// Loads the learning content bundled in `assets/content`.
class ContentRepository {
  ContentRepository(this.units);

  /// New words introduced per learn lesson: few, so each one sticks.
  static const wordsPerLesson = 4;

  final List<Unit> units;

  static Future<ContentRepository> load([AssetBundle? bundle]) async {
    final assets = bundle ?? rootBundle;
    final index = jsonDecode(
      await assets.loadString('assets/content/index.json'),
    ) as Map<String, dynamic>;
    final manifest = await AssetManifest.loadFromAssetBundle(assets);
    final available = manifest.listAssets().toSet();

    final units = <Unit>[];
    for (final raw in (index['units'] as List).cast<Map<String, dynamic>>()) {
      final id = raw['id'] as String;
      final file = 'assets/content/units/$id.json';
      var words = const <Word>[];
      if (available.contains(file)) {
        final data =
            jsonDecode(await assets.loadString(file)) as Map<String, dynamic>;
        words = (data['words'] as List)
            .cast<Map<String, dynamic>>()
            .map(Word.fromJson)
            .toList();
      }
      units.add(
        Unit(
          id: id,
          titleAr: raw['titleAr'] as String,
          titleEn: raw['titleEn'] as String,
          icon: raw['icon'] as String,
          color: Unit.colorByName(raw['color'] as String),
          words: words,
        ),
      );
    }
    return ContentRepository(units);
  }

  /// Learn lessons of [wordsPerLesson] words each, then one review of the whole unit.
  static List<Lesson> lessonsFor(Unit unit) {
    final lessons = <Lesson>[];
    for (var i = 0; i < unit.words.length; i += wordsPerLesson) {
      final end = (i + wordsPerLesson).clamp(0, unit.words.length);
      lessons.add(
        Lesson(
          unit: unit,
          index: lessons.length,
          kind: LessonKind.learn,
          words: unit.words.sublist(i, end),
        ),
      );
    }
    if (lessons.length > 1) {
      lessons.add(
        Lesson(
          unit: unit,
          index: lessons.length,
          kind: LessonKind.review,
          words: unit.words,
        ),
      );
    }
    return lessons;
  }
}
