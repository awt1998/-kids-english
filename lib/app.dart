import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'audio/audio_service.dart';
import 'audio/music_controller.dart';
import 'content/content_repository.dart';
import 'core/strings_ar.dart';
import 'core/theme/app_theme.dart';
import 'features/profiles/add_child_screen.dart';
import 'features/profiles/profile_select_screen.dart';
import 'progress/app_settings.dart';
import 'progress/play_time.dart';
import 'progress/profiles_store.dart';

class KidsEnglishApp extends StatefulWidget {
  const KidsEnglishApp({
    super.key,
    required this.content,
    required this.profiles,
    required this.audio,
    required this.settings,
  });

  final ContentRepository content;
  final ProfilesStore profiles;
  final AudioService audio;
  final AppSettings settings;

  @override
  State<KidsEnglishApp> createState() => _KidsEnglishAppState();
}

class _KidsEnglishAppState extends State<KidsEnglishApp> {
  late final _music = MusicController(widget.audio);
  late final _playTime = PlayTimeTracker(widget.profiles, widget.settings);

  @override
  void initState() {
    super.initState();
    widget.settings.addListener(_applySettings);
    _applySettings();
  }

  void _applySettings() => widget.audio.applySettings(
    soundEffects: widget.settings.soundEffects,
    music: widget.settings.music,
  );

  @override
  void dispose() {
    widget.settings.removeListener(_applySettings);
    _playTime.dispose();
    _music.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider.value(value: widget.content),
        Provider.value(value: widget.audio),
        ChangeNotifierProvider.value(value: widget.profiles),
        ChangeNotifierProvider.value(value: widget.settings),
        Provider.value(value: _playTime),
      ],
      child: MaterialApp(
        title: Ar.appName,
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        // The interface is Arabic (right-to-left); learning content is English.
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar'), Locale('en')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        navigatorObservers: [_music],
        home: const _Root(),
      ),
    );
  }
}

/// First launch shows "create a child"; afterwards "who is playing?".
class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final hasChildren = context.select<ProfilesStore, bool>(
      (s) => s.children.isNotEmpty,
    );
    return hasChildren ? const ProfileSelectScreen() : const AddChildScreen();
  }
}
