import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kids_english/app.dart';
import 'package:kids_english/audio/audio_service.dart';
import 'package:kids_english/content/content_repository.dart';
import 'package:kids_english/features/lesson/celebration_screen.dart';
import 'package:kids_english/features/map/map_screen.dart';
import 'package:kids_english/progress/profiles_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Plays the first lesson end to end, the way a child would.
void main() {
  for (final size in const [Size(393, 852), Size(1180, 820)]) {
    testWidgets(
      'first launch → new child → map → full lesson → stars (${size.width}x${size.height})',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        SharedPreferences.setMockInitialValues({});
        final content = await tester.runAsync(ContentRepository.load);
        final profiles = await tester.runAsync(ProfilesStore.load);
        final audio = SilentAudioService();

        await tester.pumpWidget(
          KidsEnglishApp(content: content!, profiles: profiles!, audio: audio),
        );
        await tester.pump();

        // No children yet: the app opens on "create a child".
        await tester.tap(find.byKey(const ValueKey('avatar-lion')));
        await tester.tap(find.byKey(const ValueKey('level-little')));
        await tester.pump();
        await tester.ensureVisible(find.byKey(const ValueKey('save-child')));
        await tester.tap(find.byKey(const ValueKey('save-child')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.byType(MapScreen), findsOneWidget);

        await tester.tap(find.byKey(const ValueKey('stop-fruits:0')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        // Four flashcards: flip, then next.
        for (var i = 0; i < 4; i++) {
          await tester.tap(find.byKey(const ValueKey('flashcard')));
          await tester.pump(const Duration(milliseconds: 600));
          await tester.tap(find.byKey(const ValueKey('next')));
          await tester.pump(const Duration(milliseconds: 400));
        }

        // Four listen-and-choose rounds. The first is answered wrong once.
        for (var round = 0; round < 4; round++) {
          await tester.pump(
            const Duration(milliseconds: 500),
          ); // word is spoken
          final target = audio.played
              .lastWhere((p) => p.startsWith('audio/en/words/'))
              .split('/')
              .last
              .split('.')
              .first;
          if (round == 0) {
            final wrong = find.byWidgetPredicate(
              (w) =>
                  w.key is ValueKey<String> &&
                  (w.key! as ValueKey<String>).value.startsWith('choice-') &&
                  (w.key! as ValueKey<String>).value != 'choice-$target',
            );
            await tester.tap(wrong.first);
            await tester.pump(const Duration(milliseconds: 800));
            expect(audio.played, contains('sfx:tryAgain'));
          }
          await tester.tap(find.byKey(ValueKey('choice-$target')));
          await tester.pump(const Duration(milliseconds: 1300));
        }

        // The missed word comes back once more.
        await tester.pump(const Duration(milliseconds: 500));
        final again = audio.played
            .lastWhere((p) => p.startsWith('audio/en/words/'))
            .split('/')
            .last
            .split('.')
            .first;
        await tester.tap(find.byKey(ValueKey('choice-$again')));
        await tester.pump(const Duration(milliseconds: 1300));
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.byType(CelebrationScreen), findsOneWidget);
        expect(profiles.current!.lessonStars['fruits:0'], 2);
        await tester.pump(const Duration(seconds: 3));

        await tester.tap(find.byKey(const ValueKey('continue')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.byType(MapScreen), findsOneWidget);
        expect(profiles.current!.totalStars, 2);
      },
    );
  }
}
