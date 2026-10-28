import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kids_english/audio/audio_service.dart';
import 'package:kids_english/audio/music_controller.dart';

void main() {
  testWidgets(
    'music plays on menus, stops during lessons and celebrations, returns after',
    (tester) async {
      final audio = SilentAudioService();
      final music = MusicController(audio);
      addTearDown(music.dispose);
      final nav = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: nav,
          navigatorObservers: [music],
          home: const Text('map'),
        ),
      );
      expect(audio.musicPlaying, isTrue);

      nav.currentState!.push(
        MaterialPageRoute<void>(
          settings: const RouteSettings(name: 'lesson'),
          builder: (_) => const Text('game'),
        ),
      );
      await tester.pumpAndSettle();
      expect(audio.musicPlaying, isFalse);

      nav.currentState!.pushReplacement(
        MaterialPageRoute<void>(
          settings: const RouteSettings(name: 'celebration'),
          builder: (_) => const Text('yay'),
        ),
      );
      await tester.pumpAndSettle();
      expect(audio.musicPlaying, isFalse);

      nav.currentState!.pop();
      await tester.pumpAndSettle();
      expect(audio.musicPlaying, isTrue);
    },
  );

  testWidgets('music pauses when the app goes to the background', (
    tester,
  ) async {
    final audio = SilentAudioService();
    final music = MusicController(audio);
    addTearDown(music.dispose);
    await tester.pumpWidget(
      MaterialApp(navigatorObservers: [music], home: const Text('map')),
    );
    expect(audio.musicPlaying, isTrue);
    music.didChangeAppLifecycleState(AppLifecycleState.paused);
    expect(audio.musicPlaying, isFalse);
    music.didChangeAppLifecycleState(AppLifecycleState.resumed);
    expect(audio.musicPlaying, isTrue);
  });
}
