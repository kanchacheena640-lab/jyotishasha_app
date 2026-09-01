import 'package:flutter/foundation.dart';

import 'package:jyotishasha_app/core/analytics/safe_default_activity_event_client.dart';
import 'package:jyotishasha_app/services/activity_event_client.dart';

/// Phase 5B -- fires `session_start` at most ONCE per Dart process,
/// attempted only at the first authenticated seam reached this process:
/// either SplashPage's returning-user cold start, or LoginPage's fresh
/// sign-in completing this same process -- whichever happens first; the
/// other becomes a no-op for the remainder of this process. Deliberately
/// never persisted (matches `AnalyticsSessionContext`'s own
/// process-lifetime-only contract, Phase 5A) -- a fresh process always
/// re-evaluates from scratch, and there is no 30-minute/background-timer
/// semantic here at all.
///
/// `/api/activity-events` is authenticated-only (Phase 3, frozen): this
/// producer is only ever called from a seam that has already confirmed a
/// real signed-in user exists at that point -- it never fabricates an
/// event for an unauthenticated launch (both call sites — SplashPage and
/// LoginPage — only reach this after their own `user != null` check).
class SessionStartProducer {
  SessionStartProducer._();

  static bool _attempted = false;

  /// `entryPoint` is one of the two frozen Phase 5B values: `"cold_start"`
  /// (SplashPage, an already-signed-in Firebase user relaunching the app)
  /// or `"login"` (LoginPage, a fresh sign-in completing this same
  /// process). Never awaited by a call site -- fire-and-forget, and
  /// [ActivityEventClient.record] itself never throws.
  static Future<void> attemptOnce({
    required String entryPoint,
    ActivityEventClient? client,
  }) {
    if (_attempted) return Future<void>.value();
    // Set BEFORE the await inside record() runs, so two seams reached in
    // the same synchronous turn can never both pass this guard -- Dart
    // has no true concurrency, so this simple flag is sufficient.
    _attempted = true;
    final eventClient = client ?? safeDefaultActivityEventClient();
    return eventClient.record(
      eventName: 'session_start',
      properties: {'entry_point': entryPoint},
    );
  }

  /// Test-only: simulates a new process, so the next [attemptOnce] call
  /// becomes eligible again. Production code never calls this.
  @visibleForTesting
  static void resetForTest() {
    _attempted = false;
  }
}
