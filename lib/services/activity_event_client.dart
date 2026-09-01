import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:jyotishasha_app/core/analytics/analytics_session_context.dart';
import 'package:jyotishasha_app/core/identity/current_user_identity_port.dart';
import 'package:jyotishasha_app/core/identity/firebase_current_user_identity_port.dart';
import 'package:jyotishasha_app/services/backend_auth_service.dart';

/// Phase 5A -- Flutter's first-party activity-event DELIVERY FOUNDATION.
///
/// This is deliberately just a thin, dedicated client for
/// `POST /api/activity-events` (the backend's frozen, authenticated-only
/// Phase-3 client-ingestion endpoint) -- not a new HTTP architecture, not
/// a new auth system. It reuses the exact `BackendAuthService
/// .getBackendToken()` token-exchange pattern already proven live in
/// production by `AskNowService`, `ProfileCompletenessService`, the
/// notification repository, and `SubscriptionProvider`.
///
/// NO PRODUCT EVENT IS WIRED HERE. This file only makes `record()`
/// available for Phase 5B to call from real product seams.
///
/// Delivery contract (locked, Phase 5A):
///   - fire-and-forget from the CALLER's perspective: `record()` never
///     throws and its returned Future never needs to be awaited by a
///     product call site for correctness.
///   - every failure (no signed-in user, no backend token, any network
///     error, any timeout, any non-2xx/non-`200/201` HTTP response) is
///     swallowed here and only ever produces a high-level debug log line
///     -- never a thrown exception, never a user-facing error, never a
///     retry.
///   - no offline queue, no persistent queue, no background worker.
typedef ActivityEventTokenProvider =
    Future<String?> Function(String firebaseUid, {http.Client? client});

class ActivityEventClient {
  /// `httpClient` / `identityPort` / `tokenProvider` / `sessionContext`
  /// are injectable purely for tests -- mirrors the exact same
  /// `client:`-injection seam already used throughout this codebase
  /// (`BackendAuthService`, `AskNowService`, `ProfileService`'s
  /// `CurrentUserIdentityPort`, etc.). Production code that constructs
  /// `ActivityEventClient()` with no arguments gets exactly today's real
  /// behavior: the real `FirebaseCurrentUserIdentityPort`, the real
  /// `BackendAuthService.getBackendToken`, a fresh `http.Client()` per
  /// call, and the real process-lifetime `AnalyticsSessionContext`.
  ActivityEventClient({
    http.Client? httpClient,
    CurrentUserIdentityPort? identityPort,
    ActivityEventTokenProvider? tokenProvider,
    AnalyticsSessionContext? sessionContext,
  }) : _httpClient = httpClient,
       _identityPort = identityPort ?? FirebaseCurrentUserIdentityPort(),
       _tokenProvider = tokenProvider ?? BackendAuthService.getBackendToken,
       _sessionContext = sessionContext ?? AnalyticsSessionContext.instance;

  static const String _baseUrl = 'https://jyotishasha-backend.onrender.com';
  static const String _path = '/api/activity-events';

  /// The one fixed `source` literal every Flutter-originated client event
  /// carries -- no caller may override it (Phase 5A design freeze, S8).
  static const String source = 'flutter_app';

  /// Deliberately short: this is a non-interactive, observational,
  /// no-retry call -- nothing in the product waits on it. Every existing
  /// HTTP timeout in this codebase is either 12s (interactive
  /// auth/status/purchase calls that a loading spinner is genuinely
  /// waiting on) or 25s (`AskNowService`'s AI-generation call, explicitly
  /// not reusable here per the task brief). 5s is shorter than both --
  /// long enough for a normal warm request to a small JSON endpoint, short
  /// enough that a slow/cold backend can never make analytics linger
  /// noticeably, since a timeout here is just silently dropped anyway.
  static const Duration _timeout = Duration(seconds: 5);

  final http.Client? _httpClient;
  final CurrentUserIdentityPort _identityPort;
  final ActivityEventTokenProvider _tokenProvider;
  final AnalyticsSessionContext _sessionContext;

  /// Records one client-owned activity event. Accepts ONLY the fields a
  /// client is actually allowed to assert under the frozen ingestion
  /// contract -- `event_id`, `recorded_at`, `environment`, `firebase_uid`,
  /// `profile_id`, `correlation_id`, and `dedupe_key` have no parameter
  /// here at all, so a normal caller has no way to supply them even by
  /// accident. `occurred_at`, `platform`, `source`, and `session_id` are
  /// always derived internally -- never caller-supplied.
  ///
  /// Never throws. Safe to call without `await` from a product call site;
  /// this method itself awaits the network call internally only to
  /// enforce the timeout/error handling below, not to let any failure
  /// propagate back out.
  Future<void> record({
    required String eventName,
    int eventVersion = 1,
    Map<String, Object?>? properties,
    Map<String, Object?>? campaignContext,
    Map<String, Object?>? notificationContext,
    String? entityType,
    String? entityId,
    String? idempotencyKey,
  }) async {
    try {
      final platform = _resolvePlatform();
      if (platform == null) {
        _log('activity event dropped: unsupported platform');
        return;
      }

      final firebaseUid = _identityPort.currentFirebaseUid;
      if (firebaseUid == null) {
        _log('activity event dropped: no signed-in user');
        return;
      }

      final ownsClient = _httpClient == null;
      final client = _httpClient ?? http.Client();
      try {
        final token = await _tokenProvider(firebaseUid, client: client);
        if (token == null) {
          _log('activity event dropped: no backend token');
          return;
        }

        final body = <String, Object?>{
          'event_name': eventName,
          'event_version': eventVersion,
          'occurred_at': DateTime.now().toUtc().toIso8601String(),
          'platform': platform,
          'source': source,
          'session_id': _sessionContext.sessionId,
          if (properties != null && properties.isNotEmpty)
            'properties': properties,
          if (campaignContext != null && campaignContext.isNotEmpty)
            'campaign_context': campaignContext,
          if (notificationContext != null && notificationContext.isNotEmpty)
            'notification_context': notificationContext,
          if (entityType != null) 'entity_type': entityType,
          if (entityId != null) 'entity_id': entityId,
          if (idempotencyKey != null) 'idempotency_key': idempotencyKey,
        };

        final res = await client
            .post(
              Uri.parse('$_baseUrl$_path'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
              body: jsonEncode(body),
            )
            .timeout(_timeout);

        if (res.statusCode == 200 || res.statusCode == 201) {
          _log('activity event delivered: HTTP ${res.statusCode}');
        } else {
          _log('activity event dropped: HTTP ${res.statusCode}');
        }
      } finally {
        if (ownsClient) client.close();
      }
    } catch (e) {
      // Deliberately untyped, exactly like BackendAuthService's own
      // catch (_) -- a timeout, a SocketException, a Firebase failure, a
      // malformed response, anything at all: analytics is dropped, never
      // surfaced to the caller.
      _log('activity event dropped: ${e.runtimeType}');
    }
  }

  String? _resolvePlatform() {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'app_android';
      case TargetPlatform.iOS:
        return 'app_ios';
      default:
        return null;
    }
  }

  /// High-level diagnostics only. NEVER logs the Authorization header, the
  /// backend JWT, the Firebase ID token, the request body, or any event
  /// property -- only a fixed, static, human-authored message string.
  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[ActivityEventClient] $message');
    }
  }
}
