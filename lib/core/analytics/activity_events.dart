import 'package:flutter/foundation.dart';

import 'package:jyotishasha_app/core/analytics/safe_default_activity_event_client.dart';
import 'package:jyotishasha_app/services/activity_event_client.dart';

/// Phase 5B -- thin, semantic convenience layer over [ActivityEventClient]
/// for the client-owned canonical events wired in this phase. Each method
/// builds EXACTLY the frozen properties shape for its event and nothing
/// else -- callers never construct a raw properties map themselves, so a
/// product call site can never accidentally add an extra/forbidden key.
///
/// Every method is fire-and-forget: none of them need to be (or are)
/// awaited by product call sites, and [ActivityEventClient.record] itself
/// never throws -- see that class's own delivery contract.
class ActivityEvents {
  ActivityEvents._();

  // Deliberately lazy (not `= ActivityEventClient()` at declaration): the
  // real ActivityEventClient()'s default FirebaseCurrentUserIdentityPort
  // touches FirebaseAuth.instance eagerly in ITS OWN constructor. In
  // production that's harmless (Firebase.initializeApp() has already
  // completed before any UI code can reach this class). In a headless
  // test, constructing it before a test has had a chance to call
  // debugOverrideClient() below would crash immediately -- so the real
  // default is only ever constructed lazily, on first real use.
  static ActivityEventClient? _client;

  static ActivityEventClient get _current =>
      _client ??= safeDefaultActivityEventClient();

  /// Test-only: swaps in a fully test-controlled [ActivityEventClient]
  /// (e.g. one built with a fake identity port / MockClient) so producer
  /// tests never touch real Firebase, the real backend, or the network.
  /// Production code never calls this.
  @visibleForTesting
  static void debugOverrideClient(ActivityEventClient client) {
    _client = client;
  }

  /// Test-only: clears the override so the NEXT real call lazily
  /// reconstructs the production-default client -- never eagerly
  /// constructs one itself (see [_client]'s own doc comment for why).
  /// Always call this in a test's `tearDown` after [debugOverrideClient].
  @visibleForTesting
  static void debugResetClient() {
    _client = null;
  }

  /// `cta_click` -- frozen properties: `{cta_id, screen_name}` only.
  static Future<void> ctaClick({
    required String ctaId,
    required String screenName,
  }) {
    return _current.record(
      eventName: 'cta_click',
      properties: {'cta_id': ctaId, 'screen_name': screenName},
    );
  }

  /// `feature_used` -- frozen properties: `{feature_name}` only. Callers
  /// must only invoke this at an actual feature-invocation boundary (see
  /// each producer's own call-site comment for its chosen seam) -- never
  /// on a landing/marketing view, never on rebuild.
  static Future<void> featureUsed(String featureName) {
    return _current.record(
      eventName: 'feature_used',
      properties: {'feature_name': featureName},
    );
  }

  /// `report_discovery_viewed` -- frozen properties: `{report_type}` only.
  static Future<void> reportDiscoveryViewed(String reportType) {
    return _current.record(
      eventName: 'report_discovery_viewed',
      properties: {'report_type': reportType},
    );
  }

  /// `asknow_entry_viewed` -- frozen properties: `{}` (none).
  static Future<void> asknowEntryViewed() {
    return _current.record(eventName: 'asknow_entry_viewed');
  }
}
