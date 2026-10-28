import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kids_english/audio/audio_service.dart';
import 'package:kids_english/content/models.dart';
import 'package:kids_english/features/games/game_common.dart';
import 'package:kids_english/features/games/letter_games.dart';
import 'package:kids_english/features/games/match_game.dart';
import 'package:kids_english/features/games/trace_game.dart';
import 'package:kids_english/features/lesson/listen_choose_game.dart';
import 'package:provider/provider.dart';

const apple = Word(id: 'apple', en: 'apple', ar: 'تفاحة');
const pear = Word(id: 'pear', en: 'pear', ar: 'كمثرى');
const lemon = Word(id: 'lemon', en: 'lemon', ar: 'ليمونة');

Future<SilentAudioService> host(WidgetTester tester, Widget game) async {
  tester.view.physicalSize = const Size(1180, 820);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final audio = SilentAudioService();
  await tester.pumpWidget(
    Provider<AudioService>.value(
      value: audio,
      child: MaterialApp(home: Scaffold(body: game)),
    ),
  );
  return audio;
}

void main() {
  testWidgets(
    'missing letter: a wrong letter gives a gentle hint and is counted',
    (tester) async {
      GameResult? result;
      final audio = await host(
        tester,
        MissingLetterGame(
          word: apple,
          random: Random(3),
          onDone: (r) => result = r,
        ),
      );
      final choices = find.byWidgetPredicate(
        (w) =>
            w.key is ValueKey<String> &&
            (w.key! as ValueKey<String>).value.startsWith('letter-'),
      );
      final keys = choices
          .evaluate()
          .map((e) => (e.widget.key! as ValueKey<String>).value.substring(7))
          .toList();
      final wrong = keys.firstWhere((c) => !apple.en.contains(c));
      final right = keys.firstWhere(apple.en.contains);

      await tester.tap(find.byKey(ValueKey('letter-$wrong')));
      await tester.pump(const Duration(milliseconds: 300));
      expect(audio.played, contains('sfx:tryAgain'));
      expect(audio.played, isNot(contains('sfx:correct')));

      await tester.tap(find.byKey(ValueKey('letter-$right')));
      await tester.pump(const Duration(seconds: 2));
      expect(result!.mistakesByWord, {'apple': 1});
    },
  );

  testWidgets('spelling: letters in the right order finish the word', (
    tester,
  ) async {
    GameResult? result;
    await host(
      tester,
      SpellGame(word: lemon, random: Random(1), onDone: (r) => result = r),
    );
    Finder tileWith(String c) => find.byWidgetPredicate((w) {
      final k = w.key;
      return k is ValueKey<String> &&
          k.value.startsWith('tile-') &&
          find
              .descendant(of: find.byWidget(w), matching: find.text(c))
              .evaluate()
              .isNotEmpty;
    });
    // One wrong tile first: "n" is not the first letter.
    await tester.tap(tileWith('n').first);
    await tester.pump(const Duration(milliseconds: 300));
    for (final c in 'lemon'.split('')) {
      await tester.tap(tileWith(c).first);
      await tester.pump(const Duration(milliseconds: 200));
    }
    await tester.pump(const Duration(seconds: 2));
    expect(result!.mistakesByWord, {'lemon': 1});
  });

  testWidgets(
    'matching: a wrong pair counts for the picture, the right pairs finish',
    (tester) async {
      GameResult? result;
      await host(
        tester,
        MatchGame(
          words: const [apple, pear, lemon],
          random: Random(2),
          onDone: (r) => result = r,
        ),
      );
      await tester.tap(find.byKey(const ValueKey('pic-apple')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('label-pear')));
      await tester.pump(const Duration(milliseconds: 300));
      for (final w in const [apple, pear, lemon]) {
        await tester.tap(find.byKey(ValueKey('pic-${w.id}')));
        await tester.pump();
        await tester.tap(find.byKey(ValueKey('label-${w.id}')));
        await tester.pump(const Duration(milliseconds: 300));
      }
      await tester.pump(const Duration(seconds: 2));
      expect(result!.mistakesByWord, {'apple': 1, 'pear': 0, 'lemon': 0});
    },
  );

  test(
    'tracing: drawing on the letter counts, scribbling elsewhere does not',
    () {
      final square = Path()..addRect(const Rect.fromLTWH(100, 100, 200, 200));
      final onLetter = TraceScorer(square, 400);
      for (var y = 105.0; y < 300; y += 20) {
        for (var x = 105.0; x < 300; x += 20) {
          onLetter.add(Offset(x, y));
        }
      }
      expect(onLetter.done, isTrue);

      final scribble = TraceScorer(square, 400);
      for (var y = 0.0; y < 400; y += 8) {
        for (var x = 0.0; x < 400; x += 8) {
          scribble.add(Offset(x, y));
        }
      }
      expect(scribble.coverage, greaterThan(0.8));
      expect(
        scribble.done,
        isFalse,
        reason: 'most of the scribble is off the letter',
      );
    },
  );

  testWidgets('the instruction finishes first, then the word is asked', (
    tester,
  ) async {
    final audio = await host(
      tester,
      ListenChooseGame(
        target: apple,
        options: const [apple, pear, lemon],
        onDone: (_) {},
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(audio.played, ['prompt:listenAndChoose', apple.audioPath]);
  });

  testWidgets(
    'if the child acts during the instruction, the word is not said over it',
    (tester) async {
      final audio = SilentAudioService()..interruptNextWait = true;
      tester.view.physicalSize = const Size(1180, 820);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        Provider<AudioService>.value(
          value: audio,
          child: MaterialApp(
            home: Scaffold(
              body: ListenChooseGame(
                target: apple,
                options: const [apple, pear, lemon],
                onDone: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(audio.played, ['prompt:listenAndChoose']);
    },
  );
}
