import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:jyotishasha_app/services/asknow_service.dart';
import 'package:jyotishasha_app/core/config/app_config.dart';

class AskNowProvider extends ChangeNotifier {
  /// Google Play product ID for the paid Ask Now pack — the ONE named
  /// constant for it, read by [AskNowChatPage] instead of an inline
  /// literal (mirrors [ReportPurchaseProvider]'s `_productId`).
  ///
  /// Product switch: 10-question pack, ₹100, replacing the previous
  /// `asknow8q` (8 questions, ₹51). The old product ID is intentionally
  /// left un-referenced anywhere in this app (never queried, never
  /// purchased) rather than deleted from Play Console/backend — any
  /// `asknow8q` purchase still owned-but-unconsumed from before this
  /// switch (e.g. mid-recovery via [_pendingUserIdPrefsKey]) keeps
  /// verifying and crediting correctly against the backend's still-intact
  /// `asknow8q` mapping; this app just never offers it for sale again.
  static const String packProductId = "asknow10q";

  /// `billing`/`httpClient` are injectable purely for tests (mirrors
  /// [ReportPurchaseProvider]/[SubscriptionProvider]'s identical `billing`
  /// seam, and [BackendAskNowRepository]'s identical `client` seam) —
  /// production always falls through to the real [InAppPurchase.instance]
  /// and a plain [http.Client]. Doesn't change the verify request's URL,
  /// headers, or body — only how the outgoing call is dispatched.
  AskNowProvider({InAppPurchase? billing, http.Client? httpClient})
    : _iap = billing ?? InAppPurchase.instance,
      _httpClient = httpClient ?? http.Client();

  // ---------------------------------------------------------
  // STATE
  // ---------------------------------------------------------
  bool isLoading = false;
  String? pendingAnswer;
  String? lastErrorMessage;

  // FREE system
  bool freeAvailable = false;
  bool freeUsedToday = false;

  // PAID PACK system
  bool hasActivePack = false;
  int remainingTokens = 0;

  bool statusLoaded = false;

  // ---------------------------------------------------------
  // GOOGLE PLAY BILLING
  // ---------------------------------------------------------
  final InAppPurchase _iap;
  final http.Client _httpClient;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;

  int? _pendingUserId;

  /// Release-gate fix (P0): single-slot persistence key for the user id a
  /// purchase was started for. `_pendingUserId` alone is in-memory only —
  /// if the app process dies between launching the purchase and
  /// [_verifyAndActivate] finishing (backgrounding, OS kill, a crash),
  /// the purchase is redelivered via [purchaseStream] on next launch (the
  /// `in_app_purchase` package's own documented behavior for purchases
  /// that were never completed — see [initBilling]) but arrives at a
  /// fresh provider instance with `_pendingUserId == null`. Persisting it
  /// here, BEFORE the purchase is launched, is what makes that recovery
  /// actually work. Mirrors [ReportPurchaseProvider]'s identical
  /// `_pendingRequestPrefsKey` pattern.
  static const String _pendingUserIdPrefsKey = "asknow_pending_user_id_v1";

  /// In-flight guard keyed by purchase token — prevents re-entrant
  /// double-processing (and therefore double-crediting) if the same
  /// token arrives twice in a burst within one running session (e.g. the
  /// live purchase event and an overlapping `restorePurchases()` query
  /// landing at once). Deliberately in-memory only, same as
  /// [ReportPurchaseProvider]'s `_confirmingTokens` — it must not survive
  /// a restart, since a fresh attempt after a crash is exactly the
  /// recovery path this class exists for.
  final Set<String> _confirmingTokens = {};

  // ---------------------------------------------------------
  // 🔒 SINGLE SOURCE OF TRUTH (BACKEND → PROVIDER)
  // ---------------------------------------------------------
  void applyStatusFromBackend(Map<String, dynamic> status) {
    freeAvailable = status["free_available"] == true;
    freeUsedToday = status["free_used_today"] == true;

    remainingTokens =
        int.tryParse(status["remaining_tokens"]?.toString() ?? "0") ?? 0;

    hasActivePack = remainingTokens > 0;
    statusLoaded = true;

    notifyListeners();
  }

  // ---------------------------------------------------------
  // INIT / DISPOSE
  // ---------------------------------------------------------
  void initBilling() {
    _purchaseSub ??= _iap.purchaseStream.listen((purchases) {
      for (final purchase in purchases) {
        switch (purchase.status) {
          case PurchaseStatus.pending:
            isLoading = true;
            notifyListeners();
            break;

          case PurchaseStatus.purchased:
          case PurchaseStatus.restored:
            _verifyAndActivate(purchase);
            break;

          case PurchaseStatus.canceled:
            isLoading = false;
            lastErrorMessage = "Payment cancelled";
            notifyListeners();
            break;

          case PurchaseStatus.error:
            isLoading = false;
            lastErrorMessage = purchase.error?.message;
            notifyListeners();
            break;
        }
      }
    }, onError: (_) {});

    // Release-gate fix (P0): proactively surfaces any owned-but-unconsumed
    // pack purchase through the same listener above — the explicit half
    // of crash recovery, same belt-and-suspenders pattern
    // [ReportPurchaseProvider.initPurchaseListener] already uses. Never
    // awaited: app startup must not block on it.
    unawaited(_iap.restorePurchases());
  }

  @override
  void dispose() {
    _purchaseSub?.cancel();
    super.dispose();
  }

  // ---------------------------------------------------------
  void clearPending() {
    pendingAnswer = null;
    notifyListeners();
  }

  // ---------------------------------------------------------
  // MAIN CHAT LOGIC (FIXED)
  // ---------------------------------------------------------
  Future<void> askFreeOrFromTokens({
    required String question,
    required Map<String, dynamic> profile,
    required int userId,
  }) async {
    isLoading = true;
    pendingAnswer = null;
    lastErrorMessage = null;
    notifyListeners();

    // Ask Now Credit Safety: tracks whether a network call that could
    // have affected quota was actually attempted this call (WAIT_SYNC /
    // PAYMENT_REQUIRED never reach the network, so there is nothing to
    // reconcile for those). Read in `finally` below, which is the one
    // place reconciliation happens now -- unconditionally, on BOTH
    // success and failure, for BOTH free and paid/earned paths.
    bool attemptedNetworkCall = false;

    try {
      if (!statusLoaded) {
        lastErrorMessage = "WAIT_SYNC";
        return;
      }

      Map<String, dynamic>? res;

      // ---------------- FREE QUESTION ----------------
      if (freeAvailable) {
        attemptedNetworkCall = true;
        res = await AskNowService.askFreeQuestion(
          userId: userId,
          question: question,
          profile: profile,
          client: _httpClient,
        );
      }
      // ---------------- PAID QUESTION ----------------
      else if (hasActivePack && remainingTokens > 0) {
        attemptedNetworkCall = true;
        res = await AskNowService.askPaidQuestion(
          userId: userId,
          question: question,
          profile: profile,
          client: _httpClient,
        );
      } else {
        lastErrorMessage = "PAYMENT_REQUIRED";
        return;
      }

      final String answerText = res["answer"]?.toString().trim() ?? "";
      if (answerText.isNotEmpty) {
        pendingAnswer = answerText;
      } else {
        lastErrorMessage = "No answer received.";
      }

      // Best-effort immediate update from this response's own field --
      // the unconditional authoritative reconciliation below is the
      // real source of truth regardless; this only avoids a visible
      // flicker on the paid/earned path before that lands.
      if (res.containsKey("remaining_tokens")) {
        final parsed = int.tryParse(res["remaining_tokens"].toString());
        if (parsed != null) {
          remainingTokens = parsed;
          hasActivePack = parsed > 0;
        }
      }
    } catch (e) {
      // Ask Now Timeout Delivery Fix: a raw TimeoutException.toString()
      // ("TimeoutException after 0:00:25.000000: Future not completed")
      // is not something to show a user. A distinct sentinel here (the
      // same pattern WAIT_SYNC/PAYMENT_REQUIRED already use) lets the UI
      // map it to a clear message. This is surfaced ONLY -- nothing here
      // (or anywhere else in this method) automatically re-sends the
      // question; the user must tap send again, exactly like every other
      // failure already requires.
      lastErrorMessage = e is TimeoutException ? "ANSWER_TIMEOUT" : e.toString();
    } finally {
      // Ask Now Credit Safety: reconcile authoritative balance after
      // EVERY attempt that could have affected quota -- success or
      // failure, free or paid/earned alike -- so the header never shows
      // a stale balance and the next eligible source becomes usable
      // immediately in the SAME conversation, with no manual refresh.
      // A failure of this sync step itself must never overwrite/hide
      // the original request's own error set above.
      if (attemptedNetworkCall) {
        try {
          final status = await AskNowService.fetchChatStatus(
            userId,
            client: _httpClient,
          );
          applyStatusFromBackend(status);
        } catch (_) {
          // Deliberately swallowed -- lastErrorMessage (if any) from the
          // actual question attempt above is what the user must see,
          // not a secondary status-sync failure.
        }
      }
      isLoading = false;
      notifyListeners();
    }
  }

  /// Read-only lookup — lets the purchase-decision UI show Play's own
  /// localized price (e.g. "₹100.00") instead of a hardcoded string, per
  /// the same [ProductDetails] query [startGooglePlayPackPurchase] itself
  /// already performs. Never starts a purchase, never touches billing
  /// state — purely informational. Returns `null` on any failure/empty
  /// result so callers can fall back to static copy.
  Future<ProductDetails?> queryPackProduct(String productId) async {
    try {
      final response = await _iap.queryProductDetails({productId});
      if (response.productDetails.isEmpty) return null;
      return response.productDetails.first;
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------
  // GOOGLE PLAY PACK PURCHASE
  // ---------------------------------------------------------
  Future<void> startGooglePlayPackPurchase({
    required int userId,
    required String productId,
  }) async {
    _pendingUserId = userId;
    // Persisted BEFORE the purchase is launched (Release-gate fix, P0) —
    // if the app dies at any point after this line, the one thing
    // [_verifyAndActivate] needs to recover (which user this purchase
    // belongs to) already survives the crash.
    await _savePendingUserId(userId);

    final response = await _iap.queryProductDetails({productId});
    if (response.productDetails.isEmpty) {
      lastErrorMessage = "Product not found";
      notifyListeners();
      return;
    }

    final product = response.productDetails.first;
    final param = PurchaseParam(productDetails: product);

    // Release-gate fix (P0): autoConsume: false. The Play Billing plugin
    // consumes an autoConsume:true purchase internally BEFORE delivering
    // it to `purchaseStream` — i.e. before backend verification even
    // starts. If `/api/chatpack/verify` then failed (network loss,
    // backend error, app killed mid-flight) the purchase was already
    // irreversibly consumed: gone from Play, never restorable, tokens
    // never credited. Consumption now only ever happens explicitly, in
    // [_verifyAndActivate], after backend confirmation succeeds — the
    // exact same shape [ReportPurchaseProvider.purchaseReport] already
    // uses for Paid Reports.
    await _iap.buyConsumable(purchaseParam: param, autoConsume: false);
  }

  /// Manual retry entry point for a pack purchase that was paid for but
  /// never got credited (e.g. the user dismisses an error and taps
  /// "Retry"). The purchase is still owned (unconsumed) by Play — this
  /// re-queries it and lets it flow through the exact same
  /// [_verifyAndActivate] path a fresh purchase or an app-restart
  /// recovery already uses. Not a separate retry mechanism.
  Future<void> retryPendingAskNowPurchase() async {
    lastErrorMessage = null;
    notifyListeners();
    await _iap.restorePurchases();
  }

  // ---------------------------------------------------------
  // VERIFY + ACTIVATE
  // ---------------------------------------------------------
  /// The one place a verified Play pack purchase is turned into credited
  /// tokens, and the one place completePurchase()/consumePurchase() are
  /// ever called — always after, never before, the backend has confirmed
  /// the purchase (Release-gate fix, P0).
  Future<void> _verifyAndActivate(PurchaseDetails purchase) async {
    final token = purchase.verificationData.serverVerificationData;

    // Duplicate-callback guard — prevents two redundant in-flight verify
    // calls for the same token landing at once (e.g. the live purchase
    // event and an overlapping restorePurchases() query). Never blocks a
    // later, separate attempt, because it's in-memory only.
    if (_confirmingTokens.contains(token)) return;
    _confirmingTokens.add(token);

    try {
      // Recovery path: a fresh provider instance (app restart after the
      // purchase but before verification finished) has no in-memory
      // `_pendingUserId` — load the one persisted before the purchase
      // was launched.
      _pendingUserId ??= await _loadPendingUserId();

      if (_pendingUserId == null) {
        // No local record of which user this purchase belongs to.
        // Known limitation, same as ReportPurchaseProvider's equivalent
        // case: cannot safely call the backend without it. The purchase
        // itself is NOT consumed/acknowledged here, so it remains
        // recoverable via `restorePurchases()` once a pending id is
        // available again (e.g. after logging back in and starting a
        // fresh purchase, or a future manual "Restore Purchases" action).
        isLoading = false;
        lastErrorMessage = "User not ready";
        notifyListeners();
        return;
      }

      isLoading = true;
      notifyListeners();

      // Release-gate fix (P0): a stalled/never-responding verify request
      // (Render cold start, dropped connection) previously hung this
      // await forever, leaving isPurchasing/isLoading stuck and the
      // purchase neither confirmed nor safely abandoned. TimeoutException
      // flows into the existing catch below exactly like any other
      // failure here -- isLoading resets, an error is surfaced, and
      // critically `completePurchase`/`_consume` below are never reached,
      // so nothing is consumed/acknowledged on a timeout. The pending
      // purchase is preserved exactly as the existing non-2xx branch
      // above already documents.
      final res = await _httpClient
          .post(
            Uri.parse(
              "${AppConfig.backendBaseUrl}/api/chatpack/verify",
            ),
            headers: const {"Content-Type": "application/json"},
            body: jsonEncode({
              "user_id": _pendingUserId,
              "product_id": purchase.productID,
              "purchase_token": token,
            }),
          )
          .timeout(const Duration(seconds: 12));

      if (res.statusCode < 200 || res.statusCode >= 300) {
        // Do NOT consume, do NOT acknowledge — the pending record is
        // deliberately left in place so a retry (restorePurchases(), or
        // the next app session's redelivery) can find this same purchase
        // again and try the same verify call, exactly as
        // ReportPurchaseProvider's own failure path already does.
        isLoading = false;
        lastErrorMessage = "Verification failed";
        notifyListeners();
        return;
      }

      // Success — acknowledge, then explicitly consume. Only from here
      // on is the purchase actually spent.
      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
      await _consume(purchase);
      await _clearPendingUserId();

      // Product switch: asknow10q credits 10 questions (was 8, asknow8q).
      remainingTokens = 10;
      hasActivePack = true;
      statusLoaded = true;
      lastErrorMessage = null;
      isLoading = false;
      notifyListeners();
    } catch (e) {
      // Same guarantee on an unexpected exception (e.g. a network
      // failure thrown by http.post itself): nothing was consumed or
      // acknowledged above this point, and this is now caught rather
      // than propagating as an unhandled async error out of the
      // purchaseStream listener.
      isLoading = false;
      lastErrorMessage = "Verification failed";
      notifyListeners();
    } finally {
      _confirmingTokens.remove(token);
    }
  }

  /// Android-only explicit consume — the cross-platform `InAppPurchase`
  /// facade doesn't expose this (only `completePurchase`, which on
  /// Android only acknowledges). Mirrors
  /// [ReportPurchaseProvider]'s identical `_consume` helper exactly.
  Future<void> _consume(PurchaseDetails purchase) async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    try {
      final addition = _iap
          .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
      await addition.consumePurchase(purchase);
    } catch (_) {
      // Play's own consumeAsync is safe to call more than once — a
      // second attempt on an already-consumed item just fails
      // harmlessly. By this point the backend has already durably
      // credited the tokens, so a failed/duplicate consume attempt has
      // no business impact — logged only, never surfaced as a
      // user-facing error.
      if (kDebugMode) {
        debugPrint('AskNowProvider: consume attempt failed (non-fatal)');
      }
    }
  }

  // ---------------------------------------------------------
  // LOCAL PERSISTENCE — the only new state this fix adds. Durable
  // across process death; not a substitute for backend idempotency,
  // only what lets THIS device know which user a recovered purchase
  // belongs to.
  // ---------------------------------------------------------
  Future<void> _savePendingUserId(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_pendingUserIdPrefsKey, userId);
  }

  Future<int?> _loadPendingUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_pendingUserIdPrefsKey);
  }

  Future<void> _clearPendingUserId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingUserIdPrefsKey);
  }

  /// Clears all per-user Ask Now state — called by the app's centralized
  /// post-auth session cleanup (see `session_cleanup.dart`) on logout and
  /// on a fully successful Delete Account, so a second account logging
  /// into the same long-lived app process never briefly sees the
  /// previous account's free/token/chat status, and a stale persisted
  /// pending-user-id can never be mis-attributed to the new session's
  /// purchase.
  ///
  /// Deliberately does NOT cancel [_purchaseSub]/re-run [initBilling] —
  /// that stream subscription is process-wide billing infrastructure
  /// registered once at app startup, not per-user state, and must keep
  /// listening across a logout/login within the same session (mirrors
  /// [SubscriptionProvider.reset]'s identical precedent).
  Future<void> reset() async {
    isLoading = false;
    pendingAnswer = null;
    lastErrorMessage = null;
    freeAvailable = false;
    freeUsedToday = false;
    hasActivePack = false;
    remainingTokens = 0;
    statusLoaded = false;
    _pendingUserId = null;
    await _clearPendingUserId();
    notifyListeners();
  }

  // ---------------------------------------------------------
  // REWARD ADS
  // ---------------------------------------------------------
  Future<void> earnedReward(int userId) async {
    try {
      final res = await AskNowService.addRewardQuestion(
        userId,
        client: _httpClient,
      );

      if (res["success"] == true) {
        // Ask Now Credit Safety (Phase D): earning a reward question has
        // no relationship to the Free Daily Question -- /api/chat/reward
        // never touches FreeDailyQuestion server-side, so nothing here
        // may claim it did. Reconcile from the authoritative status
        // endpoint so Earned AND Free both end up matching backend
        // truth, rather than fabricating either locally.
        try {
          final status = await AskNowService.fetchChatStatus(
            userId,
            client: _httpClient,
          );
          applyStatusFromBackend(status);
        } catch (_) {
          // Authoritative sync itself failed -- fall back to this
          // response's own total_tokens for remainingTokens only.
          // Still never touches freeAvailable/freeUsedToday.
          final total =
              int.tryParse(res["total_tokens"]?.toString() ?? "") ??
              remainingTokens;
          remainingTokens = total;
          hasActivePack = total > 0;
          statusLoaded = true;
        }
      }

      notifyListeners();
    } catch (e) {
      lastErrorMessage = e.toString();
      notifyListeners();
    }
  }
}
