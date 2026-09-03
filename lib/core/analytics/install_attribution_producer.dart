import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:jyotishasha_app/core/analytics/install_referrer_service.dart';
import 'package:jyotishasha_app/core/identity/current_user_identity_port.dart';
import 'package:jyotishasha_app/core/identity/firebase_current_user_identity_port.dart';
import 'package:jyotishasha_app/services/activity_event_client.dart';

/// Task 5A -- completes the chain Task 5 left blocked:
///
///   captured Play attribution (InstallReferrerService, Task 5)
///     -> first authenticated opportunity
///     -> app_install_attributed (activity_events)
///
/// FROZEN MEANING (do not reinterpret elsewhere): app_install_attributed
/// means "Google Play install attribution was captured by the Android
/// app and later associated with an authenticated app lifecycle." It is
/// NOT GA4 first_open, NOT a raw install counter, NOT the website's own
/// app_download_intent, and NOT proof of a user-level website-to-install
/// conversion. It must never be presented as "number of installs" --
/// Firebase/GA4 remains authoritative for actual install/first-open
/// volume (see this class's own test file for the same freeze restated
/// as an executable assertion, not just a comment).
///
/// Does NOT redesign InstallReferrerService (Task 5, unmodified) or the
/// authentication architecture -- this class only reads
/// [InstallReferrerService.readCapturedAttribution] and calls the
/// existing, already-authenticated [ActivityEventClient.record] at a
/// caller-chosen safe moment.
///
/// EMISSION TIMING: call [attemptOnce] from the FIRST SAFE AUTHENTICATED
/// OPPORTUNITY in the app's lifecycle, not only interactive login --
/// this covers both a restored Firebase session (SplashPage's own
/// `user != null` cold-start branch) and a fresh interactive sign-in
/// (LoginPage). Both call sites use the exact same idempotent
/// [attemptOnce] -- calling it from both is intentional and safe (see
/// EXACTLY-ONCE below), not a duplicate-producer mistake.
///
/// EXACTLY-ONCE: `install_referrer_processed_v1` (Task 5) means
/// "referrer retrieval was processed" -- it says nothing about whether
/// the LEDGER EVENT was ever successfully recorded, so it is never
/// reused as the emission-success flag here. This class owns its own,
/// separate local marker, `install_attribution_event_recorded_v1`, set
/// ONLY after `ActivityEventClient.record()` (Task 5A: now returns
/// `Future<bool>`, see that file's own docstring) confirms the event was
/// actually written or already-duplicate. A network/write failure never
/// sets it, so a later authenticated opportunity (app relaunch, a second
/// SplashPage cold-start, etc.) may legitimately retry -- there is no
/// retry loop, no background queue, and no startup blocking anywhere in
/// this class; every call is a single best-effort attempt.
///
/// DEDUPE: a random, install-scoped `idempotency_key` is generated once
/// and persisted locally (`install_attribution_idempotency_key_v1`),
/// then reused on every retry attempt until the event is confirmed
/// recorded. This protects against exactly the crash window Task 5A
/// calls out (a crash between the backend confirming the write and this
/// class setting its own local "recorded" marker): a retry with the SAME
/// idempotency_key hits the backend's own existing dedupe_key partial-
/// unique-index mechanism (modules/activity_events/ingestion_service.py)
/// and comes back HTTP 200 "duplicate" -- which `ActivityEventClient`
/// already treats as a confirmed, successful delivery (`record()`
/// returns `true` for both HTTP 201 and HTTP 200), so this class's own
/// "duplicate response -> mark emitted" requirement is satisfied by
/// `ActivityEventClient`'s own existing behavior, not a new mechanism
/// invented here.
class InstallAttributionProducer {
  InstallAttributionProducer._();

  static const String _recordedKey = 'install_attribution_event_recorded_v1';
  static const String _idempotencyKeyKey = 'install_attribution_idempotency_key_v1';

  /// Test-only seams -- production code never sets these. Mirrors
  /// ActivityEventClient's own constructor-injection pattern and
  /// ActivityEvents.debugOverrideClient()'s own static-override pattern,
  /// both already established in this codebase.
  @visibleForTesting
  static ActivityEventClient? debugClientOverride;

  @visibleForTesting
  static CurrentUserIdentityPort? debugIdentityPortOverride;

  @visibleForTesting
  static void debugReset() {
    debugClientOverride = null;
    debugIdentityPortOverride = null;
  }

  /// Fire-and-forget entry point -- call from either SplashPage's
  /// restored-session branch or LoginPage's fresh-sign-in seam, without
  /// awaiting. Never throws. Never delays navigation, never alters a
  /// login/signup result, never surfaces a user-visible error. Never
  /// logs the raw referrer, any campaign value, or any identity field --
  /// only a fixed, static diagnostic message, matching
  /// ActivityEventClient._log's own convention.
  static Future<void> attemptOnce() async {
    try {
      // This fact currently only has meaning for a Google Play install
      // (Task 5's own scope) -- backend ingestion additionally enforces
      // platform=app_android for this specific event
      // (EVENT_PLATFORM_RESTRICTIONS, modules/activity_events/
      // ingestion_policy.py), but this client-side guard avoids even
      // attempting the network call on a non-Android target in the
      // first place (defense in depth, and this app does compile for
      // iOS in principle -- ActivityEventClient._resolvePlatform()
      // already has a real app_ios branch).
      if (defaultTargetPlatform != TargetPlatform.android) {
        return;
      }

      final identityPort = debugIdentityPortOverride ?? FirebaseCurrentUserIdentityPort();
      if (identityPort.currentFirebaseUid == null) {
        // Captured attribution + unauthenticated -> wait. The caller is
        // responsible for invoking this again at the next authenticated
        // opportunity (exactly like SessionStartProducer/login_completed
        // already require their own callers to only invoke them past a
        // null-user check).
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_recordedKey) ?? false) {
        return; // Already confirmed recorded -- never re-attempt.
      }

      final captured = await InstallReferrerService.readCapturedAttribution();
      final campaignContext = buildCampaignContext(captured);
      if (campaignContext == null) {
        // No attribution captured -> no event. Deliberately does NOT
        // mark _recordedKey -- InstallReferrerService's own capture may
        // still be pending/retryable, and even once it completes with
        // genuinely no UTM values (organic install), there is nothing
        // meaningfully attributable to record; re-checking on a later
        // opportunity is harmless (this stays cheap: one SharedPreferences
        // read, no network call, when there is nothing to send).
        return;
      }

      var idempotencyKey = prefs.getString(_idempotencyKeyKey);
      if (idempotencyKey == null) {
        idempotencyKey = _generateIdempotencyKey();
        await prefs.setString(_idempotencyKeyKey, idempotencyKey);
      }

      final client = debugClientOverride ?? ActivityEventClient();
      final confirmed = await client.record(
        eventName: 'app_install_attributed',
        campaignContext: campaignContext,
        idempotencyKey: idempotencyKey,
      );

      if (confirmed) {
        await prefs.setBool(_recordedKey, true);
      }
      // else: network/write failure -- DO NOT permanently mark emitted;
      // a later authenticated opportunity may retry, reusing the SAME
      // idempotencyKey (see class docstring's DEDUPE section).
    } catch (e) {
      debugPrint('[InstallAttributionProducer] attempt failed: ${e.runtimeType}');
    }
  }

  /// Only the 3 approved campaign fields, through campaign_context --
  /// NEVER cta_location (not a supported campaign_context field, and
  /// event properties are frozen at {} -- Task 5A explicitly forbids
  /// inventing a property for it), never the raw referrer string, never
  /// a website session_id, never firebase_uid/profile_id as a property
  /// (identity is handled entirely by the existing authenticated
  /// envelope, never duplicated into a property here), never birth
  /// data/PII/device identifiers -- none of those fields are even
  /// reachable from `captured`'s own shape
  /// (InstallReferrerService.readCapturedAttribution() only ever
  /// returns utm_source/utm_medium/utm_campaign/cta_location).
  ///
  /// Returns null (not an empty map) when there is truly nothing to
  /// attach -- the caller treats that as "no attribution captured."
  @visibleForTesting
  static Map<String, Object?>? buildCampaignContext(Map<String, String?> captured) {
    final context = <String, Object?>{};
    if (captured['utm_source'] != null) context['utm_source'] = captured['utm_source'];
    if (captured['utm_medium'] != null) context['utm_medium'] = captured['utm_medium'];
    if (captured['utm_campaign'] != null) context['utm_campaign'] = captured['utm_campaign'];
    return context.isEmpty ? null : context;
  }

  /// Random, install-scoped, never derived from any PII/identity value
  /// -- same `Random.secure()`-based shape as
  /// AnalyticsSessionContext._generate()'s own session_id (that class's
  /// own established convention), deliberately NOT reused verbatim
  /// (this key must survive across process restarts via SharedPreferences,
  /// unlike the process-lifetime session_id).
  static String _generateIdempotencyKey() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  @visibleForTesting
  static Future<bool> debugIsRecorded() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_recordedKey) ?? false;
  }
}
