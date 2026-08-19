// lib/core/state/report_purchase_provider.dart

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:jyotishasha_app/core/models/love/love_contracts.dart';
import 'package:jyotishasha_app/core/models/reports/report_contracts.dart';
import 'package:jyotishasha_app/core/repositories/implementations/asset_report_repository.dart';
import 'package:jyotishasha_app/core/repositories/report_repository.dart';

/// Report Purchase Lifecycle Architecture (Bucket A).
///
/// Owns the ENTIRE Google Play report-purchase billing lifecycle --
/// exactly the same shape [SubscriptionProvider]/[AskNowProvider]
/// already use for their own purchase domains, applied to reports for
/// the first time. Registered `lazy: false` in `main.dart` so it is
/// alive for the whole app session, from launch -- required for crash
/// recovery (see [initPurchaseListener]'s doc).
///
///     Google Play Purchase
///         |
///         v
///     ReportPurchaseProvider (this class)
///         |  POST /api/reports/google/confirm
///         v
///     200 success?
///         |            \
///         | no          | yes
///         v              v
///     leave purchase   completePurchase()
///     pending, surface  -> consumePurchase()
///     error, retryable  -> done
///
/// `PaymentService`, `OrderService`, PDF generation, email, and Google
/// verification are all untouched -- this class only calls the same
/// [ReportRepository] the old `ReportPaymentPage` already called
/// directly, and the same `POST /api/reports/google/confirm` endpoint
/// that already exists. Nothing about the backend contract changes.
class ReportPurchaseProvider extends ChangeNotifier {
  ReportPurchaseProvider({ReportRepository? repository, InAppPurchase? billing})
    : _repository = repository ?? AssetReportRepository(),
      _iap = billing ?? InAppPurchase.instance;

  static const String _productId = "reports51";

  /// Single-slot persistence key. Only one report purchase can be in
  /// flight at a time (one "Pay with Google Play" button, gated by
  /// [isProcessing]) -- see the approved architecture review's "multiple
  /// simultaneous purchases" analysis. A fresh [purchaseReport] call
  /// overwrites any previous record; that's correct, not a bug, because
  /// [purchaseReport] itself refuses to start a second purchase while
  /// one is already [isProcessing].
  static const String _pendingRequestPrefsKey = "report_purchase_pending_v1";

  final ReportRepository _repository;
  final InAppPurchase _iap;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;

  /// In-flight guard keyed by purchase token -- prevents re-entrant
  /// double-processing if the SAME token arrives twice in a burst
  /// within one running session (e.g. the live purchase event and an
  /// overlapping restorePurchases() query). Deliberately in-memory
  /// only: it must NOT survive a restart, since a fresh attempt after
  /// a crash is exactly the recovery path this class exists for.
  final Set<String> _confirmingTokens = {};

  // ---------------------------------------------------------------
  // STATE
  // ---------------------------------------------------------------
  bool isProcessing = false;
  String? errorMessage;

  /// Bumped on every successful confirmation so a listener (the page,
  /// if it happens to still be mounted) can react exactly once per
  /// success, even if it wasn't mounted when the success happened.
  int successCount = 0;
  String? lastSuccessProduct;
  bool? lastSuccessWasRelationship;

  // ---------------------------------------------------------------
  // INIT / DISPOSE -- called once, eagerly, from main.dart
  // ---------------------------------------------------------------
  /// Subscribes to the app's one global `purchaseStream` and proactively
  /// asks Play for any purchase left pending from a previous session.
  ///
  /// Per the `in_app_purchase` package's own documented contract on
  /// `purchaseStream`: "If a purchase is not completed (completePurchase
  /// is not called...) from the last app session, purchase updates will
  /// happen when a new app session starts instead" -- provided something
  /// is listening "as soon as your app launches". Registering this
  /// provider `lazy: false` in main.dart satisfies that directly. The
  /// explicit `restorePurchases()` call below is additive belt-and-
  /// suspenders for the same recovery, and is also reused by
  /// [retryPendingReportPurchase] -- one mechanism serves both app-restart
  /// recovery and a user-triggered retry, not two separate ones.
  void initPurchaseListener() {
    _purchaseSub ??= _iap.purchaseStream.listen(_onPurchaseUpdate, onError: (_) {});
    // Fire-and-forget: surfaces any owned-but-unconsumed report purchase
    // through the same listener above. Never awaited here -- app startup
    // must not block on it.
    unawaited(_iap.restorePurchases());
  }

  @override
  void dispose() {
    _purchaseSub?.cancel();
    super.dispose();
  }

  // ---------------------------------------------------------------
  // START A PURCHASE -- called by ReportPaymentPage on "Pay"
  // ---------------------------------------------------------------
  /// Returns true once the Play purchase sheet was successfully
  /// launched. The actual outcome (success/failure) arrives later,
  /// asynchronously, via [purchaseStream] -- exactly like every other
  /// purchase flow in this app. Never call this while [isProcessing] is
  /// already true; a page-level UI should disable its Pay button the
  /// same way `ReportPaymentPage` already did.
  Future<bool> purchaseReport({
    required ReportGenerationRequest request,
    bool isRelationship = false,
    bool? boyIsUser,
    LovePersonInput? partner,
  }) async {
    if (isProcessing) return false;

    // Acquired synchronously, before any `await` -- a concurrent second
    // call arriving in the same event-loop turn must see this already
    // true, not race the checks below across their own await gaps.
    isProcessing = true;
    errorMessage = null;
    notifyListeners();

    final available = await _iap.isAvailable();
    if (!available) {
      isProcessing = false;
      errorMessage = "billing_unavailable";
      notifyListeners();
      return false;
    }

    final response = await _iap.queryProductDetails({_productId});
    if (response.error != null || response.productDetails.isEmpty) {
      isProcessing = false;
      errorMessage = "product_not_found";
      notifyListeners();
      return false;
    }

    // Persisted BEFORE the purchase is launched -- Requirement 5. If the
    // app crashes at any point after this line, the data needed to
    // confirm the purchase with the backend already survives the crash.
    await _savePendingRequest(
      request: request,
      isRelationship: isRelationship,
      boyIsUser: boyIsUser,
      partner: partner,
    );

    final product = response.productDetails.first;
    final param = PurchaseParam(productDetails: product);

    // Requirement 2 -- autoConsume: false. Consumption now only ever
    // happens explicitly, after backend confirmation succeeds (see
    // _confirmWithBackend below), never automatically inside the plugin.
    await _iap.buyConsumable(purchaseParam: param, autoConsume: false);
    return true;
  }

  /// Requirement 4's retry path. The purchase that failed backend
  /// confirmation is still owned (unconsumed) by Play -- this re-queries
  /// it and lets it flow through the exact same [_onPurchaseUpdate] ->
  /// [_confirmWithBackend] path a fresh purchase or an app-restart
  /// recovery already uses. Not a separate retry mechanism.
  Future<void> retryPendingReportPurchase() async {
    errorMessage = null;
    notifyListeners();
    await _iap.restorePurchases();
  }

  // ---------------------------------------------------------------
  // PURCHASE STREAM
  // ---------------------------------------------------------------
  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final p in purchases) {
      if (p.productID != _productId) continue;

      switch (p.status) {
        case PurchaseStatus.pending:
          isProcessing = true;
          notifyListeners();
          break;

        case PurchaseStatus.canceled:
          isProcessing = false;
          errorMessage = "cancelled";
          notifyListeners();
          break;

        case PurchaseStatus.error:
          isProcessing = false;
          errorMessage = p.error?.message ?? "purchase_failed";
          notifyListeners();
          break;

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _confirmWithBackend(p);
          break;
      }
    }
  }

  /// The one place a verified Play purchase is turned into a report
  /// request, and the one place completePurchase()/consumePurchase() are
  /// ever called -- always after, never before, the backend has
  /// confirmed the purchase (Requirement 3/4).
  Future<void> _confirmWithBackend(PurchaseDetails purchase) async {
    final token = purchase.verificationData.serverVerificationData;

    // Duplicate-callback guard -- Requirement 6 territory, but enforced
    // here defensively even though PaymentService's own ProcessedPayment
    // ledger (keyed on this exact token) already makes a genuine
    // double-submit safe. This only avoids two redundant in-flight HTTP
    // calls for the same token landing at once; it never blocks a later,
    // separate attempt (e.g. after a restart) because it's in-memory only.
    if (_confirmingTokens.contains(token)) return;
    _confirmingTokens.add(token);

    try {
      final pending = await _loadPendingRequest();
      if (pending == null) {
        // No local record of what to generate for this token. Cannot
        // safely call the backend without name/email/product -- surfaced
        // rather than silently dropped. Known limitation: a pending
        // purchase whose local record was cleared by something other
        // than this class's own success path has no automatic recovery
        // beyond this message; it still requires no code change to the
        // backend, since nothing was ever consumed for it.
        isProcessing = false;
        errorMessage = "unknown_pending_purchase";
        notifyListeners();
        return;
      }

      isProcessing = true;
      errorMessage = null;
      notifyListeners();

      final reportRequest = pending.request.copyWith(
        purchaseToken: token,
        productId: purchase.productID,
        orderId: purchase.purchaseID,
      );

      final ReportGenerationOutcome outcome;
      if (pending.isRelationship) {
        outcome = await _repository.requestRelationshipReport(
          RelationshipReportRequest(
            report: reportRequest,
            boyIsUser: pending.boyIsUser,
            partner: pending.partner,
          ),
        );
      } else {
        outcome = await _repository.requestReport(reportRequest);
      }
      final ok = outcome.success == true;

      if (!ok) {
        // CANCELED Recovery Dead-End fix: purchase_canceled is Google's
        // own TERMINAL verdict on this exact token (purchaseState=1) --
        // retrying it can never succeed, so this is the one failure
        // reason allowed to clear the pending record and drop the user
        // back to a fresh "Buy Report" state. Every other failure
        // (unclassified, purchase_pending, network/5xx/timeout) keeps
        // Requirement 4's original guarantee unchanged: DO NOT consume,
        // DO NOT acknowledge, DO NOT clear -- so a retry (or the next
        // app session) can still find this same token again.
        isProcessing = false;
        if (outcome.errorCode == "purchase_canceled") {
          await _clearPendingRequest();
          errorMessage = "purchase_canceled";
        } else if (outcome.errorCode == "purchase_pending") {
          errorMessage = "purchase_pending";
        } else {
          errorMessage = "report_failed";
        }
        notifyListeners();
        return;
      }

      // Success -- acknowledge, then explicitly consume. Requirement 3.
      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
      await _consume(purchase);

      await _clearPendingRequest();
      isProcessing = false;
      errorMessage = null;
      successCount += 1;
      lastSuccessProduct = pending.request.product;
      lastSuccessWasRelationship = pending.isRelationship;
      notifyListeners();
    } catch (_) {
      // Same Requirement 4 guarantee on an unexpected exception: nothing
      // was consumed or acknowledged above this point in that case.
      isProcessing = false;
      errorMessage = "report_failed";
      notifyListeners();
    } finally {
      _confirmingTokens.remove(token);
    }
  }

  /// Android-only explicit consume -- the cross-platform `InAppPurchase`
  /// facade doesn't expose this (only `completePurchase`, which on
  /// Android only acknowledges). iOS has no separate consume step in
  /// this package's model, so this is a no-op there by construction.
  Future<void> _consume(PurchaseDetails purchase) async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    try {
      final addition = _iap
          .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
      await addition.consumePurchase(purchase);
    } catch (_) {
      // Requirement 7 -- Play's own consumeAsync is safe to call more
      // than once (a second attempt on an already-consumed item just
      // fails harmlessly, per the architecture review's own analysis).
      // By this point the backend has already durably recorded the
      // order, so a failed/duplicate consume attempt has no business
      // impact -- logged only, never surfaced as a user-facing error.
      if (kDebugMode) {
        debugPrint('ReportPurchaseProvider: consume attempt failed (non-fatal)');
      }
    }
  }

  // ---------------------------------------------------------------
  // LOCAL PERSISTENCE -- the only new state this architecture adds.
  // Durable across process death; not a substitute for backend
  // idempotency, only what lets THIS device know what to ask the
  // (already-idempotent) backend for when a purchase is recovered.
  // ---------------------------------------------------------------
  Future<void> _savePendingRequest({
    required ReportGenerationRequest request,
    required bool isRelationship,
    bool? boyIsUser,
    LovePersonInput? partner,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final blob = <String, dynamic>{
      "is_relationship": isRelationship,
      "boy_is_user": boyIsUser,
      "partner": partner?.toJson(),
      "report": request.toJson(),
    };
    await prefs.setString(_pendingRequestPrefsKey, jsonEncode(blob));
  }

  Future<_PendingReportPurchase?> _loadPendingRequest() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pendingRequestPrefsKey);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return _PendingReportPurchase(
        isRelationship: decoded["is_relationship"] == true,
        boyIsUser: decoded["boy_is_user"] as bool?,
        partner: decoded["partner"] == null
            ? null
            : LovePersonInput.fromJson(
                Map<String, dynamic>.from(decoded["partner"] as Map),
              ),
        request: ReportGenerationRequest.fromJson(
          Map<String, dynamic>.from(decoded["report"] as Map),
        ),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _clearPendingRequest() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingRequestPrefsKey);
  }
}

class _PendingReportPurchase {
  const _PendingReportPurchase({
    required this.isRelationship,
    required this.request,
    this.boyIsUser,
    this.partner,
  });

  final bool isRelationship;
  final ReportGenerationRequest request;
  final bool? boyIsUser;
  final LovePersonInput? partner;
}
