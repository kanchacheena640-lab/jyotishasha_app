import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:http/http.dart' as http;

import 'package:jyotishasha_app/services/asknow_service.dart';

class AskNowProvider extends ChangeNotifier {
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
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;

  int? _pendingUserId;

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
    });
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

    try {
      if (!statusLoaded) {
        lastErrorMessage = "WAIT_SYNC";
        return;
      }

      Map<String, dynamic>? res;

      // ---------------- FREE QUESTION ----------------
      if (freeAvailable) {
        res = await AskNowService.askFreeQuestion(
          userId: userId,
          question: question,
          profile: profile,
        );

        // 🔒 HARD SYNC after free consume
        final status = await AskNowService.fetchChatStatus(userId);
        applyStatusFromBackend(status);
      }
      // ---------------- PAID QUESTION ----------------
      else if (hasActivePack && remainingTokens > 0) {
        res = await AskNowService.askPaidQuestion(
          userId: userId,
          question: question,
          profile: profile,
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

      // Token update only if backend sends it
      if (res.containsKey("remaining_tokens")) {
        final parsed = int.tryParse(res["remaining_tokens"].toString());
        if (parsed != null) {
          remainingTokens = parsed;
          hasActivePack = parsed > 0;
        }
      }
    } catch (e) {
      lastErrorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
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

    final response = await _iap.queryProductDetails({productId});
    if (response.productDetails.isEmpty) {
      lastErrorMessage = "Product not found";
      notifyListeners();
      return;
    }

    final product = response.productDetails.first;
    final param = PurchaseParam(productDetails: product);

    await _iap.buyConsumable(purchaseParam: param, autoConsume: true);
  }

  // ---------------------------------------------------------
  // VERIFY + ACTIVATE
  // ---------------------------------------------------------
  Future<void> _verifyAndActivate(PurchaseDetails purchase) async {
    if (_pendingUserId == null) {
      lastErrorMessage = "User not ready";
      notifyListeners();
      return;
    }

    final res = await http.post(
      Uri.parse("https://jyotishasha-backend.onrender.com/api/chatpack/verify"),
      headers: const {"Content-Type": "application/json"},
      body: jsonEncode({
        "user_id": _pendingUserId,
        "product_id": purchase.productID,
        "purchase_token": purchase.verificationData.serverVerificationData,
      }),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      lastErrorMessage = "Verification failed";
      notifyListeners();
      return;
    }

    await _iap.completePurchase(purchase);

    remainingTokens = 8;
    hasActivePack = true;
    statusLoaded = true;
    notifyListeners();
  }

  // ---------------------------------------------------------
  // REWARD ADS
  // ---------------------------------------------------------
  Future<void> earnedReward(int userId) async {
    try {
      final res = await AskNowService.addRewardQuestion(userId);

      if (res["success"] == true) {
        final total =
            int.tryParse(res["total_tokens"]?.toString() ?? "") ??
            remainingTokens;

        remainingTokens = total;
        hasActivePack = total > 0;
        statusLoaded = true;

        freeAvailable = false;
        freeUsedToday = true;

        notifyListeners();
      }
    } catch (e) {
      lastErrorMessage = e.toString();
      notifyListeners();
    }
  }
}
