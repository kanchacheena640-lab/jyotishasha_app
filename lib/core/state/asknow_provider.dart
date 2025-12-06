// lib/core/state/asknow_provider.dart
import 'package:flutter/material.dart';
import 'package:jyotishasha_app/services/asknow_service.dart';

class AskNowProvider extends ChangeNotifier {
  // ---------------------------------------------------------
  // STATE
  // ---------------------------------------------------------
  bool isLoading = false;
  String? pendingAnswer; // <-- ALWAYS STRING
  String? lastErrorMessage;

  // FREE system
  bool freeAvailable = false;
  bool freeUsedToday = false;

  // PAID PACK system
  bool hasActivePack = false;
  int remainingTokens = 0;

  bool statusLoaded = false;

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

  void consumeToken() {
    if (hasActivePack && remainingTokens > 0) {
      remainingTokens--;
      hasActivePack = remainingTokens > 0;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------
  // MAIN LOGIC
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
        isLoading = false;
        notifyListeners();
        return;
      }

      // ---------------- FREE QUESTION ----------------
      if (freeAvailable) {
        final res = await AskNowService.askFreeQuestion(
          userId: userId,
          question: question,
          profile: profile,
        );

        if (res["success"] == true && res["answer"] != null) {
          // ✅ Always only clean text string
          pendingAnswer = res["answer"].toString();
          setFreeAvailable(false);
          isLoading = false;
          notifyListeners();
          return;
        }

        lastErrorMessage = res["message"] ?? "Unable to use free chat.";
        isLoading = false;
        notifyListeners();
        return;
      }

      // ---------------- PAID QUESTION ----------------
      if (hasActivePack) {
        final res = await AskNowService.askPaidQuestion(
          userId: userId,
          question: question,
          profile: profile,
        );

        if (res["success"] == true && res["answer"] != null) {
          // ✅ Clean string again
          pendingAnswer = res["answer"].toString();

          final rem = res["remaining_tokens"] ?? res["remaining"];
          if (rem != null) {
            final parsed = int.tryParse(rem.toString());
            if (parsed != null) {
              remainingTokens = parsed;
              hasActivePack = parsed > 0;
            }
          }

          isLoading = false;
          notifyListeners();
          return;
        }

        lastErrorMessage = res["message"] ?? "Unable to use your pack.";
        isLoading = false;
        notifyListeners();
        return;
      }

      // ---------------- NO FREE, NO PACK ----------------
      lastErrorMessage = "PAYMENT_REQUIRED";
      isLoading = false;
      notifyListeners();
    } catch (e) {
      lastErrorMessage = e.toString();
      isLoading = false;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------
  // AFTER PAYMENT
  // ---------------------------------------------------------
  void markPackActive({int? tokens}) {
    remainingTokens = tokens ?? remainingTokens;
    hasActivePack = remainingTokens > 0;
    notifyListeners();
  }

  Future<void> askFromPaidPack({
    required String question,
    required Map<String, dynamic> profile,
    required int userId,
  }) async {
    isLoading = true;
    pendingAnswer = null;
    lastErrorMessage = null;
    notifyListeners();

    try {
      final res = await AskNowService.askPaidQuestion(
        userId: userId,
        question: question,
        profile: profile,
      );

      if (res["success"] == true && res["answer"] != null) {
        // ✅ Clean bot answer again
        pendingAnswer = res["answer"].toString();

        final rem = res["remaining_tokens"] ?? res["remaining"];
        if (rem != null) {
          final parsed = int.tryParse(rem.toString());
          if (parsed != null) {
            remainingTokens = parsed;
            hasActivePack = parsed > 0;
          }
        }

        isLoading = false;
        notifyListeners();
        return;
      }

      lastErrorMessage = res["message"] ?? "Unable to use your pack.";
      isLoading = false;
      notifyListeners();
    } catch (e) {
      lastErrorMessage = e.toString();
      isLoading = false;
      notifyListeners();
    }
  }

  // ⭐ ADD 1 QUESTION WHEN USER WATCHES 2 ADS
  Future<void> earnedReward(int userId) async {
    try {
      final res = await AskNowService.addRewardQuestion(userId);

      if (res["success"] == true) {
        final int newTotal =
            int.tryParse(res["total_tokens"].toString()) ?? remainingTokens;

        remainingTokens = newTotal;
        hasActivePack = remainingTokens > 0;

        // ⭐ FREE KO TOUCH MAT KARNA
        freeAvailable = false;
        freeUsedToday = true;

        notifyListeners();
      }
    } catch (e) {
      print("Reward error: $e");
    }
  }
}
