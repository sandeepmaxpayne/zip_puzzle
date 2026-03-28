import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../models/purchase_record.dart';
import 'monetization_config.dart';

class MonetizationEntitlement {
  const MonetizationEntitlement({
    required this.productId,
    required this.purchaseRecord,
  });

  final String productId;
  final PurchaseRecord purchaseRecord;
}

class MonetizationService {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  final Map<String, ProductDetails> _products = <String, ProductDetails>{};
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  Future<void> Function(MonetizationEntitlement entitlement)? _onEntitlement;

  bool _initialized = false;
  bool _billingAvailable = false;

  bool get isBillingAvailable => _billingAvailable;

  List<ProductDetails> get products => _products.values.toList()
    ..sort((a, b) => a.title.compareTo(b.title));

  Future<void> initialize({
    required Future<void> Function(MonetizationEntitlement entitlement)
        onEntitlement,
  }) async {
    if (_initialized) {
      return;
    }
    _initialized = true;
    _onEntitlement = onEntitlement;

    final isMobileTarget = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);

    try {
      if (!isMobileTarget) {
        return;
      }

      _billingAvailable = await _inAppPurchase.isAvailable();
      if (!_billingAvailable) {
        return;
      }

      _purchaseSubscription = _inAppPurchase.purchaseStream.listen(
        _handlePurchaseUpdates,
        onDone: () => _purchaseSubscription?.cancel(),
        onError: (_) {},
      );

      final response = await _inAppPurchase.queryProductDetails(
        <String>{
          MonetizationConfig.advanceUnlockProductId,
          MonetizationConfig.streakFreezeProductId,
        },
      );
      for (final product in response.productDetails) {
        _products[product.id] = product;
      }
    } catch (_) {
      _billingAvailable = false;
    }
  }

  Future<bool> buyProduct(String productId) async {
    final product = _products[productId];
    if (!_billingAvailable || product == null) {
      return false;
    }
    final param = PurchaseParam(productDetails: product);
    return _inAppPurchase.buyConsumable(purchaseParam: param);
  }

  Future<void> _handlePurchaseUpdates(
    List<PurchaseDetails> purchaseDetailsList,
  ) async {
    for (final purchase in purchaseDetailsList) {
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        final purchaseRecord = PurchaseRecord(
          productId: purchase.productID,
          purchaseId: purchase.purchaseID ?? '',
          purchaseToken: purchase.verificationData.serverVerificationData,
          status: purchase.status.name,
          amountLabel: _products[purchase.productID]?.price ?? 'Managed in Play',
          grantedAtIso: DateTime.now().toUtc().toIso8601String(),
          source: 'google_play_billing',
        );
        if (_onEntitlement != null) {
          await _onEntitlement!(
            MonetizationEntitlement(
              productId: purchase.productID,
              purchaseRecord: purchaseRecord,
            ),
          );
        }
      }

      if (purchase.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchase);
      }
    }
  }

  Future<void> dispose() async {
    await _purchaseSubscription?.cancel();
  }
}
