import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'audio/audio_service.dart';
import 'content/content_repository.dart';
import 'monetization/ads_controller.dart';
import 'monetization/monetization.dart';
import 'monetization/purchase_service.dart';
import 'progress/app_settings.dart';
import 'progress/profiles_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  final content = await ContentRepository.load();
  final profiles = await ProfilesStore.load();
  final settings = await AppSettings.load();
  final monetization = Monetization.current;
  final purchases = PurchaseService(
    productId: monetization.productId,
    backend: InAppPurchaseBackend(),
  );
  final ads = AdsController(
    monetization: monetization,
    purchases: purchases,
    backend: monetization.ads ? const AdMobBackend() : const NoAdBackend(),
  );
  // Store and ads start in the background; the app never waits for them.
  unawaited(
    purchases.start(restoreQuietly: monetization.ads).then((_) => ads.start()),
  );
  runApp(
    KidsEnglishApp(
      content: content,
      profiles: profiles,
      audio: AudioPlayersService(),
      settings: settings,
      monetization: monetization,
      purchases: purchases,
      ads: ads,
    ),
  );
}
