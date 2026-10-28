import '../content/models.dart';
import 'child_profile.dart';

/// Local calendar day as a whole number, so "today", "tomorrow" and gaps
/// between visits are simple integer maths.
int dayNumber(DateTime t) =>
    DateTime.utc(t.year, t.month, t.day).millisecondsSinceEpoch ~/
    Duration.millisecondsPerDay;

/// A simplified Leitner system: each correct first try moves a word to the
/// next box and pushes its next review further away; a mistake sends it back
/// to box 1 so it comes back the next day.
abstract final class Srs {
  static const maxBox = 5;
  static const _intervals = [0, 1, 2, 4, 7, 14];

  static int intervalDays(int box) => _intervals[box.clamp(0, maxBox)];

  /// Earlier words that are due today, weakest and most overdue first.
  static List<Word> dueWords(
    ChildProfile child,
    Iterable<Word> pool, {
    required int today,
    int limit = 2,
  }) {
    final due = pool.where((w) {
      final s = child.words[w.id];
      return s != null && s.box > 0 && s.dueDay <= today;
    }).toList();
    due.sort((a, b) {
      final sa = child.words[a.id]!, sb = child.words[b.id]!;
      final byBox = sa.box.compareTo(sb.box);
      return byBox != 0 ? byBox : sa.dueDay.compareTo(sb.dueDay);
    });
    return due.take(limit).toList();
  }

  /// Words of a unit ordered for a review: due first, then the weakest.
  static List<Word> reviewOrder(
    ChildProfile child,
    List<Word> words, {
    required int today,
  }) {
    int score(Word w) {
      final s = child.words[w.id];
      if (s == null) return 0;
      final due = s.dueDay <= today ? 0 : 100;
      return due + s.box * 10 - s.wrong.clamp(0, 9);
    }

    return [...words]..sort((a, b) => score(a).compareTo(score(b)));
  }
}
