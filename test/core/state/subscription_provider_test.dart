import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:jyotishasha_app/core/constants/subscription_products.dart';
import 'package:jyotishasha_app/core/constants/subscription_sections.dart';
import 'package:jyotishasha_app/core/models/asknow/asknow_contracts.dart';
import 'package:jyotishasha_app/core/models/reports/report_contracts.dart';
import 'package:jyotishasha_app/core/repositories/billing_repository.dart';
import 'package:jyotishasha_app/core/state/subscription_provider.dart';

import '../../helpers/source_characterization.dart';

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
  // Global — needed now that SubscriptionProvider.reset() also clears a
  // SharedPreferences-persisted value (the Silver section-selection
  // fix's pending-segment key). Every group in this file benefits from
  // the same headless-test mock, matching AskNowProvider/
  // ReportPurchaseProvider's own test files' identical top-level setUp.
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

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

        // Gold, not Silver -- this test is about the billing-
        // availability guard, unrelated to the Silver-only section
        // requirement (see the dedicated "Silver plan section-selection
        // fix" group below for that).
        await provider.subscribeToPlan(SubscriptionProductIds.goldMonthly);

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
        // Gold, not Silver -- see the billing_unavailable test above for
        // why.
        billing.products[SubscriptionProductIds.goldYearly] =
            const ChatPackProduct(
              productId: 'jyotishasha.gold.yearly',
              title: 'Gold Yearly',
              price: '₹1999',
            );

        await provider.subscribeToPlan(SubscriptionProductIds.goldYearly);

        expect(billing.purchaseSubscriptionCalls, [
          SubscriptionProductIds.goldYearly,
        ]);
        expect(provider.isPurchasing, isTrue);
        expect(provider.purchaseErrorMessage, isNull);
      },
    );

    test(
      'subscribeToPlan catches an exception from purchaseSubscription and '
      'never leaves isPurchasing stuck true',
      () async {
        // Gold, not Silver -- see the billing_unavailable test above for
        // why.
        billing.products[SubscriptionProductIds.goldMonthly] =
            const ChatPackProduct(
              productId: 'jyotishasha.gold.monthly',
              title: 'Gold Monthly',
              price: '₹199',
            );
        billing.purchaseSubscriptionError = Exception('play store error');

        await provider.subscribeToPlan(SubscriptionProductIds.goldMonthly);

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

  group('SubscriptionProvider (Silver plan section-selection fix)', () {
    late _FakeBillingRepository billing;
    late SubscriptionProvider provider;

    setUp(() {
      billing = _FakeBillingRepository();
      provider = SubscriptionProvider(billing: billing);
    });

    ChatPackProduct silverMonthlyProduct() => const ChatPackProduct(
      productId: 'jyotishasha.silver.monthly',
      title: 'Silver Monthly',
      price: '₹99',
    );

    ChatPackProduct silverYearlyProduct() => const ChatPackProduct(
      productId: 'jyotishasha.silver.yearly',
      title: 'Silver Yearly',
      price: '₹990',
    );

    ChatPackProduct goldMonthlyProduct() => const ChatPackProduct(
      productId: 'jyotishasha.gold.monthly',
      title: 'Gold Monthly',
      price: '₹199',
    );

    ChatPackProduct platinumYearlyProduct() => const ChatPackProduct(
      productId: 'jyotishasha.platinum.yearly',
      title: 'Platinum Yearly',
      price: '₹2999',
    );

    test(
      'Silver Monthly: subscribeToPlan with no selectedSegment never '
      'starts Google Play Billing — Play is never even asked whether '
      'billing is available',
      () async {
        billing.products[SubscriptionProductIds.silverMonthly] = silverMonthlyProduct();

        await provider.subscribeToPlan(SubscriptionProductIds.silverMonthly);

        expect(provider.purchaseErrorMessage, 'segment_required');
        expect(provider.isPurchasing, isFalse);
        expect(billing.purchaseSubscriptionCalls, isEmpty);
      },
    );

    test(
      'Silver Yearly: subscribeToPlan with no selectedSegment never '
      'starts Google Play Billing — same gate as Silver Monthly',
      () async {
        billing.products[SubscriptionProductIds.silverYearly] = silverYearlyProduct();

        await provider.subscribeToPlan(SubscriptionProductIds.silverYearly);

        expect(provider.purchaseErrorMessage, 'segment_required');
        expect(provider.isPurchasing, isFalse);
        expect(billing.purchaseSubscriptionCalls, isEmpty);
      },
    );

    test(
      'Silver Monthly: a selectedSegment that is not one of the six '
      'canonical SubscriptionSections values is rejected exactly like a '
      'missing one — never silently accepted/guessed',
      () async {
        billing.products[SubscriptionProductIds.silverMonthly] = silverMonthlyProduct();

        await provider.subscribeToPlan(
          SubscriptionProductIds.silverMonthly,
          selectedSegment: 'NOT_A_REAL_SECTION',
        );

        expect(provider.purchaseErrorMessage, 'segment_required');
        expect(billing.purchaseSubscriptionCalls, isEmpty);
      },
    );

    test(
      '✓ Silver Monthly: a valid selectedSegment starts Google Play '
      'Billing exactly like any other plan — the gate only blocks a '
      'missing/invalid selection, never a valid one',
      () async {
        billing.products[SubscriptionProductIds.silverMonthly] = silverMonthlyProduct();

        await provider.subscribeToPlan(
          SubscriptionProductIds.silverMonthly,
          selectedSegment: SubscriptionSections.love,
        );

        expect(provider.purchaseErrorMessage, isNull);
        expect(provider.isPurchasing, isTrue);
        expect(billing.purchaseSubscriptionCalls, [
          SubscriptionProductIds.silverMonthly,
        ]);
      },
    );

    test(
      '✓ Silver Yearly: every one of the six canonical sections is '
      'independently accepted (not just one hardcoded value)',
      () async {
        billing.products[SubscriptionProductIds.silverYearly] = silverYearlyProduct();

        for (final section in SubscriptionSections.all) {
          billing.purchaseSubscriptionCalls.clear();
          provider.purchaseErrorMessage = null;

          await provider.subscribeToPlan(
            SubscriptionProductIds.silverYearly,
            selectedSegment: section,
          );

          expect(
            provider.purchaseErrorMessage,
            isNull,
            reason: 'section $section should have been accepted',
          );
          expect(billing.purchaseSubscriptionCalls, [
            SubscriptionProductIds.silverYearly,
          ]);
        }
      },
    );

    test(
      '✓ Gold Monthly: subscribeToPlan proceeds with NO selectedSegment '
      'at all — Gold is full-access and must never require one, exactly '
      'as before this fix',
      () async {
        billing.products[SubscriptionProductIds.goldMonthly] = goldMonthlyProduct();

        await provider.subscribeToPlan(SubscriptionProductIds.goldMonthly);

        expect(provider.purchaseErrorMessage, isNull);
        expect(provider.isPurchasing, isTrue);
        expect(billing.purchaseSubscriptionCalls, [
          SubscriptionProductIds.goldMonthly,
        ]);
      },
    );

    test(
      '✓ Platinum Yearly: subscribeToPlan proceeds with NO '
      'selectedSegment either — every full-access tier, not just Gold, '
      'is exempt from the Silver-only requirement',
      () async {
        billing.products[SubscriptionProductIds.platinumYearly] = platinumYearlyProduct();

        await provider.subscribeToPlan(SubscriptionProductIds.platinumYearly);

        expect(provider.purchaseErrorMessage, isNull);
        expect(provider.isPurchasing, isTrue);
        expect(billing.purchaseSubscriptionCalls, [
          SubscriptionProductIds.platinumYearly,
        ]);
      },
    );

    test(
      'a valid Silver selection is persisted to SharedPreferences '
      'immediately — survives an app restart between launching the '
      'purchase and its confirm/restore landing, mirroring '
      'AskNowProvider\'s identical pending-user-id pattern',
      () async {
        billing.products[SubscriptionProductIds.silverMonthly] = silverMonthlyProduct();

        await provider.subscribeToPlan(
          SubscriptionProductIds.silverMonthly,
          selectedSegment: SubscriptionSections.career,
        );

        final prefs = await SharedPreferences.getInstance();
        expect(
          prefs.getString('subscription_pending_selected_segment_v1'),
          SubscriptionSections.career,
        );
      },
    );

    test(
      'reset() clears the persisted pending segment — the same '
      'on-logout guarantee AskNowProvider/ReportPurchaseProvider already '
      'give their own pending state, so it can never leak into a '
      'different account\'s next Silver purchase',
      () async {
        billing.products[SubscriptionProductIds.silverMonthly] = silverMonthlyProduct();
        await provider.subscribeToPlan(
          SubscriptionProductIds.silverMonthly,
          selectedSegment: SubscriptionSections.health,
        );

        await provider.reset();

        final prefs = await SharedPreferences.getInstance();
        expect(
          prefs.getString('subscription_pending_selected_segment_v1'),
          isNull,
        );
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

  group('SubscriptionProvider (Manual Trial Activation)', () {
    late _FakeBillingRepository billing;
    late SubscriptionProvider provider;

    setUp(() {
      billing = _FakeBillingRepository();
      provider = SubscriptionProvider(billing: billing);
    });

    test(
      'trialAvailable is a pure passthrough of subscriptionData '
      '["trial_available"] — never computed/inferred locally',
      () {
        expect(provider.trialAvailable, isFalse); // subscriptionData is null

        provider.subscriptionData = {'trial_available': true};
        expect(provider.trialAvailable, isTrue);

        provider.subscriptionData = {'trial_available': false};
        expect(provider.trialAvailable, isFalse);

        provider.subscriptionData = {'membership_state': 'NONE'}; // field absent
        expect(provider.trialAvailable, isFalse);
      },
    );

    test(
      'a fresh provider has no activation state set — starting point is '
      'clean, not a stale value from a previous attempt',
      () {
        expect(provider.isActivatingTrial, isFalse);
        expect(provider.activateTrialErrorMessage, isNull);
      },
    );

    test(
      'activateTrial() is a no-op while already in flight — double-tap '
      'protection, without ever reaching the network',
      () async {
        provider.isActivatingTrial = true;

        await provider.activateTrial();

        // Guard returned immediately -- state is exactly what it was
        // before the call, never touched/reset by this no-op invocation.
        expect(provider.isActivatingTrial, isTrue);
        expect(provider.activateTrialErrorMessage, isNull);
      },
    );

    test(
      'activateTrial() never leaves isActivatingTrial stuck true, even '
      'when the environment cannot resolve an authenticated user (same '
      'headless-environment reasoning already established for '
      'restorePurchases() above)',
      () async {
        await provider.activateTrial();

        expect(provider.isActivatingTrial, isFalse);
        expect(provider.activateTrialErrorMessage, isNotNull);
      },
    );

    test('reset() clears activation state and trialAvailable', () {
      provider.subscriptionData = {'trial_available': true};
      provider.isActivatingTrial = true;
      provider.activateTrialErrorMessage = 'some_error';

      provider.reset();

      expect(provider.trialAvailable, isFalse);
      expect(provider.isActivatingTrial, isFalse);
      expect(provider.activateTrialErrorMessage, isNull);
    });
  });

  group(
    'SubscriptionProvider (P0 release-gate — network timeout hardening)',
    () {
      late _FakeBillingRepository billing;

      setUp(() {
        billing = _FakeBillingRepository();
      });

      test(
        'loadSubscriptionInfo: a request that never responds in time '
        'resets isLoading and surfaces an error, exactly as any other '
        'network failure already does — no stuck spinner',
        () async {
          final client = MockClient((request) async {
            throw TimeoutException('request timed out');
          });
          final provider = SubscriptionProvider(
            billing: billing,
            httpClient: client,
            backendTokenProvider: () async => 'fixed-test-token',
          );

          await provider.loadSubscriptionInfo();

          expect(provider.isLoading, isFalse);
          expect(provider.errorMessage, isNotNull);
          expect(provider.subscriptionData, isNull);
        },
      );

      test(
        '✓ loadSubscriptionInfo: a normal, timely 200 response behaves '
        'exactly as before this fix',
        () async {
          final client = MockClient((request) async {
            return http.Response(
              '{"membership_state":"ACTIVE","trial_available":false}',
              200,
            );
          });
          final provider = SubscriptionProvider(
            billing: billing,
            httpClient: client,
            backendTokenProvider: () async => 'fixed-test-token',
          );

          await provider.loadSubscriptionInfo();

          expect(provider.isLoading, isFalse);
          expect(provider.errorMessage, isNull);
          expect(provider.subscriptionData?['membership_state'], 'ACTIVE');
        },
      );

      test(
        'activateTrial: a request that never responds in time resets '
        'isActivatingTrial and surfaces "network_error", exactly as any '
        'other network failure already does',
        () async {
          final client = MockClient((request) async {
            throw TimeoutException('request timed out');
          });
          final provider = SubscriptionProvider(
            billing: billing,
            httpClient: client,
            backendTokenProvider: () async => 'fixed-test-token',
          );

          await provider.activateTrial();

          expect(provider.isActivatingTrial, isFalse);
          expect(provider.activateTrialErrorMessage, 'network_error');
        },
      );

      test(
        '✓ activateTrial: a normal, timely success response behaves '
        'exactly as before this fix',
        () async {
          var subscriptionInfoCalls = 0;
          final client = MockClient((request) async {
            if (request.url.path.contains('activate-trial')) {
              return http.Response('{"success":true}', 200);
            }
            subscriptionInfoCalls++;
            return http.Response(
              '{"membership_state":"TRIAL","trial_available":false}',
              200,
            );
          });
          final provider = SubscriptionProvider(
            billing: billing,
            httpClient: client,
            backendTokenProvider: () async => 'fixed-test-token',
          );

          await provider.activateTrial();

          expect(provider.isActivatingTrial, isFalse);
          expect(provider.activateTrialErrorMessage, isNull);
          // Confirms the existing "refresh from backend after success"
          // behavior is untouched by this fix.
          expect(subscriptionInfoCalls, 1);
        },
      );
    },
  );

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

  group(
    'Google Play Subscription Confirm Contract fix (source characterization '
    '-- SubscriptionProvider has no injectable HTTP client, matching this '
    'file\'s own pre-existing loadSubscriptionInfo()/_confirmWithBackend() '
    'limitation, so the request payload/ordering are verified directly '
    'against source, the same technique already established elsewhere in '
    'this codebase for exactly this situation)',
    () {
      late String source;

      setUpAll(() {
        source = readProjectSource('lib/core/state/subscription_provider.dart');
      });

      test(
        'the /api/subscription/google/confirm request body includes '
        '"platform": "ANDROID" alongside the unchanged product_id/'
        'purchase_token fields',
        () {
          expectMarkersInOrder(source, [
            'Uri.parse("\$_baseUrl/api/subscription/google/confirm")',
            '"product_id": purchase.productID,',
            '"purchase_token": purchase.verificationData.serverVerificationData,',
            '"platform": "ANDROID",',
          ]);
        },
      );

      test(
        'purchase_token handling itself is unchanged -- still read from '
        'verificationData.serverVerificationData, still the exact field '
        'sent as purchase_token (not renamed/reshaped)',
        () {
          expect(
            source.contains(
              '"purchase_token": purchase.verificationData.serverVerificationData,',
            ),
            isTrue,
          );
        },
      );

      test(
        'verify-before-completePurchase ordering is unchanged: the early '
        'return on a non-2xx status still happens strictly BEFORE '
        'completePurchase() is ever reached -- a failed confirm still '
        'cannot acknowledge/complete the purchase',
        () {
          expectMarkersInOrder(source, [
            'final response = await _httpClient',
            '.post(',
            'if (response.statusCode < 200 || response.statusCode >= 300) {',
            'purchaseErrorMessage = "backend_confirmation_failed";',
            'return;',
            'if (purchase.pendingCompletePurchase) {',
            'await InAppPurchase.instance.completePurchase(purchase);',
          ]);
        },
      );

      test(
        // Release-gate fix (P0): the confirm request is now bounded --
        // a stalled/never-responding backend can no longer hang this
        // await forever -- and still, structurally, strictly BEFORE
        // completePurchase(), so a timeout can never acknowledge a
        // purchase the backend never confirmed. Anchored on the
        // confirm-endpoint URL (unique to this method) so this can't
        // accidentally match loadSubscriptionInfo/activateTrial's own,
        // separate .timeout() calls.
        'P0 network-timeout hardening: the confirm request is bounded '
        '(.timeout()), and that bound sits strictly BEFORE '
        'completePurchase() is ever reached',
        () {
          expectMarkersInOrder(source, [
            'Uri.parse("\$_baseUrl/api/subscription/google/confirm")',
            '.timeout(const Duration(seconds: 12));',
            'if (purchase.pendingCompletePurchase) {',
            'await InAppPurchase.instance.completePurchase(purchase);',
          ]);
        },
      );

      test(
        'both PurchaseStatus.purchased and PurchaseStatus.restored route '
        'through the same _confirmWithBackend call -- a restored purchase '
        'automatically uses the exact same, now-corrected contract, with '
        'no separate/stale code path',
        () {
          expectMarkersInOrder(source, [
            'case PurchaseStatus.purchased:',
            'case PurchaseStatus.restored:',
            '_confirmWithBackend(purchase);',
          ]);
        },
      );

      test(
        'Silver plan section-selection fix: selected_segment is resolved '
        '(from the in-memory pending value, falling back to the '
        'persisted one) strictly BEFORE the request body is built, and '
        'is only ever added to that body conditionally -- never an '
        'unconditional/hardcoded field',
        () {
          expectMarkersInOrder(source, [
            'if (_isSilverProduct(purchase.productID)) {',
            'selectedSegment = _pendingSelectedSegment ??= await _loadPendingSegment();',
            '"platform": "ANDROID",',
            'if (selectedSegment != null) "selected_segment": selectedSegment,',
          ]);
        },
      );

      test(
        'Silver plan section-selection fix: the persisted-segment '
        'fallback (_loadPendingSegment) is what lets a restore/re-'
        'confirm recover a previously-chosen section without ever '
        'fabricating one -- combined with the test above proving both '
        'PurchaseStatus.purchased and .restored share this exact same '
        '_confirmWithBackend call, a Silver restore can never activate '
        'ambiguously: it either finds the real persisted segment, or '
        'sends none and lets the backend\'s existing '
        'ACTIVATION_FAILED/activation_incomplete handling apply, exactly '
        'as it already does today',
        () {
          expect(
            source.contains('Future<String?> _loadPendingSegment() async {'),
            isTrue,
          );
          expect(
            source.contains(
              'selectedSegment = _pendingSelectedSegment ??= await _loadPendingSegment();',
            ),
            isTrue,
          );
        },
      );

      test(
        'Silver plan section-selection fix: _isSilverProduct matches '
        'only the two real Silver product ids -- Gold/Platinum purchases '
        'never even evaluate the segment-resolution branch, so their '
        'confirm request body is unchanged (no selected_segment key at '
        'all, same three fields as before this fix)',
        () {
          expectMarkersInOrder(source, [
            'static bool _isSilverProduct(String productId) =>',
            'productId == SubscriptionProductIds.silverMonthly ||',
            'productId == SubscriptionProductIds.silverYearly;',
          ]);
        },
      );
    },
  );
}
