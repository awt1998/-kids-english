import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Parent settings for this device, saved locally.
class AppSettings extends ChangeNotifier {
  AppSettings._(this._prefs);

  static const _sfxKey = 'settings.sfx';
  static const _musicKey = 'settings.music';
  static const _limitKey = 'settings.dailyLimitMinutes';

  /// Daily play limits a parent can choose; 0 = no limit.
  static const limitChoices = [0, 15, 30, 45, 60];

  final SharedPreferences _prefs;

  static Future<AppSettings> load() async =>
      AppSettings._(await SharedPreferences.getInstance());

  bool get soundEffects => _prefs.getBool(_sfxKey) ?? true;
  bool get music => _prefs.getBool(_musicKey) ?? true;

  /// Minutes of play allowed per child per day; 0 = no limit.
  int get dailyLimitMinutes => _prefs.getInt(_limitKey) ?? 0;

  Future<void> setSoundEffects(bool on) =>
      _set(() => _prefs.setBool(_sfxKey, on));
  Future<void> setMusic(bool on) => _set(() => _prefs.setBool(_musicKey, on));
  Future<void> setDailyLimitMinutes(int minutes) =>
      _set(() => _prefs.setInt(_limitKey, minutes));

  Future<void> _set(Future<bool> Function() write) async {
    await write();
    notifyListeners();
  }
}
