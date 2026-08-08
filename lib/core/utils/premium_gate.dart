// lib/core/utils/premium_gate.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:jyotishasha_app/core/state/subscription_provider.dart';
import 'package:jyotishasha_app/features/subscription/subscription_page.dart';

/// S5.3 — the one shared "does this user currently have premium access"
/// check, reused wherever a feature needs to require an active
/// subscription. Reads ONLY [SubscriptionProvider.subscriptionData]'s own
/// `active`/`is_active` field from `GET /api/profile/subscription-info` —
/// never infers trial/grace/expiry/plan, never computes entitlement
/// client-side. The backend is the only source of truth; if it hasn't
/// been queried yet (`subscriptionData` is still `null`), this returns
/// `false` rather than assuming access.
bool hasActiveSubscription(BuildContext context) {
  final data = context.read<SubscriptionProvider>().subscriptionData;
  return data?['active'] == true || data?['is_active'] == true;
}

/// Gates [onUnlocked] behind [hasActiveSubscription]. If the user already
/// has an active subscription, runs [onUnlocked] immediately. Otherwise
/// opens the existing [SubscriptionPage] — never a new purchase dialog,
/// never a bypass, matching "whenever a locked feature is opened,
/// navigate to the existing SubscriptionPage."
void requirePremium(BuildContext context, VoidCallback onUnlocked) {
  if (hasActiveSubscription(context)) {
    onUnlocked();
    return;
  }
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const SubscriptionPage()),
  );
}
