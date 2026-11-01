import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:kids_english/app.dart';
import 'package:kids_english/audio/audio_service.dart';
import 'package:kids_english/content/content_repository.dart';
import 'package:kids_english/content/models.dart';
import 'package:kids_english/features/parents/parental_gate.dart';
import 'package:kids_english/monetization/ads_controller.dart';
import 'package:kids_english/monetization/monetization.dart';
import 'package:kids_english/monetization/purchase_service.dart';
import 'package:kids_english/progress/app_settings.dart';
import 'package:kids_english/progress/profiles_store.dart';
import 'package:kids_english/progress/srs.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeAds implements AdBackend {
  int shown = 0;
  int loads = 0;
  @override
  Future<bool> initialize() async => true;
  @override
  Future<bool> load(String adUnitId) async {
    loads++;
    return true;
  }

  @override
  Future<bool> isLoaded() async => true;
  @override
  Future<bool> show() async {
    shown++;
    return true;
  }
}

class FakeStore implements PurchaseBackend {
  final controller = StreamController<List<PurchaseDetails>>.broadcast();
  final completed = <String>[];
  bool restoreWouldFind = false;

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => controller.stream;
  @override
  Future<bool> isAvailable() async => true;
  @override
  Future<ProductDetailsResponse> queryProductDetails(Set<String> ids) async =>
      ProductDetailsResponse(
        productDetails: [
          for (final id in ids)
            ProductDetails(
              id: id,
              title: id,
              description: '',
              price: 'SAR 11.99',
              rawPrice: 11.99,
              currencyCode: 'SAR',
            ),
        ],
        notFoundIDs: const [],
      );
  @override
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam}) async {
    controller.add([
      _details(purchaseParam.productDetails.id, PurchaseStatus.purchased),
    ]);
    return true;
  }

  @override
  Future<void> restorePurchases() async {
    if (restoreWouldFind) {
      controller.add([_details('remove_ads', PurchaseStatus.restored)]);
    }
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async =>
      completed.add(purchase.productID);

  PurchaseDetails _details(String id, PurchaseStatus status) => PurchaseDetails(
    productID: id,
    verificationData: PurchaseVerificationData(
      localVerificationData: '',
      serverVerificationData: '',
      source: 'test',
    ),
    transactionDate: '0',
    status: status,
  )..pendingCompletePurchase = true;
}

void main() {
  final day1 = DateTime(2026, 6, 1, 9);

  group('ad rules', () {
    bool can({
      bool ads = true,
      bool purchased = false,
      DateTime? now,
      DateTime? last,
    }) => AdPolicy.canShow(
      adsEnabled: ads,
      purchased: purchased,
      now: now ?? day1.add(const Duration(days: 1)),
      firstDay: dayNumber(day1),
      lastShown: last,
    );

    test(
      'never on the first day of use',
      () => expect(can(now: day1.add(const Duration(hours: 10))), isFalse),
    );
    test('allowed from the next day', () => expect(can(), isTrue));
    test(
      'never after "remove ads" was bought',
      () => expect(can(purchased: true), isFalse),
    );
    test(
      'never where ads are off (iOS)',
      () => expect(can(ads: false), isFalse),
    );
    test('at most one every four minutes', () {
      final now = day1.add(const Duration(days: 2));
      expect(
        can(now: now, last: now.subtract(const Duration(minutes: 3))),
        isFalse,
      );
      expect(
        can(now: now, last: now.subtract(const Duration(minutes: 4))),
        isTrue,
      );
    });
  });

  group('ads controller', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('shows only at allowed breaks and records the time', () async {
      var now = day1;
      final ads = FakeAds();
      final purchases = PurchaseService(productId: 'remove_ads');
      await purchases.start();
      final c = AdsController(
        monetization: Monetization.android,
        purchases: purchases,
        backend: ads,
        now: () => now,
      );
      await c.start();
      await c.atNaturalBreak();
      expect(ads.shown, 0, reason: 'first day');

      now = day1.add(const Duration(days: 1));
      await c.atNaturalBreak();
      expect(ads.shown, 1);
      now = now.add(const Duration(minutes: 2));
      await c.atNaturalBreak();
      expect(ads.shown, 1, reason: 'too soon');
      now = now.add(const Duration(minutes: 3));
      await c.atNaturalBreak();
      expect(ads.shown, 2);
    });

    test('iOS never loads or shows an ad', () async {
      final ads = FakeAds();
      final purchases = PurchaseService(productId: 'unlock_all');
      await purchases.start();
      final c = AdsController(
        monetization: Monetization.ios,
        purchases: purchases,
        backend: ads,
        now: () => day1.add(const Duration(days: 5)),
      );
      await c.start();
      await c.atNaturalBreak();
      expect(ads.loads, 0);
      expect(ads.shown, 0);
    });
  });

  group('purchase', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test(
      'buying unlocks, acknowledges the purchase, and is remembered',
      () async {
        final store = FakeStore();
        final s = PurchaseService(productId: 'remove_ads', backend: store);
        await s.start();
        expect(s.price, 'SAR 11.99');
        expect(s.owned, isFalse);
        await s.buy();
        await pumpEventQueue();
        expect(s.owned, isTrue);
        expect(store.completed, ['remove_ads']);

        final again = PurchaseService(
          productId: 'remove_ads',
          backend: FakeStore(),
        );
        await again.start();
        expect(again.owned, isTrue, reason: 'remembered on the device');
      },
    );

    test('restore finds an earlier purchase', () async {
      final store = FakeStore()..restoreWouldFind = true;
      final s = PurchaseService(productId: 'remove_ads', backend: store);
      await s.start();
      await s.restore();
      await pumpEventQueue();
      expect(s.owned, isTrue);
    });
  });

  testWidgets('iOS: units after the free ones need a parent to unlock', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1180, 820);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final content = (await tester.runAsync(ContentRepository.load))!;
    final profiles = (await tester.runAsync(ProfilesStore.load))!;
    final settings = (await tester.runAsync(AppSettings.load))!;
    final child = (await tester.runAsync(
      () => profiles.addChild(avatar: 'cat', level: AgeLevel.little),
    ))!;
    // Finish the first three units so the fourth would normally be open.
    for (final u in content.unitsFor(AgeLevel.little).take(3)) {
      for (final l in ContentRepository.lessonsFor(u)) {
        child.lessonStars[l.key] = 3;
      }
    }
    final purchases = PurchaseService(productId: 'unlock_all');
    await tester.runAsync(purchases.start);
    await tester.pumpWidget(
      KidsEnglishApp(
        content: content,
        profiles: profiles,
        audio: SilentAudioService(),
        settings: settings,
        monetization: Monetization.ios,
        purchases: purchases,
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));
    await tester.tap(find.byKey(ValueKey(child.id)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    final fourth = content.unitsFor(AgeLevel.little)[3];
    final stop = find.byKey(ValueKey('stop-${fourth.id}:0'));
    await tester.scrollUntilVisible(stop, 300);
    await tester.tap(stop);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(
      find.byType(ParentalGateScreen),
      findsOneWidget,
      reason: 'the child is sent to a parent, not to a lesson',
    );
  });
}
