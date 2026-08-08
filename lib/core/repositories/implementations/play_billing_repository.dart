import 'package:in_app_purchase/in_app_purchase.dart';

import '../../models/asknow/asknow_contracts.dart';
import '../../models/reports/report_contracts.dart';
import '../billing_repository.dart';

final class PlayBillingRepository implements BillingRepository {
  PlayBillingRepository({InAppPurchase? billing})
    : _billing = billing ?? InAppPurchase.instance;

  final InAppPurchase _billing;
  final Map<String, ProductDetails> _products = {};
  final Map<String, PurchaseDetails> _purchases = {};

  @override
  Future<bool> isAvailable() => _billing.isAvailable();

  @override
  Stream<ReportPurchaseReceipt> watchPurchases() =>
      _billing.purchaseStream.expand((purchases) => purchases).map((purchase) {
        final token = purchase.verificationData.serverVerificationData;
        _purchases[token] = purchase;
        return ReportPurchaseReceipt(
          product: purchase.productID,
          purchaseToken: token,
        );
      });

  @override
  Future<ChatPackProduct?> getProduct(String productId) async {
    final response = await _billing.queryProductDetails({productId});
    if (response.productDetails.isEmpty) return null;
    final product = response.productDetails.first;
    _products[product.id] = product;
    return ChatPackProduct(
      productId: product.id,
      title: product.title,
      price: product.price,
    );
  }

  @override
  Future<void> purchaseConsumable(ChatPackProduct product) async {
    final productId = product.productId;
    if (productId == null || productId.isEmpty) {
      throw ArgumentError.value(productId, 'product.productId');
    }
    var details = _products[productId];
    if (details == null) {
      await getProduct(productId);
      details = _products[productId];
    }
    if (details == null) throw StateError('Product not found: $productId');
    await _billing.buyConsumable(
      purchaseParam: PurchaseParam(productDetails: details),
      autoConsume: true,
    );
  }

  @override
  Future<void> purchaseSubscription(ChatPackProduct product) async {
    final productId = product.productId;
    if (productId == null || productId.isEmpty) {
      throw ArgumentError.value(productId, 'product.productId');
    }
    var details = _products[productId];
    if (details == null) {
      await getProduct(productId);
      details = _products[productId];
    }
    if (details == null) throw StateError('Product not found: $productId');
    // No `autoConsume` param — subscriptions are non-consumable; Play's
    // own subscription lifecycle (renewal/expiry) owns it from here.
    await _billing.buyNonConsumable(
      purchaseParam: PurchaseParam(productDetails: details),
    );
  }

  @override
  Future<void> restorePurchases() => _billing.restorePurchases();

  @override
  Future<void> completePurchase(ReportPurchaseReceipt receipt) async {
    final token = receipt.purchaseToken;
    final purchase = token == null ? null : _purchases[token];
    if (purchase == null) throw StateError('Purchase receipt not observed');
    if (purchase.pendingCompletePurchase) {
      await _billing.completePurchase(purchase);
    }
  }
}
