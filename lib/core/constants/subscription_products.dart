// lib/core/constants/subscription_products.dart

/// S5.2 — Google Play Console subscription product IDs (SKUs).
///
/// S5.X: these now match the backend's real, validated product catalog
/// exactly (`config/google_play_products.py::GOOGLE_PLAY_PRODUCTS` in
/// the backend repo — validated at backend startup, so this list is the
/// authoritative source of truth). The previous `jyotishasha_premium_*`
/// placeholders queried nonexistent SKUs and always resolved to an empty
/// product list. Per explicit product decision, these remain isolated
/// here as the ONE named config location — the same way
/// `"reports51"`/`"asknow8q"` are each a single named constant elsewhere
/// in this app — rather than hardcoded inline anywhere in the purchase
/// flow.
class SubscriptionProductIds {
  const SubscriptionProductIds._();

  static const String silverMonthly = 'jyotishasha.silver.monthly';
  static const String silverYearly = 'jyotishasha.silver.yearly';
  static const String goldMonthly = 'jyotishasha.gold.monthly';
  static const String goldYearly = 'jyotishasha.gold.yearly';
  static const String platinumYearly = 'jyotishasha.platinum.yearly';

  static const List<String> all = [
    silverMonthly,
    silverYearly,
    goldMonthly,
    goldYearly,
    platinumYearly,
  ];
}
