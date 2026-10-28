import 'package:flutter_test/flutter_test.dart';
import 'package:kids_english/content/models.dart';
import 'package:kids_english/progress/child_profile.dart';
import 'package:kids_english/progress/srs.dart';

import '../helpers.dart';

void main() {
  const today = 20000;
  ChildProfile child() =>
      ChildProfile(id: 'x', avatar: 'cat', level: AgeLevel.little);

  test('right first time climbs a box and comes back later each time', () {
    var s = const WordStats();
    final intervals = <int>[];
    for (var i = 0; i < 6; i++) {
      s = s.practised(firstTry: true, mistakes: 0, today: today);
      intervals.add(s.dueDay - today);
    }
    expect(s.box, Srs.maxBox);
    expect(intervals, [1, 2, 4, 7, 14, 14]);
  });

  test('a mistake sends the word back to box 1, due tomorrow', () {
    var s = const WordStats(box: 4, dueDay: today);
    s = s.practised(firstTry: false, mistakes: 2, today: today);
    expect(s.box, 1);
    expect(s.dueDay, today + 1);
    expect(s.wrong, 2);
  });

  test('due words: only practised words that are due, weakest first', () {
    final c = child()
      ..words['a'] = const WordStats(box: 3, dueDay: today - 1)
      ..words['b'] = const WordStats(box: 1, dueDay: today)
      ..words['c'] = const WordStats(box: 1, dueDay: today + 3)
      ..words['d'] = const WordStats(box: 2, dueDay: today - 5);
    final due = Srs.dueWords(
      c,
      [word('a'), word('b'), word('c'), word('d'), word('new')],
      today: today,
      limit: 3,
    );
    expect(due.map((w) => w.id), ['b', 'd', 'a']);
  });

  test('review order puts due and weak words first', () {
    final c = child()
      ..words['known'] = const WordStats(box: 5, dueDay: today + 10)
      ..words['shaky'] = const WordStats(box: 1, dueDay: today, wrong: 3);
    final order = Srs.reviewOrder(c, [
      word('known'),
      word('shaky'),
    ], today: today);
    expect(order.first.id, 'shaky');
  });

  test('dayNumber counts calendar days', () {
    expect(
      dayNumber(DateTime(2026, 1, 2, 23, 59)) -
          dayNumber(DateTime(2026, 1, 1, 0, 1)),
      1,
    );
  });
}
