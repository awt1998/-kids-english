import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Android-only AdMob interstitials, always child-directed, G-rated and
/// non-personalised (configured natively). On other platforms every call is a
/// harmless no-op, and the iOS app contains no ads code at all.
class LabeebAds {
  const LabeebAds();

  static const _channel = MethodChannel('labeeb_ads');

  bool get supported => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<bool> initialize() => _call('initialize');
  Future<bool> load(String adUnitId) => _call('load', {'adUnitId': adUnitId});
  Future<bool> isLoaded() => _call('isLoaded');

  /// Shows the loaded ad and completes once the parent/child has closed it.
  Future<bool> show() => _call('show');

  Future<bool> _call(String method, [Map<String, Object?>? args]) async {
    if (!supported) return false;
    try {
      return await _channel.invokeMethod<bool>(method, args) ?? false;
    } on PlatformException {
      return false;
    }
  }
}
