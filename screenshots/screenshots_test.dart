// Renders the main screens to PNG files for review (and later for the stores).
//
//   flutter test screenshots --update-goldens
//
// Output: docs/previews/latest/<device>-<scene>.png
// ignore_for_file: invalid_use_of_visible_for_testing_member
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kids_english/app.dart';
import 'package:kids_english/audio/audio_service.dart';
import 'package:kids_english/content/content_repository.dart';
import 'package:kids_english/core/theme/app_theme.dart';
import 'package:kids_english/content/models.dart';
import 'package:kids_english/features/games/bubble_pop_game.dart';
import 'package:kids_english/features/games/letter_games.dart';
import 'package:kids_english/features/games/match_game.dart';
import 'package:kids_english/features/games/memory_game.dart';
import 'package:kids_english/features/games/order_sentence_game.dart';
import 'package:kids_english/features/games/trace_game.dart';
import 'package:kids_english/features/parents/child_report_screen.dart';
import 'package:kids_english/features/parents/parent_zone_screen.dart';
import 'package:kids_english/features/parents/parental_gate.dart';
import 'package:kids_english/features/parents/time_up_screen.dart';
import 'package:kids_english/progress/app_settings.dart';
import 'package:kids_english/progress/child_profile.dart';
import 'package:kids_english/progress/srs.dart';
import 'package:kids_english/progress/profiles_store.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test/lesson_driver.dart';

const devices = {'phone': Size(393, 852), 'tablet': Size(1180, 820)};

Future<void> loadFonts() async {
  Future<void> load(String family, Future<ByteData> data) async {
    await (FontLoader(family)..addFont(data)).load();
  }

  await load(
    'BalooBhaijaan2',
    rootBundle.load('assets/fonts/BalooBhaijaan2.ttf'),
  );
  await load('Baloo2', rootBundle.load('assets/fonts/Baloo2.ttf'));
  final flutterRoot = Platform.environment['FLUTTER_ROOT'] ?? '/opt/flutter';
  final icons = File(
    '$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  );
  await load(
    'MaterialIcons',
    Future.value(ByteData.sublistView(icons.readAsBytesSync())),
  );
}

void main() {
  setUpAll(loadFonts);

  for (final device in devices.entries) {
    testWidgets('screens on ${device.key}', (tester) async {
      tester.view.physicalSize = device.value * 2;
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);

      Future<void> settle([int ms = 600]) async {
        for (var i = 0; i < 4; i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 60)),
          );
          await tester.pump(Duration(milliseconds: ms ~/ 4));
        }
      }

      Future<void> shot(String scene) async {
        await settle();
        await expectLater(
          find.byType(MaterialApp).first,
          matchesGoldenFile('../docs/previews/latest/${device.key}-$scene.png'),
        );
      }

      Future<void> tapKey(String key, [int ms = 600]) async {
        final f = find.byKey(ValueKey(key));
        await tester.ensureVisible(f);
        await tester.pump();
        await tester.tap(f);
        await tester.pump();
        await settle(ms);
      }

      SharedPreferences.setMockInitialValues({});
      final content = (await tester.runAsync(ContentRepository.load))!;
      await tester.runAsync(LetterShapes.load);
      final profiles = (await tester.runAsync(ProfilesStore.load))!;
      final settings = (await tester.runAsync(AppSettings.load))!;
      final audio = SilentAudioService();

      // --- The app: new child, map, a whole lesson, album, garden.
      await tester.pumpWidget(
        KidsEnglishApp(
          content: content,
          profiles: profiles,
          audio: audio,
          settings: settings,
        ),
      );
      await tapKey('avatar-lion');
      await tapKey('level-little');
      await shot('01-new-child');
      await tapKey('save-child');
      await shot('02-map');
      await tapKey('stop-fruits:0');
      await shot('03-flashcard');
      await playLesson(tester);
      await settle(2500);
      await shot('04-celebration');
      await tapKey('continue', 1000);
      await shot('05-map-after-lesson');
      await tapKey('open-album', 800);
      await shot('06-album');
      await tapKey('album-back', 800);
      await tapKey('open-garden', 800);
      await shot('07-garden');

      // --- Parent Zone screens, with the progress from the lesson above.
      final child = profiles.current!;
      child.words['grapes'] = const WordStats(box: 1, wrong: 3);
      child.secondsByDay[dayNumber(DateTime.now())] = 17 * 60;
      Future<void> parentScreen(String scene, Widget screen) async {
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              Provider.value(value: content),
              Provider<AudioService>.value(value: audio),
              ChangeNotifierProvider.value(value: profiles),
              ChangeNotifierProvider.value(value: settings),
            ],
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: buildAppTheme(),
              locale: const Locale('ar'),
              supportedLocales: const [Locale('ar')],
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              home: screen,
            ),
          ),
        );
        await settle(800);
        await shot(scene);
      }

      await parentScreen(
        '20-parental-gate',
        ParentalGateScreen(random: Random(7)),
      );
      await settings.setDailyLimitMinutes(30);
      await parentScreen('21-parent-zone', const ParentZoneScreen());
      await parentScreen('22-child-report', ChildReportScreen(child: child));
      await parentScreen('23-time-up', const TimeUpScreen());

      // --- Each game on its own, with real content.
      Word w(String id) =>
          content.units.expand((u) => u.words).firstWhere((x) => x.id == id);
      final fruits = ['apple', 'banana', 'grapes', 'orange'].map(w).toList();
      final sentence = content.units
          .firstWhere((u) => u.id == 'animals_home')
          .sentences
          .first;
      void noop(_) {}

      Future<void> game(
        String scene,
        Widget g, [
        Future<void> Function()? interact,
      ]) async {
        await tester.pumpWidget(
          Provider<AudioService>.value(
            value: audio,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: buildAppTheme(),
              locale: const Locale('ar'),
              supportedLocales: const [Locale('ar')],
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              home: Scaffold(
                body: SafeArea(
                  child: Padding(padding: const EdgeInsets.all(16), child: g),
                ),
              ),
            ),
          ),
        );
        await settle(1800);
        if (interact != null) await interact();
        await shot(scene);
      }

      await game(
        '10-bubbles',
        BubblePopGame(
          key: UniqueKey(),
          target: fruits[0],
          options: fruits,
          onDone: noop,
        ),
      );
      await game(
        '11-memory',
        MemoryGame(
          key: UniqueKey(),
          words: fruits,
          withText: true,
          random: Random(4),
          onDone: noop,
        ),
        () async {
          await tester.tap(find.byKey(const ValueKey('memory-0')));
          await settle(500);
        },
      );
      await game(
        '12-match',
        MatchGame(
          key: UniqueKey(),
          words: fruits,
          random: Random(2),
          onDone: noop,
        ),
        () async {
          await tester.tap(find.byKey(const ValueKey('pic-apple')));
          await tester.pump();
          await tester.tap(find.byKey(const ValueKey('label-apple')));
          await settle(500);
        },
      );
      await game(
        '13-missing-letter',
        MissingLetterGame(
          key: UniqueKey(),
          word: w('rabbit'),
          random: Random(1),
          onDone: noop,
        ),
      );
      await game(
        '14-spell',
        SpellGame(
          key: UniqueKey(),
          word: w('lemon'),
          random: Random(1),
          onDone: noop,
        ),
      );
      await game(
        '15-trace',
        TraceGame(key: UniqueKey(), letterWord: w('letter_b'), onDone: noop),
        () async => traceCurrentLetter(tester, fraction: 0.5),
      );
      await game(
        '16-order-sentence',
        OrderSentenceGame(
          key: UniqueKey(),
          sentence: sentence,
          random: Random(5),
          onDone: noop,
        ),
      );
    });
  }
}
