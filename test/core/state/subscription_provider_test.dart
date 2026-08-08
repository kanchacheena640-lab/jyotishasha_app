import 'package:flutter_test/flutter_test.dart';

import 'package:jyotishasha_app/core/constants/subscription_products.dart';
import 'package:jyotishasha_app/core/models/asknow/asknow_contracts.dart';
import 'package:jyotishasha_app/core/models/reports/report_contracts.dart';
import 'package:jyotishasha_app/core/repositories/billing_repository.dart';
import 'package:jyotishasha_app/core/state/subscription_provider.dart';

/// Hand-rolled fake — `PlayBillingRepository` (the real implementation)
/// wraps `InAppPurchase.instance`, which throws "no platform
/// implementation" in this headless test environment (same limitation
/// documented for `InAppWebView`/`AskNowProvider` elsewhere in this
/// codebase). [SubscriptionProvider] accepts any [BillingRepository] via
/// constructor injection specifically so its own logic — query, start
/// purchase, error mapping — can be tested without a real platform.
class _FakeBillingRepository implements BillingRepository {
  bool available = true;
  final Map<String, ChatPackProduct> products = {};
  final List<String> purchaseSubscriptionCalls = [];
  Object? purchaseSubscriptionError;
  int restorePurchasesCalls = 0;
  Object? restorePurchasesError;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<ChatPackProduct?> getProduct(String productId) async =>
      products[productId];

  @override
  Future<void> purchaseConsumable(ChatPackProduct product) async {
    throw UnimplementedError('not used by SubscriptionProvider');
  }

  @override
  Future<void> purchaseSubscription(ChatPackProduct product) async {
    purchaseSubscriptionCalls.add(product.productId ?? '');
    if (purchaseSubscriptionError != null) throw purchaseSubscriptionError!;
  }

  @override
  Future<void> restorePurchases() async {
    restorePurchasesCalls++;
    if (restorePurchasesError != null) throw restorePurchasesError!;
  }

  @override
  Stream<ReportPurchaseReceipt> watchPurchases() => const Stream.empty();

  @override
  Future<void> completePurchase(ReportPurchaseReceipt receipt) async {}
}

void main() {
  group('SubscriptionProvider (S5.2 — Google Play purchase flow)', () {
    late _FakeBillingRepository billing;
    late SubscriptionProvider provider;

    setUp(() {
      billing = _FakeBillingRepository();
      provider = SubscriptionProvider(billing: billing);
    });

    test(
      'loadAvailableProducts populates availableProducts only from what '
      'the billing repository actually resolves — never a hardcoded list',
      () async {
        billing.products[SubscriptionProductIds.silverMonthly] =
            const ChatPackProduct(
              productId: 'jyotishasha.silver.monthly',
              title: 'Silver Monthly',
              price: '₹99',
            );
        // Others deliberately NOT stubbed — simulates Play not returning them.

        await provider.loadAvailableProducts();

        expect(provider.availableProducts.length, 1);
        expect(
          provider.availableProducts.first.productId,
          SubscriptionProductIds.silverMonthly,
        );
      },
    );

    test(
      'subscribeToPlan sets billing_unavailable and never calls '
      'purchaseSubscription when Play Billing is unavailable',
      () async {
        billing.available = false;

        await provider.subscribeToPlan(SubscriptionProductIds.silverMonthly);

        expect(provider.purchaseErrorMessage, 'billing_unavailable');
        expect(provider.isPurchasing, isFalse);
        expect(billing.purchaseSubscriptionCalls, isEmpty);
      },
    );

    test(
      'subscribeToPlan sets product_not_found when the product cannot be '
      'resolved from Play',
      () async {
        await provider.subscribeToPlan('unknown_product_id');

        expect(provider.purchaseErrorMessage, 'product_not_found');
        expect(provider.isPurchasing, isFalse);
        expect(billing.purchaseSubscriptionCalls, isEmpty);
      },
    );

    test(
      'subscribeToPlan starts the Play purchase sheet for a resolved '
      'product and leaves isPurchasing true — the result arrives '
      'asynchronously via the purchase stream, not this call',
      () async {
        billing.products[SubscriptionProductIds.silverYearly] =
            const ChatPackProduct(
              productId: 'jyotishasha.silver.yearly',
              title: 'Silver Yearly',
              price: '₹990',
            );

        await provider.subscribeToPlan(SubscriptionProductIds.silverYearly);

        expect(billing.purchaseSubscriptionCalls, [
          SubscriptionProductIds.silverYearly,
        ]);
        expect(provider.isPurchasing, isTrue);
        expect(provider.purchaseErrorMessage, isNull);
      },
    );

    test(
      'subscribeToPlan catches an exception from purchaseSubscription and '
      'never leaves isPurchasing stuck true',
      () async {
        billing.products[SubscriptionProductIds.silverMonthly] =
            const ChatPackProduct(
              productId: 'jyotishasha.silver.monthly',
              title: 'Silver Monthly',
              price: '₹99',
            );
        billing.purchaseSubscriptionError = Exception('play store error');

        await provider.subscribeToPlan(SubscriptionProductIds.silverMonthly);

        expect(provider.isPurchasing, isFalse);
        expect(
          provider.purchaseErrorMessage,
          contains('play store error'),
        );
      },
    );

    test(
      'a fresh provider has no purchase state set — starting point is '
      'clean, not a stale value from a previous attempt',
      () {
        expect(provider.isPurchasing, isFalse);
        expect(provider.purchaseErrorMessage, isNull);
        expect(provider.availableProducts, isEmpty);
      },
    );
  });

  group('SubscriptionProvider (S5.4 — Restore Purchases)', () {
    late _FakeBillingRepository billing;
    late SubscriptionProvider provider;

    setUp(() {
      billing = _FakeBillingRepository();
      provider = SubscriptionProvider(billing: billing);
    });

    test(
      'a fresh provider has no restore state set — starting point is '
      'clean, not a stale value from a previous attempt',
      () {
        expect(provider.isRestoring, isFalse);
        expect(provider.restoreErrorMessage, isNull);
      },
    );

    test(
      'restorePurchases sets billing_unavailable and never calls '
      'BillingRepository.restorePurchases when Play Billing is '
      'unavailable — same early-exit shape as subscribeToPlan',
      () async {
        billing.available = false;

        await provider.restorePurchases();

        expect(provider.restoreErrorMessage, 'billing_unavailable');
        expect(provider.isRestoring, isFalse);
        expect(billing.restorePurchasesCalls, 0);
      },
    );

    test(
      'restorePurchases never leaves isRestoring stuck true, even when '
      'the environment cannot resolve an authenticated user (this '
      'headless test environment has no real FirebaseAuth app, so this '
      'also exercises the not-authenticated/unexpected-failure error '
      'path exactly as a real "not signed in" case would)',
      () async {
        await provider.restorePurchases();

        expect(provider.isRestoring, isFalse);
        expect(provider.restoreErrorMessage, isNotNull);
      },
    );

    test(
      'restorePurchases never bypasses the billing-availability check — '
      'it is always consulted before anything else, matching '
      'subscribeToPlan',
      () async {
        billing.available = false;

        await provider.restorePurchases();

        // Confirms the guard order: availability is checked first, so a
        // billing-unavailable environment never reaches (and never
        // needs) authentication or Play Billing at all.
        expect(provider.restoreErrorMessage, 'billing_unavailable');
      },
    );
  });

  group('interpretConfirmResponse (S5.X — google/confirm outcome handling)', () {
    test('activated == true is success regardless of outcome value', () {
      final result = interpretConfirmResponse({
        'status': 'VERIFIED',
        'outcome': 'ACTIVATED',
        'activated': true,
      });

      expect(result.kind, ConfirmResultKind.success);
      expect(result.warningCode, isNull);
    });

    test('status == DUPLICATE is success even without an outcome field', () {
      final result = interpretConfirmResponse({
        'status': 'DUPLICATE',
        'message': 'already processed',
      });

      expect(result.kind, ConfirmResultKind.success);
      expect(result.warningCode, isNull);
    });

    test(
      'outcome == PENDING with activated == false is a warning, not a '
      'silent success — this was the confirmed bug (previously any 2xx '
      'was treated as unconditional success)',
      () {
        final result = interpretConfirmResponse({
          'status': 'VERIFIED',
          'outcome': 'PENDING',
          'activated': false,
        });

        expect(result.kind, ConfirmResultKind.warning);
        expect(result.warningCode, 'activation_pending');
      },
    );

    for (final outcome in [
      'NOT_ACTIVATED',
      'UNMAPPED_PRODUCT',
      'ACTIVATION_FAILED',
    ]) {
      test(
        'outcome == $outcome with activated == false maps to '
        'activation_incomplete',
        () {
          final result = interpretConfirmResponse({
            'status': 'VERIFIED',
            'outcome': outcome,
            'activated': false,
          });

          expect(result.kind, ConfirmResultKind.warning);
          expect(result.warningCode, 'activation_incomplete');
        },
      );
    }
  });
}
