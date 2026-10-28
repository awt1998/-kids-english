import 'dart:async';

import 'package:flutter/widgets.dart';

import 'app_settings.dart';
import 'profiles_store.dart';
import 'srs.dart';

/// Counts how long the current child actively plays (app in the foreground,
/// a child chosen) and saves it every [flushEvery]. Knows when today's
/// limit is reached.
class PlayTimeTracker with WidgetsBindingObserver {
  PlayTimeTracker(
    this.store,
    this.settings, {
    this.tick = const Duration(seconds: 5),
    this.flushEvery = 6,
  }) {
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(tick, (_) => _onTick());
  }

  final ProfilesStore store;
  final AppSettings settings;
  final Duration tick;

  /// Ticks between saves.
  final int flushEvery;

  Timer? _timer;
  bool _foreground = true;
  int _unsaved = 0;
  int _ticks = 0;

  void _onTick() {
    if (!_foreground || store.current == null) return;
    _unsaved += tick.inSeconds;
    if (++_ticks % flushEvery == 0) flush();
  }

  /// Saves the seconds counted so far.
  Future<void> flush() async {
    final s = _unsaved;
    _unsaved = 0;
    await store.addPlayTime(s);
  }

  /// Seconds the current child has played today, including unsaved ones.
  int get secondsToday {
    final child = store.current;
    if (child == null) return 0;
    return child.secondsOn(dayNumber(store.now())) + _unsaved;
  }

  /// True when a daily limit is set and the current child has used it up.
  bool get limitReached {
    final limit = settings.dailyLimitMinutes;
    return limit > 0 && secondsToday >= limit * 60;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (!_foreground) flush();
  }

  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
  }
}
