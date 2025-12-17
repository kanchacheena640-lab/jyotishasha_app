import 'package:in_app_purchase/in_app_purchase.dart';

class PlayBillingStub {
  static final InAppPurchase _iap = InAppPurchase.instance;

  static Future<void> init() async {
    await _iap.isAvailable();
  }
}
