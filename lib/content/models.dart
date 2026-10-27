import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Age groups. The level decides which games appear and how hard they are.
enum AgeLevel {
  little('٣ – ٥', 3), // cannot read: pictures and sound only
  middle('٦ – ٨', 4),
  big('٩ – ١٠', 4);

  const AgeLevel(this.ageLabel, this.choiceCount);

  /// Arabic-digit age range shown to parents.
  final String ageLabel;

  /// Number of pictures offered in "listen and choose".
  final int choiceCount;
}

class Word {
  const Word({required this.id, required this.en, required this.ar});

  factory Word.fromJson(Map<String, dynamic> json) => Word(
    id: json['id'] as String,
    en: json['en'] as String,
    ar: json['ar'] as String,
  );

  final String id;
  final String en;
  final String ar;

  String get imagePath => 'assets/images/words/$id.svg';
  String get audioPath => 'audio/en/words/$id.mp3';

  @override
  bool operator ==(Object other) => other is Word && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

class Unit {
  const Unit({
    required this.id,
    required this.titleAr,
    required this.titleEn,
    required this.icon,
    required this.color,
    this.words = const [],
  });

  final String id;
  final String titleAr;
  final String titleEn;
  final String icon;
  final Color color;

  /// Empty while the unit is still "coming soon".
  final List<Word> words;

  bool get isAvailable => words.isNotEmpty;
  String get iconPath => 'assets/images/ui/$icon.svg';

  static Color colorByName(String name) => switch (name) {
    'sun' => AppColors.sun,
    'coral' => AppColors.coral,
    'mint' => AppColors.mint,
    'sky' => AppColors.sky,
    'grape' => AppColors.grape,
    'leaf' => AppColors.leaf,
    _ => throw ArgumentError('Unknown colour token "$name"'),
  };
}

enum LessonKind { learn, review }

/// A short play session (3–5 minutes) inside a unit.
class Lesson {
  const Lesson({
    required this.unit,
    required this.index,
    required this.kind,
    required this.words,
  });

  final Unit unit;
  final int index;
  final LessonKind kind;

  /// Words practised in this lesson. For [LessonKind.learn] these are new words.
  final List<Word> words;

  /// Stable key used to store results, e.g. `fruits:0`.
  String get key => '${unit.id}:$index';
}
