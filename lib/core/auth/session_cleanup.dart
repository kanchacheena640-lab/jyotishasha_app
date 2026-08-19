// lib/core/auth/session_cleanup.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';

import 'package:jyotishasha_app/core/messaging/fcm_token_manager.dart';
import 'package:jyotishasha_app/core/state/asknow_provider.dart';
import 'package:jyotishasha_app/core/state/daily_provider.dart';
import 'package:jyotishasha_app/core/state/firebase_kundali_provider.dart';
import 'package:jyotishasha_app/core/state/kundali_provider.dart';
import 'package:jyotishasha_app/core/state/manual_kundali_provider.dart';
import 'package:jyotishasha_app/core/state/monthly_provider.dart';
import 'package:jyotishasha_app/core/state/notification_provider.dart';
import 'package:jyotishasha_app/core/state/profile_provider.dart';
import 'package:jyotishasha_app/core/state/report_purchase_provider.dart';
import 'package:jyotishasha_app/core/state/subscription_provider.dart';
import 'package:jyotishasha_app/core/state/yearly_provider.dart';
import 'package:jyotishasha_app/features/love/providers/love_provider.dart';

/// Centralized post-auth session teardown — the ONE mechanism a
/// successful Logout and a fully successful Delete Account both call, so
/// neither path can drift out of sync with the other (previously each
/// only reset [ProfileProvider]/[SubscriptionProvider], letting the
/// birth chart, daily/monthly/yearly horoscope, love results,
/// notification count, and Ask Now/Report-purchase state of the
/// signed-out account keep showing — sometimes with genuinely another
/// person's name/email/phone still cached in [ReportPurchaseProvider]'s
/// persisted pending-purchase record).
///
/// ## What this clears
/// Every root-level provider (registered once, for the whole app
/// session, in `main.dart`'s `MultiProvider`) that can hold data scoped
/// to the signed-in account: [ProfileProvider], [SubscriptionProvider],
/// [FirebaseKundaliProvider], [KundaliProvider], [ManualKundaliProvider],
/// [DailyProvider], [MonthlyProvider], [YearlyProvider], [LoveProvider],
/// [NotificationProvider], [AskNowProvider], [ReportPurchaseProvider].
///
/// ## What this deliberately does NOT clear
/// - `LanguageProvider` — a device preference, not account data; the
///   task's own instruction is explicit that language/theme/onboarding
///   preferences must survive a logout.
/// - `WelcomeGiftProvider` — its own doc comment and
///   `LocalWelcomeGiftRepository`'s doc comment both already establish
///   this is intentionally device-local, not yet backend/account-tied
///   (`TODO(backend)` for when that changes) — the same "device
///   preference" category as language, not an account-scoped leak.
/// - `PanchangProvider`/`TransitProvider`/`CardsProvider` — derived
///   purely from date/time/location (and, for `CardsProvider`, shuffled
///   generic content), never from `FirebaseAuth.currentUser` or any
///   profile field. Resetting these would only force a wasteful refetch
///   with no privacy or correctness benefit.
/// - Each purchase provider's own `purchaseStream` subscription
///   (`initBilling()`/`initPurchaseListener()`) — process-wide billing
///   infrastructure registered once at app startup, not per-user state;
///   it must keep listening across a logout/login within the same
///   session (see [SubscriptionProvider.reset]'s own identical,
///   pre-existing precedent).
///
/// Split from [clearUserScopedSessionAndReturnToLogin] purely for
/// testability: this half touches only already-constructed providers via
/// [context] and has no real platform-channel dependency, so it can run
/// end-to-end in a widget test; the auth/FCM teardown below cannot (no
/// mock is registered for `FirebaseAuth`/`GoogleSignIn`/FCM in this
/// project's headless test environment — see the pre-existing
/// `account_page_test.dart` Logout group's own doc comment for the same,
/// longstanding constraint).
Future<void> clearUserScopedProviders(BuildContext context) async {
  if (!context.mounted) return;

  context.read<ProfileProvider>().reset();
  context.read<SubscriptionProvider>().reset();
  context.read<FirebaseKundaliProvider>().clear();
  context.read<KundaliProvider>().reset();
  context.read<ManualKundaliProvider>().reset();
  context.read<DailyProvider>().reset();
  context.read<MonthlyProvider>().reset();
  context.read<YearlyProvider>().reset();
  context.read<LoveProvider>().reset();
  context.read<NotificationProvider>().reset();
  await context.read<AskNowProvider>().reset();
  await context.read<ReportPurchaseProvider>().reset();
}

/// Local auth/session teardown — same ordering [AccountPage] already
/// used before this cleanup was centralized: clear the FCM token
/// registration, then sign out of Google, then sign out of Firebase.
/// Never calls `FirebaseAuth.currentUser.delete()` — this is signOut()
/// only, safe to call after Delete Account has already completed
/// server-side (D1–D3), where the local session is by that point merely
/// stale, not still valid.
///
/// Each step is independently try/caught (unchanged from the prior
/// inline version): a failure signing out of Google, for instance, must
/// never block Firebase sign-out or the provider cleanup that follows.
Future<void> _signOutOfAuthProviders() async {
  try {
    await fcmTokenManager.clearOnLogout();
  } catch (_) {}

  try {
    await GoogleSignIn().signOut();
  } catch (_) {}

  try {
    await FirebaseAuth.instance.signOut();
  } catch (_) {}
}

/// The single call site [AccountPage] uses for both a confirmed Logout
/// and a fully successful Delete Account: auth teardown, then every
/// user-scoped provider reset, then a full navigation-stack replacement
/// to `/login` — never an ordinary push, so the back button cannot
/// return to the now-signed-out screen.
///
/// Uses `context.go('/login')` (this app's `GoRouter`), not the Navigator
/// 1.0 `Navigator.pushNamedAndRemoveUntil` API the previous
/// implementation used — `MaterialApp.router` (see `app/app.dart`) does
/// not maintain a classic named-route table, and `go_router` maintains
/// its own internal navigation state independent of the raw Navigator
/// widget tree. `pushNamedAndRemoveUntil` was therefore never integrated
/// with `GoRouter`'s own state: any *subsequent* GoRouter-driven
/// navigation (a system Back press, which GoRouter also intercepts; its
/// own `redirect` re-evaluating) had no idea the app had "moved" to
/// `/login` and could resurface the previous, still-GoRouter-tracked
/// location — this is the actual mechanism behind Home surviving/
/// reappearing and Back returning to it. `go()` replaces GoRouter's
/// entire route stack with the new location, which both this task's own
/// "navigation must use stack replacement/reset, not ordinary push"
/// requirement and the Back-button requirement need.
Future<void> clearUserScopedSessionAndReturnToLogin(
  BuildContext context,
) async {
  await _signOutOfAuthProviders();

  if (!context.mounted) return;

  // Must run before navigating away — this is the last point this
  // context is guaranteed still attached to its providers.
  await clearUserScopedProviders(context);

  if (!context.mounted) return;

  context.go('/login');
}
