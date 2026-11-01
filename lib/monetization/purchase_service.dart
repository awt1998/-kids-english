import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The store calls the app needs; [InAppPurchaseBackend] is the real one.
abstract class PurchaseBackend {
  Stream<List<PurchaseDetails>> get purchaseStream;
  Future<bool> isAvailable();
  Future<ProductDetailsResponse> queryProductDetails(Set<String> ids);
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam});
  Future<void> restorePurchases();
  Future<void> completePurchase(PurchaseDetails purchase);
}

class InAppPurchaseBackend implements PurchaseBackend {
  InAppPurchase get _iap => InAppPurchase.instance;
  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _iap.purchaseStream;
  @override
  Future<bool> isAvailable() => _iap.isAvailable();
  @override
  Future<ProductDetailsResponse> queryProductDetails(Set<String> ids) =>
      _iap.queryProductDetails(ids);
  @override
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam}) =>
      _iap.buyNonConsumable(purchaseParam: purchaseParam);
  @override
  Future<void> restorePurchases() => _iap.restorePurchases();
  @override
  Future<void> completePurchase(PurchaseDetails purchase) =>
      _iap.completePurchase(purchase);
}

/// A store that is never available (tests, emulators without Play).
class OfflinePurchaseBackend implements PurchaseBackend {
  @override
  Stream<List<PurchaseDetails>> get purchaseStream => const Stream.empty();
  @override
  Future<bool> isAvailable() async => false;
  @override
  Future<ProductDetailsResponse> queryProductDetails(Set<String> ids) async =>
      ProductDetailsResponse(
        productDetails: const [],
        notFoundIDs: ids.toList(),
      );
  @override
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam}) async =>
      false;
  @override
  Future<void> restorePurchases() async {}
  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {}
}

enum PurchaseStatusView { idle, buying, failed }

/// The single one-time purchase ("remove ads" on Android, "unlock all" on
/// iOS). Ownership is cached on the device and confirmed again from the store.
class PurchaseService extends ChangeNotifier {
  PurchaseService({required this.productId, PurchaseBackend? backend})
    : backend = backend ?? OfflinePurchaseBackend();

  static const _ownedKey = 'purchase.owned';

  final String productId;
  final PurchaseBackend backend;

  SharedPreferences? _prefs;
  StreamSubscription<List<PurchaseDetails>>? _sub;
  ProductDetails? _product;
  bool _owned = false;
  PurchaseStatusView _status = PurchaseStatusView.idle;

  bool get owned => _owned;
  ProductDetails? get product => _product;

  /// The store's own localised price, e.g. "SAR 11.99".
  String? get price => _product?.price;
  PurchaseStatusView get status => _status;

  Future<void> start({bool restoreQuietly = false}) async {
    _prefs = await SharedPreferences.getInstance();
    _owned = _prefs!.getBool(_ownedKey) ?? false;
    _sub = backend.purchaseStream.listen(
      _onPurchases,
      onError: (_) => _setStatus(PurchaseStatusView.failed),
    );
    if (await backend.isAvailable()) {
      final res = await backend.queryProductDetails({productId});
      _product = res.productDetails.where((p) => p.id == productId).firstOrNull;
      // Android: silently re-sync after a reinstall. iOS only restores when asked.
      if (restoreQuietly) await backend.restorePurchases();
    }
    notifyListeners();
  }

  Future<void> buy() async {
    final product = _product;
    if (product == null || _owned) return;
    _setStatus(PurchaseStatusView.buying);
    final started = await backend.buyNonConsumable(
      purchaseParam: PurchaseParam(productDetails: product),
    );
    if (!started) _setStatus(PurchaseStatusView.failed);
  }

  Future<void> restore() => backend.restorePurchases();

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final p in purchases.where((p) => p.productID == productId)) {
      switch (p.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          _owned = true;
          await _prefs?.setBool(_ownedKey, true);
          _setStatus(PurchaseStatusView.idle);
        case PurchaseStatus.pending:
          _setStatus(PurchaseStatusView.buying);
        case PurchaseStatus.error:
          _setStatus(PurchaseStatusView.failed);
        case PurchaseStatus.canceled:
          _setStatus(PurchaseStatusView.idle);
      }
      // The store refunds purchases that are never acknowledged.
      if (p.pendingCompletePurchase) await backend.completePurchase(p);
    }
  }

  void _setStatus(PurchaseStatusView s) {
    _status = s;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
