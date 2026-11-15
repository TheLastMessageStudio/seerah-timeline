import '../l10n/strings.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// Achat unique « Seerah Timeline Premium » (Google Play Billing).
/// Le statut Premium vient UNIQUEMENT du store (achat / restauration),
/// jamais d'une simple préférence locale.
class PurchaseService extends ChangeNotifier {
  static const productId = 'seerah_timeline_premium';

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;

  bool storeAvailable = false;
  bool premium = false;
  bool busy = false;
  String? error;
  ProductDetails? product;

  Future<void> init() async {
    try {
      storeAvailable = await _iap.isAvailable();
      if (!storeAvailable) {
        notifyListeners();
        return;
      }
      _sub = _iap.purchaseStream.listen(
        _onPurchases,
        onError: (Object e) {
          busy = false;
          error = tr('err_payment', {'e': e});
          notifyListeners();
        },
      );
      final resp = await _iap.queryProductDetails({productId});
      if (resp.productDetails.isNotEmpty) product = resp.productDetails.first;
      await _iap.restorePurchases();
    } catch (e) {
      error = tr('err_store', {'e': e});
    }
    notifyListeners();
  }

  Future<void> buy() async {
    if (product == null) {
      error = tr('err_unavailable');
      notifyListeners();
      return;
    }
    busy = true;
    error = null;
    notifyListeners();
    try {
      await _iap.buyNonConsumable(purchaseParam: PurchaseParam(productDetails: product!));
    } catch (e) {
      busy = false;
      error = tr('err_buy', {'e': e});
      notifyListeners();
    }
  }

  Future<void> restore() async {
    busy = true;
    error = null;
    notifyListeners();
    try {
      await _iap.restorePurchases();
    } catch (e) {
      error = tr('err_restore', {'e': e});
    }
    // Si aucun achat n'est renvoyé, on ne reste pas bloqué en attente.
    Future.delayed(const Duration(seconds: 6), () {
      if (busy) {
        busy = false;
        notifyListeners();
      }
    });
    notifyListeners();
  }

  Future<void> _onPurchases(List<PurchaseDetails> list) async {
    for (final p in list) {
      switch (p.status) {
        case PurchaseStatus.pending:
          busy = true;
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          if (p.productID == productId) premium = true;
          busy = false;
          break;
        case PurchaseStatus.error:
          busy = false;
          error = p.error?.message ?? tr('err_generic');
          break;
        case PurchaseStatus.canceled:
          busy = false;
          break;
      }
      if (p.pendingCompletePurchase) {
        await _iap.completePurchase(p);
      }
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
