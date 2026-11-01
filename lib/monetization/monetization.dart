import 'package:flutter/foundation.dart';

/// How the app earns money on each store (decided with the owner):
/// - Android: free with child-safe ads; one purchase removes them.
/// - iOS (Kids Category, no third-party ads allowed): the first units are
///   free; one purchase unlocks everything.
class Monetization {
  const Monetization._({
    required this.ads,
    required this.productId,
    required this.freeUnits,
  });

  static const android = Monetization._(
    ads: true,
    productId: 'remove_ads',
    freeUnits: null,
  );
  static const ios = Monetization._(
    ads: false,
    productId: 'unlock_all',
    freeUnits: 3,
  );

  static Monetization get current =>
      defaultTargetPlatform == TargetPlatform.iOS ? ios : android;

  /// Interstitial ads at natural breaks, until the purchase is made.
  final bool ads;

  /// The one non-consumable product sold in the Parent Zone.
  final String productId;

  /// Units (in map order) playable without the purchase; null = all of them.
  final int? freeUnits;
}

/// AdMob ad unit for the interstitial. Defaults to Google's public test unit;
/// release builds pass the real one with --dart-define=ADMOB_INTERSTITIAL=...
const interstitialAdUnitId = String.fromEnvironment(
  'ADMOB_INTERSTITIAL',
  defaultValue: 'ca-app-pub-3940256099942544/1033173712',
);
