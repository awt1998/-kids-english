// Renders the main screens to PNG files for review (and later for the stores).
//
//   flutter test screenshots --update-goldens
//
// Output: docs/previews/latest/<device>-<scene>.png
// ignore_for_file: invalid_use_of_visible_for_testing_member
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kids_english/app.dart';
import 'package:kids_english/audio/audio_service.dart';
import 'package:kids_english/content/content_repository.dart';
import 'package:kids_english/progress/profiles_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
          find.byType(MaterialApp),
          matchesGoldenFile('../docs/previews/latest/${device.key}-$scene.png'),
        );
      }

      Future<void> tapKey(String key, [int ms = 600]) async {
        final f = find.byKey(ValueKey(key));
        await tester.ensureVisible(f);
        await tester.pump();
        await tester.tap(f);
        await settle(ms);
      }

      SharedPreferences.setMockInitialValues({});
      final content = (await tester.runAsync(ContentRepository.load))!;
      final profiles = (await tester.runAsync(ProfilesStore.load))!;
      final audio = SilentAudioService();
      await tester.pumpWidget(
        KidsEnglishApp(content: content, profiles: profiles, audio: audio),
      );

      await tapKey('avatar-lion');
      await tapKey('level-little');
      await shot('1-new-child');

      await tapKey('save-child');
      await shot('2-map');

      await tapKey('stop-fruits:0');
      await shot('3-flashcard-front');
      await tapKey('flashcard', 900);
      await shot('4-flashcard-back');

      for (var i = 0; i < 4; i++) {
        if (i > 0) await tapKey('flashcard', 900);
        await tapKey('next');
      }
      await settle();
      String target() => audio.played
          .lastWhere((p) => p.startsWith('audio/en/words/'))
          .split('/')
          .last
          .split('.')
          .first;
      await shot('5-listen-choose');

      final wrong = find.byWidgetPredicate((w) {
        final k = w.key;
        return k is ValueKey<String> &&
            k.value.startsWith('choice-') &&
            k.value != 'choice-${target()}';
      });
      await tester.tap(wrong.first);
      await settle(300);
      await shot('6-hint-after-mistake');

      for (var round = 0; round < 5; round++) {
        await tapKey('choice-${target()}', 1400);
        await settle();
      }
      await settle(2500);
      await shot('7-celebration');

      await tapKey('continue');
      await shot('8-map-after-lesson');

      await tapKey('switch-child');
      await shot('9-who-is-playing');
    });
  }
}
