import '../content/models.dart';

/// Per-word practice counters, used for the parent report and (later) spaced repetition.
class WordStats {
  const WordStats({this.correct = 0, this.wrong = 0});

  factory WordStats.fromJson(Map<String, dynamic> json) =>
      WordStats(correct: json['c'] as int? ?? 0, wrong: json['w'] as int? ?? 0);

  final int correct;
  final int wrong;

  WordStats add({int correct = 0, int wrong = 0}) =>
      WordStats(correct: this.correct + correct, wrong: this.wrong + wrong);

  Map<String, dynamic> toJson() => {'c': correct, 'w': wrong};
}

/// One child on this device. Everything stays on the device.
class ChildProfile {
  ChildProfile({
    required this.id,
    required this.avatar,
    required this.level,
    this.name = '',
    Map<String, int>? lessonStars,
    Map<String, WordStats>? words,
  }) : lessonStars = lessonStars ?? {},
       words = words ?? {};

  factory ChildProfile.fromJson(Map<String, dynamic> json) => ChildProfile(
    id: json['id'] as String,
    avatar: json['avatar'] as String,
    level: AgeLevel.values.byName(json['level'] as String),
    name: json['name'] as String? ?? '',
    lessonStars: (json['stars'] as Map<String, dynamic>? ?? {}).map(
      (k, v) => MapEntry(k, v as int),
    ),
    words: (json['words'] as Map<String, dynamic>? ?? {}).map(
      (k, v) => MapEntry(k, WordStats.fromJson(v as Map<String, dynamic>)),
    ),
  );

  final String id;
  String avatar;
  AgeLevel level;
  String name;

  /// Best star count (1–3) per lesson key. Missing = not completed yet.
  final Map<String, int> lessonStars;
  final Map<String, WordStats> words;

  String get avatarPath => 'assets/images/avatars/$avatar.svg';
  int get totalStars => lessonStars.values.fold(0, (a, b) => a + b);

  Map<String, dynamic> toJson() => {
    'id': id,
    'avatar': avatar,
    'level': level.name,
    'name': name,
    'stars': lessonStars,
    'words': words.map((k, v) => MapEntry(k, v.toJson())),
  };
}
