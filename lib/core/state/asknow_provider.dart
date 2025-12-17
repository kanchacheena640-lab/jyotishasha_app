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

  void setFreeAvailable(bool available) {
    freeAvailable = available;
    freeUsedToday = !available;
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
    // 🔒 HARD RESET BEFORE CALL
    isLoading = true;
    pendingAnswer = null;
    lastErrorMessage = null;
    notifyListeners();

    try {
      if (!statusLoaded) {
        lastErrorMessage = "WAIT_SYNC";
        isLoading = false;
        notifyListeners();
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
        setFreeAvailable(false);
      }
      // ---------------- PAID QUESTION ----------------
      else if (hasActivePack) {
        res = await AskNowService.askPaidQuestion(
          userId: userId,
          question: question,
          profile: profile,
        );
      } else {
        lastErrorMessage = "PAYMENT_REQUIRED";
        isLoading = false;
        notifyListeners();
        return;
      }

      // ---------------- RESULT HANDLE (CRITICAL FIX) ----------------
      final String answerText = res["answer"]?.toString().trim() ?? "";

      if (answerText.isNotEmpty) {
        pendingAnswer = answerText;
      } else {
        lastErrorMessage = "No answer received. Please try again.";
      }

      // Update tokens if present
      final rem = res["remaining_tokens"];
      if (rem != null) {
        final parsed = int.tryParse(rem.toString());
        if (parsed != null) {
          remainingTokens = parsed;
          hasActivePack = parsed > 0;
        }
      }
    } catch (e) {
      lastErrorMessage = e.toString();
    } finally {
      // 🔥 GUARANTEED EXIT
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

    _iap.buyNonConsumable(purchaseParam: param);
  }

  // ---------------------------------------------------------
  // VERIFY + ACTIVATE
  // ---------------------------------------------------------
  Future<void> _verifyAndActivate(PurchaseDetails purchase) async {
    if (_pendingUserId == null) {
      isLoading = false;
      lastErrorMessage = "User not ready for verification";
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
      isLoading = false;
      lastErrorMessage = "Verification failed";
      notifyListeners();
      return;
    }

    await _iap.completePurchase(purchase);

    remainingTokens = 8;
    hasActivePack = true;
    statusLoaded = true;
    isLoading = false;
    notifyListeners();
  }

  // ---------------------------------------------------------
  // REWARD ADS (2 ads = 1Q)
  // ---------------------------------------------------------
  Future<void> earnedReward(int userId) async {
    try {
      final res = await AskNowService.addRewardQuestion(userId);

      if (res["success"] == true) {
        final int total =
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
