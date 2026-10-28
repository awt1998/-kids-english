import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kids_english/audio/audio_service.dart';
import 'package:kids_english/content/content_repository.dart';
import 'package:kids_english/content/models.dart';
import 'package:kids_english/features/games/bubble_pop_game.dart';
import 'package:kids_english/features/games/letter_games.dart';
import 'package:kids_english/features/games/match_game.dart';
import 'package:kids_english/features/games/memory_game.dart';
import 'package:kids_english/features/games/order_sentence_game.dart';
import 'package:kids_english/features/games/trace_game.dart';
import 'package:kids_english/features/lesson/celebration_screen.dart';
import 'package:kids_english/features/lesson/lesson_screen.dart';
import 'package:kids_english/progress/profiles_store.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../lesson_driver.dart';

/// Every age group can play real lessons from start to celebration, and the
/// rewards (stars, stickers, today's flower, spaced repetition) are saved.
void main() {
  late ContentRepository content;

  Future<ProfilesStore> setUpStore(WidgetTester tester, AgeLevel level) async {
    SharedPreferences.setMockInitialValues({});
    content = (await tester.runAsync(ContentRepository.load))!;
    // Asset files load with real I/O, so preload the tracing shapes outside fake time.
    await tester.runAsync(LetterShapes.load);
    final store = (await tester.runAsync(
      () => ProfilesStore.load(now: () => DateTime(2026, 3, 10)),
    ))!;
    await tester.runAsync(() => store.addChild(avatar: 'lion', level: level));
    return store;
  }

  Future<void> open(
    WidgetTester tester,
    ProfilesStore store,
    Lesson lesson,
  ) async {
    tester.view.physicalSize = const Size(1180, 820);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider.value(value: content),
          Provider<AudioService>.value(value: SilentAudioService()),
          ChangeNotifierProvider.value(value: store),
        ],
        child: MaterialApp(
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => LessonScreen(lesson: lesson),
                    ),
                  ),
                  child: const Text('go'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  Lesson lessonOf(String unitId, int index) => ContentRepository.lessonsFor(
    content.units.firstWhere((u) => u.id == unitId),
  )[index];

  final expectations = {
    AgeLevel.little: {BubblePopGame, MemoryGame},
    AgeLevel.middle: {MissingLetterGame, MatchGame, MemoryGame},
    AgeLevel.big: {SpellGame, MatchGame, OrderSentenceGame},
  };

  for (final level in AgeLevel.values) {
    testWidgets('${level.name}: a full fruit lesson, rewards saved', (
      tester,
    ) async {
      final store = await setUpStore(tester, level);
      final lesson = lessonOf('fruits', 0);
      await open(tester, store, lesson);
      final seen = await playLesson(tester);
      expect(seen.toSet(), containsAll(expectations[level]!));
      expect(find.byType(CelebrationScreen), findsOneWidget);

      final child = store.current!;
      expect(child.lessonStars[lesson.key], 3, reason: 'no mistakes were made');
      expect(child.stickers, containsAll(lesson.words.map((w) => w.id)));
      expect(child.playDays, hasLength(1));
      for (final w in lesson.words) {
        expect(child.words[w.id]!.box, greaterThanOrEqualTo(1), reason: w.id);
      }
      await tester.pump(const Duration(seconds: 4));
    });
  }

  for (final level in [AgeLevel.little, AgeLevel.middle]) {
    testWidgets('${level.name}: an alphabet lesson with letter tracing', (
      tester,
    ) async {
      final store = await setUpStore(tester, level);
      await open(tester, store, lessonOf('alphabet', 0));
      final seen = await playLesson(tester);
      expect(seen, contains(TraceGame));
      expect(find.byType(CelebrationScreen), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
    });
  }
}
