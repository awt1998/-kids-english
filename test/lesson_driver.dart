import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kids_english/features/games/bubble_pop_game.dart';
import 'package:kids_english/features/games/letter_games.dart';
import 'package:kids_english/features/games/match_game.dart';
import 'package:kids_english/features/games/memory_game.dart';
import 'package:kids_english/features/games/order_sentence_game.dart';
import 'package:kids_english/features/games/trace_game.dart';
import 'package:kids_english/features/lesson/flashcard_game.dart';
import 'package:kids_english/features/lesson/listen_choose_game.dart';
import 'package:kids_english/features/lesson/lesson_screen.dart';

/// Plays whatever game is on screen the way a child would, until the lesson ends.
/// Returns the kinds of games it met, in order.
Future<List<Type>> playLesson(WidgetTester tester, {int maxSteps = 40}) async {
  final seen = <Type>[];
  Future<void> wait([int ms = 400]) => tester.pump(Duration(milliseconds: ms));

  for (var step = 0; step < maxSteps; step++) {
    await wait(1700); // instructions and the spoken word
    if (find.byType(LessonScreen).evaluate().isEmpty) return seen;

    if (find.byType(FlashcardGame).evaluate().isNotEmpty) {
      seen.add(FlashcardGame);
      await tester.tap(find.byKey(const ValueKey('flashcard')));
      await wait(700);
      await tester.tap(find.byKey(const ValueKey('next')));
    } else if (find.byType(ListenChooseGame).evaluate().isNotEmpty) {
      seen.add(ListenChooseGame);
      final g = tester.widget<ListenChooseGame>(find.byType(ListenChooseGame));
      await tester.tap(find.byKey(ValueKey('choice-${g.target.id}')));
      await wait(1400);
    } else if (find.byType(BubblePopGame).evaluate().isNotEmpty) {
      seen.add(BubblePopGame);
      final g = tester.widget<BubblePopGame>(find.byType(BubblePopGame));
      await tester.tap(
        find.byKey(ValueKey('bubble-${g.target.id}')),
        warnIfMissed: false,
      );
      await wait(1300);
    } else if (find.byType(MemoryGame).evaluate().isNotEmpty) {
      seen.add(MemoryGame);
      final n = find
          .byWidgetPredicate(
            (w) =>
                w.key is ValueKey<String> &&
                (w.key! as ValueKey<String>).value.startsWith('memory-'),
          )
          .evaluate()
          .length;
      for (
        var i = 0;
        i < n && find.byType(MemoryGame).evaluate().isNotEmpty;
        i++
      ) {
        for (
          var j = i + 1;
          j < n && find.byType(MemoryGame).evaluate().isNotEmpty;
          j++
        ) {
          for (final k in ['memory-$i', 'memory-$j']) {
            if (find.byKey(ValueKey(k)).evaluate().isEmpty) break;
            await tester.tap(find.byKey(ValueKey(k)));
            await wait(k.endsWith('$i') ? 350 : 1100);
          }
        }
      }
      await wait(1600);
    } else if (find.byType(MatchGame).evaluate().isNotEmpty) {
      seen.add(MatchGame);
      final g = tester.widget<MatchGame>(find.byType(MatchGame));
      for (final w in g.words) {
        await tester.tap(find.byKey(ValueKey('pic-${w.id}')));
        await wait(200);
        await tester.tap(find.byKey(ValueKey('label-${w.id}')));
        await wait(400);
      }
      await wait(1500);
    } else if (find.byType(MissingLetterGame).evaluate().isNotEmpty) {
      seen.add(MissingLetterGame);
      // The two wrong choices never appear in the word, so the right one is the one that does.
      final g = tester.widget<MissingLetterGame>(
        find.byType(MissingLetterGame),
      );
      final answer = find.byWidgetPredicate((w) {
        final k = w.key;
        return k is ValueKey<String> &&
            k.value.startsWith('letter-') &&
            g.word.en.contains(k.value.substring(7));
      });
      await tester.tap(answer.first);
      await wait(1800);
    } else if (find.byType(SpellGame).evaluate().isNotEmpty) {
      seen.add(SpellGame);
      final g = tester.widget<SpellGame>(find.byType(SpellGame));
      for (final c in g.word.en.split('')) {
        final tile = find.byWidgetPredicate((w) {
          final k = w.key;
          if (k is! ValueKey<String> || !k.value.startsWith('tile-')) {
            return false;
          }
          return find
              .descendant(of: find.byWidget(w), matching: find.text(c))
              .evaluate()
              .isNotEmpty;
        });
        await tester.tap(tile.first);
        await wait(250);
      }
      await wait(1900);
    } else if (find.byType(OrderSentenceGame).evaluate().isNotEmpty) {
      seen.add(OrderSentenceGame);
      final g = tester.widget<OrderSentenceGame>(
        find.byType(OrderSentenceGame),
      );
      final text = g.sentence.en.replaceAll(RegExp(r'[.!?]$'), '');
      for (final word in text.split(' ')) {
        final tile = find.byWidgetPredicate((w) {
          final k = w.key;
          if (k is! ValueKey<String> || !k.value.startsWith('wordtile-')) {
            return false;
          }
          return find
              .descendant(of: find.byWidget(w), matching: find.text(word))
              .evaluate()
              .isNotEmpty;
        });
        await tester.tap(tile.first);
        await wait(250);
      }
      await wait(3100);
    } else if (find.byType(TraceGame).evaluate().isNotEmpty) {
      seen.add(TraceGame);
      await traceCurrentLetter(tester);
      await wait(1800);
    } else {
      fail('Unknown step on screen');
    }
  }
  fail('Lesson did not finish in $maxSteps steps');
}

/// Drags a finger over every part of the letter on the tracing pad.
/// Needs [LetterShapes.load] to have run in `tester.runAsync` beforehand.
Future<void> traceCurrentLetter(
  WidgetTester tester, {
  double fraction = 1,
}) async {
  final g = tester.widget<TraceGame>(find.byType(TraceGame));
  final pad = find.byKey(const ValueKey('trace-pad'));
  final rect = tester.getRect(pad);
  final shapes = await LetterShapes.load();
  final letter = g.lowercase
      ? g.letterWord.en.toLowerCase()
      : g.letterWord.en.toUpperCase();
  final path = shapes.pathFor(letter, rect.width - 16); // inside the 8px border
  final gesture = await tester.startGesture(
    rect.topLeft + const Offset(8, 8) + _firstInside(path, rect.width - 16),
  );
  // Rows top to bottom; `fraction` < 1 stops part-way (for a mid-tracing picture).
  for (var y = 0.0; y < rect.width * fraction; y += rect.width / 40) {
    for (var x = 0.0; x < rect.width; x += rect.width / 40) {
      final p = Offset(x, y);
      if (path.contains(p)) {
        await gesture.moveTo(rect.topLeft + const Offset(8, 8) + p);
      }
    }
  }
  await gesture.up();
}

Offset _firstInside(Path path, double size) {
  for (var y = 0.0; y < size; y += 4) {
    for (var x = 0.0; x < size; x += 4) {
      if (path.contains(Offset(x, y))) return Offset(x, y);
    }
  }
  return Offset.zero;
}
