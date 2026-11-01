import 'package:labeeb_ads/labeeb_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../progress/srs.dart';
import 'monetization.dart';
import 'purchase_service.dart';

/// The rules for showing an ad in a children's app. Pure, so it is easy to test.
abstract final class AdPolicy {
  /// At most one ad every four minutes.
  static const minGap = Duration(minutes: 4);

  static bool canShow({
    required bool adsEnabled,
    required bool purchased,
    required DateTime now,
    required int firstDay,
    DateTime? lastShown,
  }) {
    if (!adsEnabled || purchased) return false;
    // Never on the day the app is first used: the first impression is the app, not an ad.
    if (dayNumber(now) <= firstDay) return false;
    return lastShown == null || now.difference(lastShown) >= minGap;
  }
}

/// Where ads come from; the real one is [LabeebAds], tests use a fake.
abstract class AdBackend {
  Future<bool> initialize();
  Future<bool> load(String adUnitId);
  Future<bool> isLoaded();
  Future<bool> show();
}

class AdMobBackend implements AdBackend {
  const AdMobBackend();
  static const _ads = LabeebAds();

  @override
  Future<bool> initialize() => _ads.initialize();
  @override
  Future<bool> load(String adUnitId) => _ads.load(adUnitId);
  @override
  Future<bool> isLoaded() => _ads.isLoaded();
  @override
  Future<bool> show() => _ads.show();
}

/// No ads at all (iOS, tests, or before the SDK is ready).
class NoAdBackend implements AdBackend {
  const NoAdBackend();
  @override
  Future<bool> initialize() async => false;
  @override
  Future<bool> load(String adUnitId) async => false;
  @override
  Future<bool> isLoaded() async => false;
  @override
  Future<bool> show() async => false;
}

/// Shows an interstitial only at natural breaks (after a lesson's
/// celebration) and only when [AdPolicy] allows it.
class AdsController {
  AdsController({
    required this.monetization,
    required this.purchases,
    this.backend = const NoAdBackend(),
    DateTime Function()? now,
  }) : now = now ?? DateTime.now;

  static const _firstDayKey = 'ads.firstDay';
  static const _lastShownKey = 'ads.lastShown';

  final Monetization monetization;
  final PurchaseService purchases;
  final AdBackend backend;
  final DateTime Function() now;

  SharedPreferences? _prefs;
  bool _ready = false;

  bool get _wanted => monetization.ads && !purchases.owned;

  int get _firstDay => _prefs?.getInt(_firstDayKey) ?? dayNumber(now());
  DateTime? get _lastShown {
    final ms = _prefs?.getInt(_lastShownKey);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  /// Remembers the first day of use; prepares an ad when one may be shown later.
  Future<void> start() async {
    final prefs = _prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_firstDayKey)) {
      await prefs.setInt(_firstDayKey, dayNumber(now()));
    }
    if (!_wanted) return;
    _ready = await backend.initialize();
    if (_ready) await backend.load(interstitialAdUnitId);
  }

  bool get mayShowNow => AdPolicy.canShow(
    adsEnabled: monetization.ads,
    purchased: purchases.owned,
    now: now(),
    firstDay: _firstDay,
    lastShown: _lastShown,
  );

  /// Call at a natural break. Shows an ad if allowed and ready, and completes
  /// when it has been closed. Never throws, never blocks for long.
  Future<void> atNaturalBreak() async {
    if (!_ready || !mayShowNow || !await backend.isLoaded()) return;
    if (await backend.show()) {
      await _prefs?.setInt(_lastShownKey, now().millisecondsSinceEpoch);
    }
    if (_wanted) await backend.load(interstitialAdUnitId);
  }
}
