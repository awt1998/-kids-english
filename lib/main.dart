import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'audio/audio_service.dart';
import 'content/content_repository.dart';
import 'progress/profiles_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  final content = await ContentRepository.load();
  final profiles = await ProfilesStore.load();
  runApp(
    KidsEnglishApp(
      content: content,
      profiles: profiles,
      audio: AudioPlayersService(),
    ),
  );
}
