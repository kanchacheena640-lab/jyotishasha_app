import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class PlayBillingStub {
  static final InAppPurchase _iap = InAppPurchase.instance;

  /// Release-gate fix (P0): a startup probe only — nothing downstream
  /// reads its return value, and every real purchase flow
  /// (`AskNowProvider`/`SubscriptionProvider`/`ReportPurchaseProvider`)
  /// already calls `isAvailable()` again itself before actually starting
  /// a purchase. This call existing is therefore optional; it must never
  /// be able to block `main()` from ever reaching `runApp()`.
  ///
  /// `isAvailable()` connects to the native Play Billing client and
  /// waits for its setup callback — Google gives no guaranteed bound on
  /// that, and on a device with Play Services misconfigured or not yet
  /// ready it can stall indefinitely. Bounded here with a timeout, and
  /// any failure (timeout or thrown exception) is swallowed rather than
  /// propagated — startup must proceed regardless of whether Play
  /// Billing turns out to be available.
  static Future<void> init() async {
    try {
      await _iap.isAvailable().timeout(const Duration(seconds: 3));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ PlayBillingStub.init() failed/timed out (non-fatal): $e');
      }
    }
  }
}
