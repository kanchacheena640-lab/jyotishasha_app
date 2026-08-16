// lib/core/state/subscription_provider.dart

import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:in_app_purchase/in_app_purchase.dart';

import 'package:jyotishasha_app/core/constants/subscription_products.dart';
import 'package:jyotishasha_app/core/models/asknow/asknow_contracts.dart';
import 'package:jyotishasha_app/core/repositories/billing_repository.dart';
import 'package:jyotishasha_app/core/repositories/implementations/play_billing_repository.dart';
import 'package:jyotishasha_app/services/backend_auth_service.dart';

/// S5.1 status foundation + S5.2 Google Play purchase flow.
///
/// `GET /api/profile/subscription-info` remains the only source of truth
/// for subscription STATE — this class never computes/infers active,
/// trial, or expiry status client-side, before or after a purchase.
///
/// S5.2 reuses existing billing infrastructure rather than duplicating
/// it:
/// - [BillingRepository]/[PlayBillingRepository] (built in an earlier
///   ESR pass, never previously adopted) — reused here for
///   `isAvailable()`, `getProduct()`, and the new `purchaseSubscription()`
///   this task adds to that same interface (subscriptions need
///   `buyNonConsumable`, not the existing `purchaseConsumable`, since a
///   subscription must never be auto-consumed).
/// - The purchase-update **listener** and **verify-then-acknowledge**
///   sequencing mirror `AskNowProvider`'s proven, live pattern — the one
///   purchase flow in this codebase that already works correctly
///   end-to-end — rather than [BillingRepository.watchPurchases], which
///   collapses every purchase status (pending/purchased/canceled/error)
///   into an unconditional receipt with no status field. Reusing that
///   method here would risk treating a cancelled or failed purchase as a
///   success. [PlayBillingRepository] is still reused for everything it
///   *does* do correctly (queries, purchase initiation, acknowledgement
///   plumbing is available via [BillingRepository.completePurchase] but
///   this class calls `InAppPurchase.completePurchase` directly for the
///   same reason — it already holds the raw, status-checked
///   [PurchaseDetails] from its own listener, matching AskNowProvider).
/// - The backend Bearer token reuses [BackendAuthService.getBackendToken]
///   — the same method `NotificationService` and the S5.1 status load
///   already use — no new auth/networking logic.
class SubscriptionProvider extends ChangeNotifier {
  SubscriptionProvider({BillingRepository? billing})
    : _billing = billing ?? PlayBillingRepository();

  static const String _baseUrl = "https://jyotishasha-backend.onrender.com";

  final BillingRepository _billing;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;

  // ---------------------------------------------------------------
  // S5.1 — subscription STATUS (read-only, backend is the only source)
  // ---------------------------------------------------------------
  bool isLoading = false;
  String? errorMessage;
  Map<String, dynamic>? subscriptionData;

  Future<void> loadSubscriptionInfo() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final token = await _requireBackendToken();
      if (token == null) {
        errorMessage = "Unable to authenticate.";
        return;
      }

      final response = await http.get(
        Uri.parse("$_baseUrl/api/profile/subscription-info"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode != 200) {
        errorMessage = "Server error (${response.statusCode}).";
        return;
      }

      subscriptionData = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------
  // S5.2 — Google Play subscription PURCHASE
  // ---------------------------------------------------------------

  /// Separate from [isLoading]/[errorMessage] (the status-load state) on
  /// purpose — a failed purchase attempt must never clobber or hide the
  /// last successfully loaded subscription-info still on screen.
  bool isPurchasing = false;
  String? purchaseErrorMessage;

  /// Products successfully queried from Google Play for the configured
  /// [SubscriptionProductIds] — never hardcoded per-product data, only
  /// what `getProduct()` (via [BillingRepository]) actually returns.
  List<ChatPackProduct> availableProducts = [];

  Future<void> loadAvailableProducts() async {
    final products = <ChatPackProduct>[];
    for (final id in SubscriptionProductIds.all) {
      final product = await _billing.getProduct(id);
      if (product != null) products.add(product);
    }
    availableProducts = products;
    notifyListeners();
  }

  /// Starts listening for Google Play purchase updates. Idempotent and
  /// intended to be called once, eagerly, at app startup — the same
  /// `initBilling()` pattern `AskNowProvider` already uses (registered
  /// `lazy: false` in `main.dart`), so a purchase completing while the
  /// user isn't on [SubscriptionPage] is still handled.
  void initPurchaseListener() {
    _purchaseSub ??= InAppPurchase.instance.purchaseStream.listen((
      purchases,
    ) {
      for (final purchase in purchases) {
        // This is the app's one global purchase stream — AskNow/report
        // purchases flow through it too. Only react to this provider's
        // own subscription products; anything else is someone else's
        // listener's concern.
        if (!SubscriptionProductIds.all.contains(purchase.productID)) {
          continue;
        }

        switch (purchase.status) {
          case PurchaseStatus.pending:
            isPurchasing = true;
            purchaseErrorMessage = null;
            notifyListeners();
            break;

          case PurchaseStatus.purchased:
          case PurchaseStatus.restored:
            _confirmWithBackend(purchase);
            break;

          case PurchaseStatus.canceled:
            isPurchasing = false;
            purchaseErrorMessage = "cancelled";
            notifyListeners();
            break;

          case PurchaseStatus.error:
            isPurchasing = false;
            purchaseErrorMessage = purchase.error?.message ?? "purchase_failed";
            notifyListeners();
            break;
        }
      }
    });
  }

  /// When the user taps Subscribe for [productId] (one of
  /// [SubscriptionProductIds]): checks billing availability, resolves the
  /// live product, then starts the Play purchase sheet. The result
  /// arrives asynchronously via [initPurchaseListener]'s stream, not this
  /// method's return — matching how Google Play purchases always work.
  Future<void> subscribeToPlan(String productId) async {
    purchaseErrorMessage = null;
    isPurchasing = true;
    notifyListeners();

    try {
      final available = await _billing.isAvailable();
      if (!available) {
        isPurchasing = false;
        purchaseErrorMessage = "billing_unavailable";
        return;
      }

      final product = await _billing.getProduct(productId);
      if (product == null) {
        isPurchasing = false;
        purchaseErrorMessage = "product_not_found";
        return;
      }

      await _billing.purchaseSubscription(product);
      // isPurchasing stays true — the stream listener resolves it next,
      // once Play actually reports pending/purchased/canceled/error.
    } catch (e) {
      isPurchasing = false;
      purchaseErrorMessage = e.toString();
    } finally {
      notifyListeners();
    }
  }

  /// Purchase → backend confirm → acknowledge, in that order — mirrors
  /// `AskNowProvider._verifyAndActivate`'s proven sequencing exactly:
  /// the Play purchase is only acknowledged (`completePurchase`) AFTER
  /// the backend confirms it, never before. `POST
  /// /api/subscription/google/confirm` is the existing, frozen backend
  /// endpoint this task specifies; the purchase token and the
  /// existing-authenticated-user's Bearer token are all it's given — no
  /// entitlement fields are computed or sent from Flutter.
  Future<void> _confirmWithBackend(PurchaseDetails purchase) async {
    try {
      final token = await _requireBackendToken();
      if (token == null) {
        isPurchasing = false;
        purchaseErrorMessage = "auth_failed";
        notifyListeners();
        return;
      }

      final response = await http.post(
        Uri.parse("$_baseUrl/api/subscription/google/confirm"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "product_id": purchase.productID,
          "purchase_token": purchase.verificationData.serverVerificationData,
        }),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        // Backend is the source of truth — if it didn't confirm, the
        // purchase is NOT acknowledged, and no local entitlement is
        // assumed. The user keeps a pending Play purchase they can
        // still complete/retry later (e.g. via a future Restore
        // Purchases flow — explicitly out of scope for S5.2).
        isPurchasing = false;
        purchaseErrorMessage = "backend_confirmation_failed";
        notifyListeners();
        return;
      }

      // S5.X fix: a 2xx here only means the purchase token was
      // successfully VERIFIED with Google — it does NOT mean
      // entitlement was actually activated (`outcome` can be
      // PENDING/NOT_ACTIVATED/UNMAPPED_PRODUCT/ACTIVATION_FAILED, all
      // still 200s per the backend's own contract). Previously this
      // branch treated every 2xx as unconditional success, so a paying
      // user who hit e.g. ACTIVATION_FAILED saw no error at all.
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final result = interpretConfirmResponse(body);

      // Play billing requires acknowledgment within 3 days regardless
      // of the business outcome (else Google auto-refunds) — the token
      // was already verified server-side above, so this still runs
      // even when [result] carries a warning.
      if (purchase.pendingCompletePurchase) {
        await InAppPurchase.instance.completePurchase(purchase);
      }

      isPurchasing = false;
      purchaseErrorMessage = result.warningCode;
      notifyListeners();

      // "The page must immediately reflect the new subscription
      // status" — refresh from the backend rather than assuming/
      // computing the new state client-side.
      await loadSubscriptionInfo();
    } catch (e) {
      isPurchasing = false;
      purchaseErrorMessage = e.toString();
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------
  // S5.4 — Restore Purchases
  // ---------------------------------------------------------------

  /// Separate from [isPurchasing]/[purchaseErrorMessage] on purpose — a
  /// restore attempt must never clobber or be clobbered by an unrelated
  /// in-flight Subscribe tap.
  bool isRestoring = false;
  String? restoreErrorMessage;

  /// S5.4 — "User taps Restore Purchases". Reuses everything already
  /// built rather than duplicating it: [BillingRepository.
  /// restorePurchases] (new in this task, symmetrical with
  /// `purchaseSubscription`) asks Play to replay every purchase this
  /// user already owns through the exact same `purchaseStream`
  /// [initPurchaseListener] is already listening to — each one arrives
  /// as a `PurchaseStatus.restored` event, which that listener already
  /// routes to [_confirmWithBackend]: the identical verify-then-
  /// acknowledge-then-refresh pipeline a brand new purchase uses. This
  /// method does not itself confirm, acknowledge, or evaluate any
  /// purchase — it only triggers the replay and then asks the backend
  /// (via [loadSubscriptionInfo], the one existing status endpoint) what
  /// the final, authoritative state is.
  ///
  /// "Never create duplicate entitlements" / "never calculate
  /// entitlements in Flutter": every restored purchase is sent to
  /// `POST /api/subscription/google/confirm` exactly like a fresh one —
  /// deduplication is the backend's responsibility, not computed here.
  Future<void> restorePurchases() async {
    restoreErrorMessage = null;
    isRestoring = true;
    notifyListeners();

    try {
      final available = await _billing.isAvailable();
      if (!available) {
        restoreErrorMessage = "billing_unavailable";
        return;
      }

      final token = await _requireBackendToken();
      if (token == null) {
        restoreErrorMessage = "auth_failed";
        return;
      }

      await _billing.restorePurchases();

      // Restored purchases (if any) arrive asynchronously via the same
      // stream `initPurchaseListener` already handles — give that its
      // own confirm/refresh cycle a brief window before asking the
      // backend for the final answer.
      await Future.delayed(const Duration(seconds: 2));
      await loadSubscriptionInfo();

      final active =
          subscriptionData?['active'] == true ||
          subscriptionData?['is_active'] == true;
      if (!active) {
        // The backend — not this class — is the one deciding "not
        // active" here; this only reports what it already said via the
        // refresh just above.
        restoreErrorMessage = "no_purchases_found";
      }
    } catch (e) {
      restoreErrorMessage = e.toString();
    } finally {
      isRestoring = false;
      notifyListeners();
    }
  }

  /// Clears membership/purchase state — called on logout so the next
  /// login (a different account, in the same long-lived app process)
  /// never briefly shows the previous user's plan/membership_state
  /// before its own fresh [loadSubscriptionInfo] call resolves.
  /// Deliberately does NOT cancel [_purchaseSub]/re-run
  /// [initPurchaseListener] — that stream subscription is process-wide
  /// billing infrastructure registered once at app startup, not
  /// per-user state, and must keep listening across a logout/login
  /// within the same session (a purchase completing mid-restore, etc.).
  void reset() {
    isLoading = false;
    errorMessage = null;
    subscriptionData = null;
    isPurchasing = false;
    purchaseErrorMessage = null;
    availableProducts = [];
    isRestoring = false;
    restoreErrorMessage = null;
    notifyListeners();
  }

  Future<String?> _requireBackendToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return BackendAuthService.getBackendToken(user.uid);
  }

  @override
  void dispose() {
    _purchaseSub?.cancel();
    super.dispose();
  }
}

/// Whether a `google/confirm` 2xx response actually granted entitlement,
/// or only verified the token with Google without activating it.
enum ConfirmResultKind {
  /// `activated == true`, or `status == "DUPLICATE"` (already processed
  /// by an earlier confirm — nothing new to warn about).
  success,

  /// `status == "VERIFIED"` but `activated == false` — the purchase
  /// token was real and has already been acknowledged with Google, but
  /// no entitlement was granted (see [warningCode]).
  warning,
}

/// Result of [interpretConfirmResponse].
@immutable
class ConfirmResult {
  const ConfirmResult(this.kind, this.warningCode);

  final ConfirmResultKind kind;

  /// Only set when [kind] is [ConfirmResultKind.warning] — one of
  /// `"activation_pending"` (Google's own `outcome: "PENDING"`, e.g. a
  /// deferred payment) or `"activation_incomplete"` (`NOT_ACTIVATED`/
  /// `UNMAPPED_PRODUCT`/`ACTIVATION_FAILED` — a real problem the user
  /// should be told about, distinct from a normal purchase error).
  final String? warningCode;
}

/// Pure interpretation of a `POST /api/subscription/google/confirm`
/// response body, called only once the HTTP status code itself was
/// already 2xx (a non-2xx status is always a hard failure, handled
/// before this is ever reached). Kept as a free function of the decoded
/// JSON body — not a method — so it's unit-testable without mocking an
/// HTTP client or a [PurchaseDetails].
@visibleForTesting
ConfirmResult interpretConfirmResponse(Map<String, dynamic> body) {
  if (body['status']?.toString() == 'DUPLICATE') {
    return const ConfirmResult(ConfirmResultKind.success, null);
  }
  if (body['activated'] == true) {
    return const ConfirmResult(ConfirmResultKind.success, null);
  }
  final outcome = body['outcome']?.toString();
  return ConfirmResult(
    ConfirmResultKind.warning,
    outcome == 'PENDING' ? 'activation_pending' : 'activation_incomplete',
  );
}
