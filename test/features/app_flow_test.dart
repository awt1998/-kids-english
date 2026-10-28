import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kids_english/app.dart';
import 'package:kids_english/audio/audio_service.dart';
import 'package:kids_english/content/content_repository.dart';
import 'package:kids_english/features/games/trace_game.dart';
import 'package:kids_english/features/lesson/celebration_screen.dart';
import 'package:kids_english/features/map/map_screen.dart';
import 'package:kids_english/features/rewards/album_screen.dart';
import 'package:kids_english/features/rewards/garden_screen.dart';
import 'package:kids_english/features/rewards/sticker.dart';
import 'package:kids_english/progress/profiles_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../lesson_driver.dart';

/// The whole journey a child takes, on a phone and on a tablet.
void main() {
  for (final size in const [Size(393, 852), Size(1180, 820)]) {
    testWidgets(
      'first launch → new child → lesson → stickers and a flower (${size.width.toInt()}w)',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        SharedPreferences.setMockInitialValues({});
        final content = (await tester.runAsync(ContentRepository.load))!;
        await tester.runAsync(LetterShapes.load);
        final profiles = (await tester.runAsync(ProfilesStore.load))!;
        final audio = SilentAudioService();

        await tester.pumpWidget(
          KidsEnglishApp(content: content, profiles: profiles, audio: audio),
        );
        await tester.pump();
        expect(audio.musicPlaying, isTrue);

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
        await tester.pump(const Duration(milliseconds: 500));
        expect(audio.musicPlaying, isFalse, reason: 'no music while playing');
        await playLesson(tester);

        expect(find.byType(CelebrationScreen), findsOneWidget);
        expect(profiles.current!.lessonStars['fruits:0'], 3);
        expect(find.byType(Sticker), findsNWidgets(4));
        await tester.pump(const Duration(seconds: 4));
        await tester.ensureVisible(find.byKey(const ValueKey('continue')));
        await tester.tap(find.byKey(const ValueKey('continue')));
        await tester.pump();
        await tester.pump(
          const Duration(seconds: 1),
        ); // page transition back to the map
        expect(find.byType(CelebrationScreen), findsNothing);
        expect(find.byType(MapScreen), findsOneWidget);
        expect(audio.musicPlaying, isTrue);
        await tester.tap(find.byKey(const ValueKey('open-album')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.byType(AlbumScreen), findsOneWidget);
        final collected = tester
            .widgetList<Sticker>(find.byType(Sticker))
            .where((s) => s.collected);
        expect(collected, hasLength(4));
        await tester.tap(find.byKey(const ValueKey('album-back')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        await tester.tap(find.byKey(const ValueKey('open-garden')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.byType(GardenScreen), findsOneWidget);
        expect(profiles.current!.playDays, hasLength(1));
      },
    );
  }
}
