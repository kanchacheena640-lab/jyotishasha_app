import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:jyotishasha_app/core/analytics/analytics_session_context.dart';
import 'package:jyotishasha_app/core/identity/current_user_identity_port.dart';
import 'package:jyotishasha_app/services/activity_event_client.dart';

/// Phase 5A foundation tests -- ActivityEventClient.
///
/// This headless test environment has no real Firebase app (documented,
/// pre-existing repo-wide limitation -- see
/// test/core/state/asknow_credit_safety_test.dart's identical note), so
/// `ActivityEventClient` accepts an injectable `CurrentUserIdentityPort`
/// (the exact seam `ProfileService`/`DashboardPage` already use in
/// production) and an injectable token-provider function (mirroring the
/// `client:`-injection seam `BackendAuthService`/`AskNowService` already
/// use for HTTP) -- purely so the auth-acquisition step itself can be
/// controlled here without touching real Firebase or the real backend.
/// Neither seam is used by production code, which always falls through
/// to the real `FirebaseCurrentUserIdentityPort` /
/// `BackendAuthService.getBackendToken`.
class _FakeIdentityPort implements CurrentUserIdentityPort {
  _FakeIdentityPort(this._uid);
  final String? _uid;
  @override
  String? get currentFirebaseUid => _uid;
}

void main() {
  const signedInUid = 'test-firebase-uid';
  const fakeToken = 'fake-backend-jwt-for-tests-only';

  late List<String> logs;
  late DebugPrintCallback originalDebugPrint;

  setUp(() {
    AnalyticsSessionContext.resetForTest();
    logs = [];
    originalDebugPrint = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) {
      logs.add(message ?? '');
    };
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
  });

  tearDown(() {
    debugPrint = originalDebugPrint;
    debugDefaultTargetPlatformOverride = null;
  });

  /// Builds a client wired to a MockClient that always succeeds with 201
  /// and records every request it receives, plus a token provider that
  /// always returns [fakeToken] -- the "everything works" baseline most
  /// tests start from and then deviate one thing at a time.
  ({ActivityEventClient client, List<http.Request> captured}) happyClient({
    String? uid = signedInUid,
    int statusCode = 201,
    String responseBody = '{"status":"written","event_id":"abc"}',
  }) {
    final captured = <http.Request>[];
    final mockClient = MockClient((request) async {
      captured.add(request);
      return http.Response(responseBody, statusCode);
    });
    final client = ActivityEventClient(
      httpClient: mockClient,
      identityPort: _FakeIdentityPort(uid),
      tokenProvider: (firebaseUid, {client}) async => fakeToken,
    );
    return (client: client, captured: captured);
  }

  // ---------------------------------------------------------------
  // #1 allowed fields serialize correctly / #20 absent optional fields
  // are not fabricated / #21 anonymous_id never auto-generated / #24 no
  // sensitive fields automatically collected
  // ---------------------------------------------------------------
  test('minimal call: only the always-present fields are sent', () async {
    final h = happyClient();
    await h.client.record(eventName: 'feature_used');

    expect(h.captured, hasLength(1));
    final body = jsonDecode(h.captured.single.body) as Map<String, dynamic>;

    expect(body['event_name'], 'feature_used');
    expect(body['event_version'], 1);
    expect(body['platform'], 'app_android');
    expect(body['source'], 'flutter_app');
    expect(body.containsKey('session_id'), isTrue);
    expect(body.containsKey('occurred_at'), isTrue);

    // Nothing fabricated for absent optional fields.
    for (final key in [
      'properties',
      'campaign_context',
      'notification_context',
      'entity_type',
      'entity_id',
      'idempotency_key',
      'anonymous_id',
    ]) {
      expect(body.containsKey(key), isFalse, reason: 'unexpected key "$key"');
    }
  });

  test(
    'full call: every allowed optional field is included and forbidden '
    'backend-owned fields never appear',
    () async {
      final h = happyClient();
      await h.client.record(
        eventName: 'report_viewed',
        eventVersion: 1,
        properties: {'feature_name': 'kundali'},
        campaignContext: {'utm_source': 'newsletter'},
        notificationContext: {'notification_id': '42'},
        entityType: 'ai_report',
        entityId: '7',
        idempotencyKey: 'idem-123',
      );

      final body = jsonDecode(h.captured.single.body) as Map<String, dynamic>;

      expect(body['properties'], {'feature_name': 'kundali'});
      expect(body['campaign_context'], {'utm_source': 'newsletter'});
      expect(body['notification_context'], {'notification_id': '42'});
      expect(body['entity_type'], 'ai_report');
      expect(body['entity_id'], '7');
      expect(body['idempotency_key'], 'idem-123');

      // #2 forbidden backend-owned fields structurally cannot appear --
      // record() has no parameter for any of these, so this proves it at
      // runtime too, not just by reading the signature.
      for (final key in [
        'event_id',
        'recorded_at',
        'environment',
        'firebase_uid',
        'profile_id',
        'correlation_id',
        'dedupe_key',
      ]) {
        expect(
          body.containsKey(key),
          isFalse,
          reason: 'forbidden key "$key" leaked into the request body',
        );
      }
    },
  );

  // ---------------------------------------------------------------
  // #3 / #4 platform derivation
  // ---------------------------------------------------------------
  test('Android -> platform "app_android"', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final h = happyClient();
    await h.client.record(eventName: 'cta_click');
    final body = jsonDecode(h.captured.single.body) as Map<String, dynamic>;
    expect(body['platform'], 'app_android');
  });

  test('iOS -> platform "app_ios"', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final h = happyClient();
    await h.client.record(eventName: 'cta_click');
    final body = jsonDecode(h.captured.single.body) as Map<String, dynamic>;
    expect(body['platform'], 'app_ios');
  });

  test(
    'unsupported platform -> dropped safely, no HTTP call, no throw',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      final h = happyClient();
      await h.client.record(eventName: 'cta_click');
      expect(h.captured, isEmpty);
      expect(logs.any((l) => l.contains('unsupported platform')), isTrue);
    },
  );

  // ---------------------------------------------------------------
  // #5 occurred_at UTC ISO-8601 / #6 fixed source literal
  // ---------------------------------------------------------------
  test('occurred_at is a UTC, timezone-aware, ISO-8601 timestamp', () async {
    final before = DateTime.now().toUtc();
    final h = happyClient();
    await h.client.record(eventName: 'feature_used');
    final after = DateTime.now().toUtc();

    final body = jsonDecode(h.captured.single.body) as Map<String, dynamic>;
    final raw = body['occurred_at'] as String;
    expect(raw.endsWith('Z'), isTrue, reason: 'not UTC-marked: $raw');

    final parsed = DateTime.parse(raw);
    expect(parsed.isUtc, isTrue);
    expect(
      parsed.isAfter(before.subtract(const Duration(seconds: 1))),
      isTrue,
    );
    expect(parsed.isBefore(after.add(const Duration(seconds: 1))), isTrue);
  });

  test('source is always the fixed literal "flutter_app"', () async {
    expect(ActivityEventClient.source, 'flutter_app');
    final h = happyClient();
    await h.client.record(eventName: 'feature_used');
    final body = jsonDecode(h.captured.single.body) as Map<String, dynamic>;
    expect(body['source'], 'flutter_app');
  });

  // ---------------------------------------------------------------
  // #7 session_id stable within one client/process (charset/length are
  // covered exhaustively in analytics_session_context_test.dart)
  // ---------------------------------------------------------------
  test('session_id is identical across two record() calls', () async {
    final h = happyClient();
    await h.client.record(eventName: 'feature_used');
    await h.client.record(eventName: 'cta_click');
    expect(h.captured, hasLength(2));
    final first = jsonDecode(h.captured[0].body)['session_id'];
    final second = jsonDecode(h.captured[1].body)['session_id'];
    expect(first, equals(second));
    expect(first, equals(AnalyticsSessionContext.instance.sessionId));
  });

  // ---------------------------------------------------------------
  // #9 no Firebase user -> safely dropped
  // ---------------------------------------------------------------
  test('no signed-in user -> dropped safely, no HTTP call, no throw', () async {
    final h = happyClient(uid: null);
    await h.client.record(eventName: 'feature_used');
    expect(h.captured, isEmpty);
    expect(logs.any((l) => l.contains('no signed-in user')), isTrue);
  });

  // ---------------------------------------------------------------
  // #10 backend JWT acquisition failure -> safely dropped
  // ---------------------------------------------------------------
  test('backend token acquisition failure -> dropped, no HTTP call', () async {
    final captured = <http.Request>[];
    final mockClient = MockClient((request) async {
      captured.add(request);
      return http.Response('{}', 201);
    });
    final client = ActivityEventClient(
      httpClient: mockClient,
      identityPort: _FakeIdentityPort(signedInUid),
      tokenProvider: (firebaseUid, {client}) async => null,
    );
    await client.record(eventName: 'feature_used');
    expect(captured, isEmpty);
    expect(logs.any((l) => l.contains('no backend token')), isTrue);
  });

  // ---------------------------------------------------------------
  // #11 network exception -> safely dropped
  // ---------------------------------------------------------------
  test('a thrown network exception -> dropped, never rethrown', () async {
    final mockClient = MockClient((request) async {
      throw const SocketExceptionStub();
    });
    final client = ActivityEventClient(
      httpClient: mockClient,
      identityPort: _FakeIdentityPort(signedInUid),
      tokenProvider: (firebaseUid, {client}) async => fakeToken,
    );
    await expectLater(
      client.record(eventName: 'feature_used'),
      completes,
    );
    expect(logs.any((l) => l.contains('activity event dropped')), isTrue);
  });

  // ---------------------------------------------------------------
  // #12 timeout -> safely dropped
  // ---------------------------------------------------------------
  test(
    'a request that never completes in time -> dropped via the internal '
    'timeout, never hangs the caller',
    () async {
      final mockClient = MockClient((request) async {
        await Future<void>.delayed(const Duration(seconds: 6));
        return http.Response('{}', 201); // never actually reached
      });
      final client = ActivityEventClient(
        httpClient: mockClient,
        identityPort: _FakeIdentityPort(signedInUid),
        tokenProvider: (firebaseUid, {client}) async => fakeToken,
      );
      await expectLater(client.record(eventName: 'feature_used'), completes);
      expect(logs.any((l) => l.contains('activity event dropped')), isTrue);
    },
    // Real client timeout is 5s; the mock delay (6s) is deliberately just
    // over it so this proves the internal .timeout() actually fires,
    // mirroring backend_auth_service_test.dart's identical convention.
    timeout: const Timeout(Duration(seconds: 15)),
  );

  // ---------------------------------------------------------------
  // #13-#16 non-2xx HTTP status -> safely dropped, never thrown
  // #19 no retry after failure (exactly one call each time)
  // ---------------------------------------------------------------
  for (final status in [400, 401, 429, 500]) {
    test('HTTP $status -> dropped safely, no throw, no retry', () async {
      final h = happyClient(statusCode: status, responseBody: '{}');
      await expectLater(h.client.record(eventName: 'feature_used'), completes);
      expect(h.captured, hasLength(1), reason: 'must not retry');
      expect(logs.any((l) => l.contains('dropped: HTTP $status')), isTrue);
    });
  }

  // ---------------------------------------------------------------
  // #17 / #18 success outcomes
  // ---------------------------------------------------------------
  test('HTTP 201 -> treated as successful delivery', () async {
    final h = happyClient(statusCode: 201);
    await h.client.record(eventName: 'feature_used');
    expect(h.captured, hasLength(1));
    expect(logs.any((l) => l.contains('delivered: HTTP 201')), isTrue);
  });

  test('HTTP 200 (duplicate) -> also treated as successful delivery', () async {
    final h = happyClient(statusCode: 200, responseBody: '{"status":"duplicate"}');
    await h.client.record(eventName: 'feature_used');
    expect(h.captured, hasLength(1));
    expect(logs.any((l) => l.contains('delivered: HTTP 200')), isTrue);
  });

  // ---------------------------------------------------------------
  // #23 no auth token enters event JSON / privacy of the Authorization
  // header itself, and of logging
  // ---------------------------------------------------------------
  test(
    'the backend token is sent only as the Authorization header, never '
    'inside the JSON body, and never logged',
    () async {
      final h = happyClient();
      await h.client.record(eventName: 'feature_used');

      final req = h.captured.single;
      expect(req.headers['Authorization'], 'Bearer $fakeToken');
      expect(req.body.contains(fakeToken), isFalse);

      for (final line in logs) {
        expect(line.contains(fakeToken), isFalse);
        expect(line.toLowerCase().contains('bearer'), isFalse);
      }
    },
  );

  test('record() never throws even without the caller awaiting it', () async {
    final mockClient = MockClient((request) async {
      throw const SocketExceptionStub();
    });
    final client = ActivityEventClient(
      httpClient: mockClient,
      identityPort: _FakeIdentityPort(signedInUid),
      tokenProvider: (firebaseUid, {client}) async => fakeToken,
    );
    // Deliberately not awaited -- a product call site is allowed to do
    // exactly this per the Phase 5A delivery contract.
    // ignore: unawaited_futures
    client.record(eventName: 'feature_used');
    // Give the fire-and-forget call a turn to run to completion so the
    // test process doesn't tear down mid-flight.
    await Future<void>.delayed(const Duration(milliseconds: 10));
  });
}

/// Minimal stand-in for `SocketException` without importing `dart:io`
/// directly -- mirrors backend_auth_service_test.dart's identical helper.
/// Only its `Exception`-ness matters: `ActivityEventClient`'s catch block
/// is intentionally untyped (`catch (e)`) and swallows any exception the
/// same way.
class SocketExceptionStub implements Exception {
  const SocketExceptionStub();
  @override
  String toString() => 'SocketExceptionStub: connection failed';
}
