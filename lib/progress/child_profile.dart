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
    Map<int, int>? secondsByDay,
  }) : secondsByDay = secondsByDay ?? {},
       lessonStars = lessonStars ?? {},
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
    secondsByDay: (json['time'] as Map<String, dynamic>? ?? {}).map(
      (k, v) => MapEntry(int.parse(k), v as int),
    ),
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

  /// Seconds of active play per day (see [dayNumber]), for the parent report
  /// and the daily time limit.
  final Map<int, int> secondsByDay;

  int secondsOn(int day) => secondsByDay[day] ?? 0;

  /// Seconds played over the 7 days ending [today].
  int secondsThisWeek(int today) =>
      [for (var d = today - 6; d <= today; d++) secondsOn(d)]
          .fold(0, (a, b) => a + b);

  /// Words practised at least once.
  int get wordsLearned => words.values.where((s) => s.box > 0).length;

  /// Words answered right first time on three reviews in a row (box 4+).
  int get wordsMastered => words.values.where((s) => s.box >= 4).length;

  /// Practised words the child finds hard: most mistakes first.
  List<String> hardWordIds({int limit = 12}) {
    final hard =
        words.entries
            .where((e) => e.value.wrong > 0 && e.value.box <= 2)
            .toList()
          ..sort((a, b) {
            final byWrong = b.value.wrong.compareTo(a.value.wrong);
            return byWrong != 0 ? byWrong : a.value.box.compareTo(b.value.box);
          });
    return hard.take(limit).map((e) => e.key).toList();
  }

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
    // Keep the last 60 days only; older play time is never shown.
    'time': {
      for (final e in secondsByDay.entries)
        if (secondsByDay.keys.reduce((a, b) => a > b ? a : b) - e.key < 60)
          '${e.key}': e.value,
    },
  };
}
