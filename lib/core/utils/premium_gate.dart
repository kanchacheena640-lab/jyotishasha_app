// lib/core/utils/premium_gate.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:jyotishasha_app/core/state/subscription_provider.dart';
import 'package:jyotishasha_app/features/subscription/subscription_page.dart';

/// S5.3 — the one shared "does this user currently have premium access"
/// check, reused wherever a feature needs to require an active
/// subscription. Reads ONLY [SubscriptionProvider.subscriptionData]'s own
/// `membership_state` field from `GET /api/profile/subscription-info` —
/// the backend's finalized, single source of truth for membership status
/// (`TRIAL`/`ACTIVE`/`GRACE_PERIOD`/`EXPIRED`/`NONE`, guaranteed in every
/// response). `TRIAL` and `GRACE_PERIOD` grant access exactly like
/// `ACTIVE` (a trial unlocks every premium report; a lapsed-but-in-grace
/// user keeps access until the grace period ends) — never inferred from
/// any other field, never computed client-side. If the backend hasn't
/// been queried yet (`subscriptionData` is still `null`), this returns
/// `false` rather than assuming access.
bool hasActiveSubscription(BuildContext context) {
  final data = context.read<SubscriptionProvider>().subscriptionData;
  final state = data?['membership_state']?.toString().toUpperCase();
  return state == 'TRIAL' || state == 'ACTIVE' || state == 'GRACE_PERIOD';
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
