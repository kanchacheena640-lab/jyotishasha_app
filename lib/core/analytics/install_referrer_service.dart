import 'package:flutter/foundation.dart';
import 'package:play_install_referrer/play_install_referrer.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/startup_timeout.dart';

/// Task 5 -- reads Google Play's Install Referrer ONCE per install and
/// safely persists ONLY the allowlisted, non-PII campaign-attribution
/// fields locally (SharedPreferences), gated by a durable "already
/// processed" marker so a later app launch never reprocesses the same
/// install's referrer.
///
/// DELIBERATELY DOES NOT EMIT ANY activity_events ROW for this fact.
/// Task 5's own forensic audit of the frozen canonical event registry
/// (modules/activity_events/event_schemas.py, backend) found no
/// existing event that accurately represents "attributed app install /
/// first open" -- app_download_intent is a WEBSITE click-intent fact,
/// session_start/login_completed/feature_used all mean something else
/// entirely, and inventing a new event name here would violate the
/// frozen backend-owned canonical-event-ownership process (see
/// ActivityEvents' own class docstring: every method already maps to a
/// FROZEN backend schema, never a client-invented one). A backend
/// canonical contract extension is required first (see Task 5's final
/// report); this file's job stops at "safely captured and stored
/// locally" -- once that extension exists, a future producer reads the
/// locally-stored fields back via [readCapturedAttribution] and emits
/// them through the normal, authenticated `ActivityEventClient`. This
/// is the exact same deferred-backend-integration shape already
/// established in this codebase by
/// LocalWelcomeGiftRepository/WelcomeGiftProvider's own
/// `TODO(backend):` seam -- not a new pattern.
///
/// Google Play's Install Referrer API is not itself a one-shot call --
/// it may return the SAME referrer value again on a later app open.
/// The "once" guarantee here is enforced entirely by this service's own
/// local marker, never by an assumption about Play's own behavior.
///
/// Startup safety (Task 5 S7): the actual platform-channel call is
/// wrapped in this codebase's own existing `withStartupTimeout()`
/// (already used for `FirebaseMessaging.getInitialMessage()` in
/// main.dart -- reused here, not reinvented), so a stall or thrown
/// exception can never block app startup, and [captureOnce] itself is
/// meant to be called fire-and-forget (never awaited) from `main()`.
class InstallReferrerService {
  InstallReferrerService._();

  static const String _processedKey = 'install_referrer_processed_v1';
  static const String _utmSourceKey = 'install_referrer_utm_source_v1';
  static const String _utmMediumKey = 'install_referrer_utm_medium_v1';
  static const String _utmCampaignKey = 'install_referrer_utm_campaign_v1';
  static const String _ctaLocationKey = 'install_referrer_cta_location_v1';

  /// Exactly the fields the website's own outbound Play Store `referrer`
  /// payload writes (lib/playStoreAttribution.ts, frontend repo) --
  /// nothing else is ever read out of the raw referrer string, no
  /// matter what other keys it might contain.
  static const Set<String> _allowedKeys = {
    'utm_source',
    'utm_medium',
    'utm_campaign',
    'cta_location',
  };

  /// Matches the backend's own MAX_STRING_VALUE_LENGTH
  /// (modules/activity_events/ingestion_validation.py) -- a value this
  /// service ever stores must already be safe to eventually send to
  /// that contract once a producer exists.
  static const int _maxValueLength = 256;

  /// Test-only seam: overrides the real Play API call. Production code
  /// never sets this -- mirrors `ActivityEvents.debugOverrideClient()`'s
  /// own established static-override test pattern in this codebase.
  @visibleForTesting
  static Future<String?> Function()? debugFetcherOverride;

  @visibleForTesting
  static void debugResetFetcherOverride() {
    debugFetcherOverride = null;
  }

  static Future<String?> _defaultFetcher() async {
    final details = await PlayInstallReferrer.installReferrer;
    return details.installReferrer;
  }

  /// Fire-and-forget entry point -- call from `main()` without
  /// awaiting. Never throws. Never logs the raw referrer string or any
  /// parsed value -- only a fixed, static diagnostic message, matching
  /// `ActivityEventClient._log`'s own convention.
  ///
  /// `timeout` is exposed purely so tests can prove the bounded-startup
  /// contract without a real multi-second wait (mirrors
  /// `withStartupTimeout`'s own test-facing `timeout` parameter,
  /// test/core/utils/startup_timeout_test.dart) -- production code
  /// (main.dart) never passes it, so `withStartupTimeout`'s own 3-second
  /// default applies unchanged.
  static Future<void> captureOnce({Duration? timeout}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_processedKey) ?? false) {
        return; // Already captured for this install -- never reprocess.
      }

      final fetcher = debugFetcherOverride ?? _defaultFetcher;
      final raw = await withStartupTimeout(
        fetcher,
        debugLabel: 'InstallReferrerService.captureOnce',
        timeout: timeout ?? const Duration(seconds: 3),
      );
      if (raw == null) {
        // Timed out, threw, or the platform call itself failed -- no
        // evidence obtained. Deliberately NOT marked processed: a later
        // launch may legitimately retry once more, since nothing was
        // actually consumed yet.
        return;
      }

      final parsed = parseAllowlisted(raw);

      // Marked processed regardless of whether any field was actually
      // present (an organic/unattributed install is real evidence too
      // -- an empty or non-matching referrer string is a successful
      // read, not a failure) -- see class docstring.
      await prefs.setBool(_processedKey, true);
      await _persistIfPresent(prefs, _utmSourceKey, parsed['utm_source']);
      await _persistIfPresent(prefs, _utmMediumKey, parsed['utm_medium']);
      await _persistIfPresent(prefs, _utmCampaignKey, parsed['utm_campaign']);
      await _persistIfPresent(prefs, _ctaLocationKey, parsed['cta_location']);
    } catch (e) {
      debugPrint('[InstallReferrerService] capture failed: ${e.runtimeType}');
    }
  }

  static Future<void> _persistIfPresent(
    SharedPreferences prefs,
    String key,
    String? value,
  ) async {
    if (value != null) await prefs.setString(key, value);
  }

  /// Parses ONLY the allowlisted keys out of a raw referrer query
  /// string (`Uri.splitQueryString`'s own standard `key=value&key=value`
  /// shape -- the exact shape `lib/playStoreAttribution.ts`'s
  /// `buildPlayStoreReferrerValue()` on the website side writes). Never
  /// throws -- a malformed string simply yields an all-null result.
  /// Unknown keys are silently ignored. A value longer than
  /// [_maxValueLength] is dropped entirely (treated as absent), not
  /// truncated -- an oversized value for a marketing UTM field is not a
  /// legitimate one and truncating it could produce a misleading
  /// partial value.
  @visibleForTesting
  static Map<String, String?> parseAllowlisted(String raw) {
    final result = <String, String?>{
      'utm_source': null,
      'utm_medium': null,
      'utm_campaign': null,
      'cta_location': null,
    };
    if (raw.isEmpty) return result;

    Map<String, String> pairs;
    try {
      pairs = Uri.splitQueryString(raw);
    } catch (_) {
      return result;
    }

    for (final key in _allowedKeys) {
      final value = pairs[key];
      if (value != null && value.isNotEmpty && value.length <= _maxValueLength) {
        result[key] = value;
      }
    }
    return result;
  }

  /// Reads back whatever was captured (if anything) for a FUTURE
  /// producer to emit once a canonical event exists (see class
  /// docstring). Not called by any producer yet in this task.
  static Future<Map<String, String?>> readCapturedAttribution() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'utm_source': prefs.getString(_utmSourceKey),
      'utm_medium': prefs.getString(_utmMediumKey),
      'utm_campaign': prefs.getString(_utmCampaignKey),
      'cta_location': prefs.getString(_ctaLocationKey),
    };
  }

  @visibleForTesting
  static Future<bool> debugIsProcessed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_processedKey) ?? false;
  }
}
