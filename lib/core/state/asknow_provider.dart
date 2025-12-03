// lib/core/state/asknow_provider.dart

import 'package:flutter/material.dart';
import 'package:jyotishasha_app/services/asknow_service.dart';

class AskNowProvider extends ChangeNotifier {
  // ---------------------------------------------------------
  // STATE
  // ---------------------------------------------------------
  bool isLoading = false;
  String? pendingAnswer;
  String? lastErrorMessage;

  bool freeUsedToday = false; // 1 free per day
  bool hasActivePack = false; // pack status
  int remainingTokens = 0; // how many questions left

  // ---------------------------------------------------------
  // HELPERS
  // ---------------------------------------------------------
  void clearPending() {
    pendingAnswer = null;
    notifyListeners();
  }

  void markFreeUsed() {
    freeUsedToday = true;
    notifyListeners();
  }

  void consumeToken() {
    if (hasActivePack && remainingTokens > 0) {
      remainingTokens--;
      if (remainingTokens == 0) {
        hasActivePack = false;
      }
      notifyListeners();
    }
  }

  // ---------------------------------------------------------
  // MAIN ENTRY → FREE OR PAID
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
      // ======================================================
      // 1) FREE QUESTION (if not used today)
      // ======================================================
      if (!freeUsedToday) {
        final res = await AskNowService.askFreeQuestion(
          userId: userId,
          question: question,
          profile: profile,
        );

        final success = res["success"] == true;

        if (success && res.containsKey("answer")) {
          pendingAnswer = (res["answer"] ?? "").toString();
          markFreeUsed();
          isLoading = false;
          notifyListeners();
          return;
        }

        // Backend says free used
        final msg = (res["message"] ?? "").toString();
        if (!success &&
            msg.toLowerCase().contains("free") &&
            (msg.toLowerCase().contains("used") ||
                msg.toLowerCase().contains("already"))) {
          markFreeUsed(); // now move to token pack
        } else if (!success) {
          lastErrorMessage = msg.isNotEmpty ? msg : "Unable to use free chat.";
          isLoading = false;
          notifyListeners();
          return;
        }
      }

      // ======================================================
      // 2) PAID PACK (if active)
      // ======================================================
      if (hasActivePack) {
        final resPaid = await AskNowService.askPaidQuestion(
          userId: userId,
          question: question,
          profile: profile,
        );

        final successPaid = resPaid["success"] == true;

        if (successPaid && resPaid.containsKey("answer")) {
          pendingAnswer = (resPaid["answer"] ?? "").toString();

          final rem =
              resPaid["remaining_questions"] ??
              resPaid["remaining_tokens"] ??
              resPaid["tokens_left"];

          if (rem is int) {
            remainingTokens = rem;
            hasActivePack = rem > 0;
          }

          isLoading = false;
          notifyListeners();
          return;
        } else {
          lastErrorMessage =
              (resPaid["message"] ?? "Unable to use your question pack.")
                  .toString();

          // if backend says no tokens left
          final lmsg = lastErrorMessage!.toLowerCase();
          if (lmsg.contains("no tokens") ||
              lmsg.contains("no remaining") ||
              lmsg.contains("insufficient")) {
            hasActivePack = false;
            remainingTokens = 0;
          }

          isLoading = false;
          notifyListeners();
          return;
        }
      }

      // ======================================================
      // 3) No free + no pack → Ask for payment
      // ======================================================
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
  // AFTER PAYMENT SUCCESS → ACTIVATE PACK
  // ---------------------------------------------------------
  void markPackActive({int? tokens}) {
    hasActivePack = true;
    remainingTokens = tokens ?? remainingTokens;

    if (remainingTokens <= 0) {
      hasActivePack = false;
    }

    notifyListeners();
  }

  // ---------------------------------------------------------
  // ASK AFTER PAYMENT (same question)
  // ---------------------------------------------------------
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

      final successPaid = res["success"] == true;

      if (successPaid && res.containsKey("answer")) {
        pendingAnswer = (res["answer"] ?? "").toString();

        final rem =
            res["remaining_questions"] ??
            res["remaining_tokens"] ??
            res["tokens_left"];

        if (rem is int) {
          remainingTokens = rem;
          hasActivePack = rem > 0;
        }

        isLoading = false;
        notifyListeners();
      } else {
        lastErrorMessage = (res["message"] ?? "Unable to use your pack.")
            .toString();
        isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      lastErrorMessage = e.toString();
      isLoading = false;
      notifyListeners();
    }
  }
}
