import 'package:flutter/widgets.dart';

import 'audio_service.dart';

/// Route names of the screens where a child is playing: the music stays off there.
const quietRoutes = {'lesson', 'celebration'};

/// Turns the background music on for menus and the map, and off during games,
/// celebrations and whenever the app is not in the foreground.
class MusicController extends NavigatorObserver with WidgetsBindingObserver {
  MusicController(this.audio) {
    WidgetsBinding.instance.addObserver(this);
  }

  final AudioService audio;
  Route<dynamic>? _top;
  bool _foreground = true;

  void _update() {
    final quiet = quietRoutes.contains(_top?.settings.name);
    audio.setMusicPlaying(_foreground && _top != null && !quiet);
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _top = route;
    _update();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _top = previousRoute;
    _update();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _top = newRoute;
    _update();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _update();
  }

  void dispose() => WidgetsBinding.instance.removeObserver(this);
}
