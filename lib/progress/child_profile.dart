import '../content/models.dart';
import 'srs.dart';

/// Practice record of one word: counters for the parent report plus its
/// spaced-repetition box and the day it should come back.
class WordStats {
  const WordStats({
    this.correct = 0,
    this.wrong = 0,
    this.box = 0,
    this.dueDay = 0,
  });

  factory WordStats.fromJson(Map<String, dynamic> json) => WordStats(
    correct: json['c'] as int? ?? 0,
    wrong: json['w'] as int? ?? 0,
    box: json['b'] as int? ?? 0,
    dueDay: json['d'] as int? ?? 0,
  );

  final int correct;
  final int wrong;

  /// 0 = never practised, 1 = just learned … [Srs.maxBox] = well known.
  final int box;

  /// Day number (see [dayNumber]) from which the word is due for review.
  final int dueDay;

  /// The result of one practice: right first time moves the word up a box,
  /// any mistake sends it back to box 1 so it returns soon.
  WordStats practised({
    required bool firstTry,
    required int mistakes,
    required int today,
  }) {
    final newBox = firstTry ? (box + 1).clamp(1, Srs.maxBox) : 1;
    return WordStats(
      correct: correct + (firstTry ? 1 : 0),
      wrong: wrong + mistakes,
      box: newBox,
      dueDay: today + Srs.intervalDays(newBox),
    );
  }

  Map<String, dynamic> toJson() => {
    'c': correct,
    'w': wrong,
    'b': box,
    'd': dueDay,
  };
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
    Set<String>? stickers,
    Set<int>? playDays,
  }) : lessonStars = lessonStars ?? {},
       words = words ?? {},
       stickers = stickers ?? {},
       playDays = playDays ?? {};

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
    stickers: {...(json['stickers'] as List? ?? const []).cast<String>()},
    playDays: {...(json['days'] as List? ?? const []).cast<int>()},
  );

  final String id;
  String avatar;
  AgeLevel level;
  String name;

  /// Best star count (1–3) per lesson key. Missing = not completed yet.
  final Map<String, int> lessonStars;
  final Map<String, WordStats> words;

  /// Word ids collected as stickers in the album.
  final Set<String> stickers;

  /// Days (see [dayNumber]) on which the child finished at least one lesson:
  /// one flower each in the garden. Missed days are simply not there.
  final Set<int> playDays;

  String get avatarPath => 'assets/images/avatars/$avatar.svg';
  int get totalStars => lessonStars.values.fold(0, (a, b) => a + b);

  Map<String, dynamic> toJson() => {
    'id': id,
    'avatar': avatar,
    'level': level.name,
    'name': name,
    'stars': lessonStars,
    'words': words.map((k, v) => MapEntry(k, v.toJson())),
    'stickers': stickers.toList()..sort(),
    'days': playDays.toList()..sort(),
  };
}
