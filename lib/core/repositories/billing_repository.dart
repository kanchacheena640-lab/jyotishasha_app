import '../models/asknow/asknow_contracts.dart';
import '../models/reports/report_contracts.dart';

/// Purpose: owns the platform-neutral purchase lifecycle boundary.
///
/// Responsibilities: expose availability and purchase updates, resolve product
/// details, start a consumable purchase, and acknowledge completion.
///
/// Excluded responsibilities: billing SDK types, AskNow/report verification,
/// entitlement policy, navigation, and presentation state.
///
/// Future implementation owner: ESR-003 billing repository implementation.
abstract interface class BillingRepository {
  Future<bool> isAvailable();

  Stream<ReportPurchaseReceipt> watchPurchases();

  Future<ChatPackProduct?> getProduct(String productId);

  Future<void> purchaseConsumable(ChatPackProduct product);

  /// S5.2 — starts a Google Play *subscription* purchase (`buyNonConsumable`
  /// under `in_app_purchase`, never auto-consumed — subscriptions are
  /// managed by Play's own renewal system, unlike [purchaseConsumable]'s
  /// one-shot consumables).
  Future<void> purchaseSubscription(ChatPackProduct product);

  /// S5.4 — asks Google Play to replay the user's already-owned
  /// purchases through the same purchase stream [watchPurchases]/a
  /// direct `purchaseStream` listener observes, as `PurchaseStatus.
  /// restored` events. Returns once Play has accepted the request, not
  /// once every restored purchase has actually been delivered — that
  /// still happens asynchronously via the stream, same as a fresh
  /// purchase.
  Future<void> restorePurchases();

  Future<void> completePurchase(ReportPurchaseReceipt receipt);
}
